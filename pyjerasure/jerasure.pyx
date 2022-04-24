# cython: language_level=3, boundscheck=True
# distutils: language=c++
"""Implementation for pyjerasure."""

import array
from typing import Iterable, Union
from cpython cimport array
from libc.stdlib cimport calloc, free

from pyjerasure cimport jerasure
from pyjerasure.utils import align_size


def __check_size(Matrix matrix, int size, int data_size, int packetsize = 0):
    if matrix.is_bitmatrix:
        if packetsize <= 0:
            raise ValueError("Packet size must be > 0")
        width = matrix.w * packetsize
    else:
        width = 16
    if size % width != 0:
        raise ValueError(f"Size must be divisible by {width}")
    if size <= 0:
        raise ValueError(f"Size cannot be < 1")
    if data_size % size != 0:
        raise ValueError(f"Data Size must be divisible by size")
    if data_size <= 0:
        raise ValueError(f"Data Size cannot be < 1")


def __check_matrix(Matrix matrix, int packetsize):
    if not matrix.valid:
        raise ValueError("Matrix is not valid")
    if matrix.is_bitmatrix:
        if packetsize <= 0:
            raise ValueError("Packet Size must be greater than 0")
        if matrix.w < 1 or matrix.w > 32:
            raise ValueError("w must be between 1 and 32")
    else:
        if matrix.w not in (8, 16, 32):
            raise ValueError("w must be one of (8, 16, 32)")


cdef int allocate_erasures(int k, int m, int* erasures, erased):
    cdef int i = 0
    cdef int erased_index = 0
    for i in range(len(erased)):
        if not isinstance(erased[i], int):
            return 1
        if erased[i] not in range(0, k + m):
            return 1
        erasures[i] = erased[i]
    erasures[len(erased)] = -1  # Important. Make last index '-1'
    return 0


cdef int allocate_block_ptrs(int k, int m, int size, array.array data, char **data_ptrs, char **coding_ptrs):
    cdef int i = 0
    for i in range(k + m):
        index = size * i
        if i < k:
            data_ptrs[i] = &data.data.as_chars[index]
        else:
            coding_ptrs[i-k] = &data.data.as_chars[index]
    return 0


def decode(Matrix matrix, bytes data, erasures: Iterable[int], int size, int packetsize = 0, bint data_only=False):
    """Return original data."""
    __check_matrix(matrix, packetsize)
    __check_size(matrix, size, len(data), packetsize)

    cdef int result = 0
    cdef int error = 0
    cdef int *erasures_ptr = <int *> calloc(len(erasures) + 1, sizeof(int));
    cdef char **data_ptrs = <char **> calloc(matrix.k, sizeof(char *))
    cdef char **coding_ptrs = <char **> calloc(matrix.m, sizeof(char *))
    cdef array.array data_array = array.array("I", data)

    error = allocate_erasures(matrix.k, matrix.m, erasures_ptr, erasures)
    if error != 0:
        result = -1
    error = allocate_block_ptrs(matrix.k, matrix.m, size, data_array, data_ptrs, coding_ptrs)
    if error != 0:
        result = -1
    if len(erasures) <= 0:
        result = -1
    
    if result == 0:
        if matrix.is_bitmatrix:
            result = jerasure.jerasure_bitmatrix_decode(matrix.k, matrix.m, matrix.w, matrix.ptr, matrix.row_k_ones, erasures_ptr, data_ptrs, coding_ptrs, size, packetsize)
        else:
            result = jerasure.jerasure_matrix_decode(matrix.k, matrix.m, matrix.w, matrix.ptr, matrix.row_k_ones, erasures_ptr, data_ptrs, coding_ptrs, size)

    free(data_ptrs)
    free(coding_ptrs)
    free(erasures_ptr)

    if result < 0:
        return b""
    if data_only:
        return data_array.tobytes()[:matrix.k * size]
    return data_array.tobytes()


