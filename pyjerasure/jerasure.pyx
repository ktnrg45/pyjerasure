# cython: language_level=3, boundscheck=True
"""Implementation for pyjerasure."""

import array
from cpython cimport array
from libc.stdlib cimport malloc, calloc, free
from libc.string cimport memcpy

from pyjerasure cimport jerasure


cdef class Matrix():
    """Matrix Class."""
    TYPES = ["cauchy", "cauchy_good", "rs_vandermonde", "rs_r6", "liberation", "blaum_roth"]

    def __cinit__(self, str type, int k = 0, int m = 0, int word_size = 0):
        self.k = k
        self.m = m
        self.word_size = word_size
        self.is_bitmatrix = False
        self.type = type

        if type == "cauchy":
            self.ptr = jerasure.cauchy_original_coding_matrix(k, m, word_size)
        elif type == "cauchy_good":
            self.ptr = jerasure.cauchy_good_general_coding_matrix(k, m, word_size)
        elif type == "rs_vandermonde":
            self.ptr = jerasure.reed_sol_vandermonde_coding_matrix(k, m, word_size)
            self.row_k_ones = 1
        elif type == "rs_r6":
            self.ptr = jerasure.reed_sol_r6_coding_matrix(k, word_size)
            self.m = 2
        elif type == "liberation":
            self.ptr = jerasure.liberation_coding_bitmatrix(k, word_size)
            self.m = 2
            self.is_bitmatrix = True
        elif type == "blaum_roth":
            self.ptr = jerasure.blaum_roth_coding_bitmatrix(k, word_size)
            self.m = 2
            self.is_bitmatrix = True
        else:
            raise ValueError(f"type must be one of {self.TYPES}")

    def __dealloc__(self):
        if self.ptr != NULL:
            free(self.ptr)
            self.ptr = NULL

    def __repr__(self):
        return f"{str(self.__class__)[:-1]} type={self.type} valid={self.valid}>"

    def print_matrix(self):
        """Print matrix."""
        if self.is_bitmatrix:
            jerasure.jerasure_print_bitmatrix(self.ptr, self.m * self.word_size, self.k * self.word_size, self.word_size)
        else:
            jerasure.jerasure_print_matrix(self.ptr, self.m, self.k, self.word_size)

    @property
    def valid(self) -> bool:
        """Return True if matrix is valid."""
        return self.ptr != NULL


def __check_size(int size, int data_size):
    if size % sizeof(long) != 0:
        raise ValueError(f"Size must be divisible by {sizeof(long)}")
    if data_size % size != 0:
        raise ValueError(f"Data Size must be divisible by size")


def __check_matrix(Matrix matrix, int packetsize):
    if matrix.is_bitmatrix:
        if packetsize <= 0:
            raise ValueError("Packet Size must be greater than 0")
        if matrix.word_size < 1 or matrix.word_size > 32:
            raise ValueError("word_size must be between 1 and 32")
    else:
        if matrix.word_size not in (8, 16, 32):
            raise ValueError("word_size must be one of (8, 16, 32)")

cdef int allocate_erasures(int k, int* erasures, erased):
    cdef int i = 0
    cdef int erased_index = 0
    for i in range(len(erased)):
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


def decode(matrix: Matrix, data: bytes, erasures, size: int, packetsize: int = 0):
    """Return original data."""
    __check_matrix(matrix, packetsize)
    __check_size(size, len(data))

    cdef int *erasures_ptr = <int *> calloc(len(erasures) + 1, sizeof(int));
    cdef char **data_ptrs = <char **> calloc(matrix.k, sizeof(char *))
    cdef char **coding_ptrs = <char **> calloc(matrix.m, sizeof(char *))
    cdef array.array data_array = array.array("I", data)

    allocate_erasures(matrix.k, erasures_ptr, erasures)
    allocate_block_ptrs(matrix.k, matrix.m, size, data_array, data_ptrs, coding_ptrs)
    if matrix.is_bitmatrix:
        result = jerasure.jerasure_bitmatrix_decode(matrix.k, matrix.m, matrix.word_size, matrix.ptr, matrix.row_k_ones, erasures_ptr, data_ptrs, coding_ptrs, size, packetsize)
    else:
        result = jerasure.jerasure_matrix_decode(matrix.k, matrix.m, matrix.word_size, matrix.ptr, matrix.row_k_ones, erasures_ptr, data_ptrs, coding_ptrs, size)

    free(data_ptrs)
    free(coding_ptrs)
    free(erasures_ptr)

    if result < 0:
        return b""
    return data_array.tobytes()


def encode(matrix: Matrix, data: bytes, size: int, packetsize: int = 0):
    """Return data with coding blocks concatenated."""
    __check_matrix(matrix, packetsize)
    data = data.ljust((matrix.k + matrix.m) * size, b"\x00")
    __check_size(size, len(data))

    cdef char **data_ptrs = <char **> calloc(matrix.k, sizeof(char *))
    cdef char **coding_ptrs = <char **> calloc(matrix.m, sizeof(char *))
    cdef array.array data_array = array.array("I", data)

    allocate_block_ptrs(matrix.k, matrix.m, size, data_array, data_ptrs, coding_ptrs)
    if matrix.is_bitmatrix:
        jerasure.jerasure_bitmatrix_encode(matrix.k, matrix.m, matrix.word_size, matrix.ptr, data_ptrs, coding_ptrs, size, packetsize)
    else:
        jerasure.jerasure_matrix_encode(matrix.k, matrix.m, matrix.word_size, matrix.ptr, data_ptrs, coding_ptrs, size)

    free(data_ptrs)
    free(coding_ptrs)

    return data_array.tobytes()