def encode(Matrix matrix, bytes data, int size, int packetsize = 0):
    """Return data with coding blocks concatenated."""
    __check_matrix(matrix, packetsize)
    data = data.ljust((matrix.k + matrix.m) * size, b"\x00")
    __check_size(matrix, size, len(data), packetsize)

    cdef int result = 0
    cdef int error = 0
    cdef char **data_ptrs = <char **> calloc(matrix.k, sizeof(char *))
    cdef char **coding_ptrs = <char **> calloc(matrix.m, sizeof(char *))
    cdef array.array data_array = array.array("I", data)

    error = allocate_block_ptrs(matrix.k, matrix.m, size, data_array, data_ptrs, coding_ptrs)
    if error != 0:
        result = -1
    if result == 0:
        if matrix.is_bitmatrix:
            jerasure.jerasure_bitmatrix_encode(matrix.k, matrix.m, matrix.w, matrix.ptr, data_ptrs, coding_ptrs, size, packetsize)
        else:
            jerasure.jerasure_matrix_encode(matrix.k, matrix.m, matrix.w, matrix.ptr, data_ptrs, coding_ptrs, size)

    free(data_ptrs)
    free(coding_ptrs)

    if result < 0:
        return b""
    return data_array.tobytes()


cdef class Matrix():
    """Matrix Class.

    :param type: Matrix type
    :param k: Number of data blocks
    :param m: Number of coding blocks
    :param w: Word Size
    """
    TYPES = ("cauchy", "cauchy_good", "rs_vandermonde", "rs_r6", "liberation", "blaum_roth")

    def __dealloc__(self):
        if self.ptr != NULL:
            free(self.ptr)
            self.ptr = NULL

    def __repr__(self):
        return f"{str(self.__class__)[:-1]} type={self.type} k={self.k} m={self.m} w={self.w} valid={self.valid}>"

    def print(self):
        """Print matrix."""
        if not self.valid:
            print(None)
            return
        if self.is_bitmatrix:
            jerasure.jerasure_print_bitmatrix(self.ptr, self.m * self.w, self.k * self.w, self.w)
        else:
            jerasure.jerasure_print_matrix(self.ptr, self.m, self.k, self.w)

    def __cinit__(self, str type, int k = 0, int m = 0, int w = 0):
        self._k = k
        self._m = m
        self._w = w
        self.is_bitmatrix = False
        self.type = type

        self.__init_matrix()

    def __init_matrix(self):
        if self.ptr != NULL:
            free(self.ptr)

        if self.type == "cauchy":
            self.ptr = jerasure.cauchy_original_coding_matrix(self.k, self.m, self.w)
        elif self.type == "cauchy_good":
            self.ptr = jerasure.cauchy_good_general_coding_matrix(self.k, self.m, self.w)
        elif self.type == "rs_vandermonde":
            self.ptr = jerasure.reed_sol_vandermonde_coding_matrix(self.k, self.m, self.w)
            self.row_k_ones = 1
        elif self.type == "rs_r6":
            self.ptr = jerasure.reed_sol_r6_coding_matrix(self.k, self.w)
            self._m = 2
        elif self.type == "liberation":
            self.ptr = jerasure.liberation_coding_bitmatrix(self.k, self.w)
            self._m = 2
            self.is_bitmatrix = True
        elif self.type == "blaum_roth":
            self.ptr = jerasure.blaum_roth_coding_bitmatrix(self.k, self.w)
            self._m = 2
            self.is_bitmatrix = True
        else:
            raise ValueError(f"type must be one of {self.TYPES}")

    def align_size(self, int size, int packetsize = 0) -> int:
        """Return align size."""
        return align_size(self, size, packetsize)

    def align_block(self, block: Union[bytes, bytearray], int size, int packetsize = 0) -> bytes:
        """Return aligned block."""
        align_size = self.align_size(size, packetsize)
        return bytes(block.ljust(align_size, b"\x00"))

    @property
    def valid(self) -> bool:
        """Return True if matrix is valid."""
        return self.ptr != NULL

    @property
    def k(self) -> int:
        """Return number of data blocks."""
        return self._k

    @k.setter
    def k(self, int blocks):
        """Set number of data blocks."""
        self._k = blocks
        self.__init_matrix()

    @property
    def m(self) -> int:
        """Return number of coding blocks."""
        return self._m

    @m.setter
    def m(self, int blocks):
        """Set number of coding blocks."""
        self._m = blocks
        self.__init_matrix()

    @property
    def w(self) -> int:
        """Return word size."""
        return self._w

    @w.setter
    def w(self, int size):
        """Set word size."""
        self._w = size
        self.__init_matrix()