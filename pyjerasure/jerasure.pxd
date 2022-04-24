# cython: language_level=3, boundscheck=True
# distutils: language=c++
"""Definitions for Jerasure."""


cdef extern from "jerasure.h" nogil:

    cdef int *jerasure_matrix_to_bitmatrix(int k, int m, int w, int *matrix)
    cdef int **jerasure_dumb_bitmatrix_to_schedule(int k, int m, int w, int *bitmatrix)
    cdef int **jerasure_smart_bitmatrix_to_schedule(int k, int m, int w, int *bitmatrix)
    cdef int ***jerasure_generate_schedule_cache(int k, int m, int w, int *bitmatrix, int smart)

    cdef void jerasure_free_schedule(int **schedule)
    cdef void jerasure_free_schedule_cache(int k, int m, int ***cache)


    cdef void jerasure_do_parity(int k, char **data_ptrs, char *parity_ptr, int size)

    cdef void jerasure_matrix_encode(int k, int m, int w, int *matrix, char **data_ptrs, char **coding_ptrs, int size)

    cdef void jerasure_bitmatrix_encode(int k, int m, int w, int *bitmatrix, char **data_ptrs, char **coding_ptrs, int size, int packetsize)

    cdef void jerasure_schedule_encode(int k, int m, int w, int **schedule, char **data_ptrs, char **coding_ptrs, int size, int packetsize)

    cdef int jerasure_matrix_decode(int k, int m, int w, int *matrix, int row_k_ones, int *erasures, char **data_ptrs, char **coding_ptrs, int size)
                            
    cdef int jerasure_bitmatrix_decode(int k, int m, int w, int *bitmatrix, int row_k_ones, int *erasures, char **data_ptrs, char **coding_ptrs, int size, int packetsize)

    cdef int jerasure_schedule_decode_lazy(int k, int m, int w, int *bitmatrix, int *erasures,char **data_ptrs, char **coding_ptrs, int size, int packetsize, int smart)

    cdef int jerasure_schedule_decode_cache(int k, int m, int w, int ***scache, int *erasures,char **data_ptrs, char **coding_ptrs, int size, int packetsize)

    cdef int jerasure_make_decoding_matrix(int k, int m, int w, int *matrix, int *erased, int *decoding_matrix, int *dm_ids)

    cdef int jerasure_make_decoding_bitmatrix(int k, int m, int w, int *matrix, int *erased, int *decoding_matrix, int *dm_ids)

    cdef int *jerasure_erasures_to_erased(int k, int m, int *erasures)

 
    cdef void jerasure_matrix_dotprod(int k, int w, int *matrix_row, int *src_ids, int dest_id, char **data_ptrs, char **coding_ptrs, int size)

    cdef void jerasure_bitmatrix_dotprod(int k, int w, int *bitmatrix_row,int *src_ids, int dest_id,char **data_ptrs, char **coding_ptrs, int size, int packetsize)

    cdef void jerasure_do_scheduled_operations(char **ptrs, int **schedule, int packetsize)


    cdef int jerasure_invert_matrix(int *mat, int *inv, int rows, int w)
    cdef int jerasure_invert_bitmatrix(int *mat, int *inv, int rows)
    cdef int jerasure_invertible_matrix(int *mat, int rows, int w)
    cdef int jerasure_invertible_bitmatrix(int *mat, int rows)

    cdef int *jerasure_matrix_multiply(int *m1, int *m2, int r1, int c1, int r2, int c2, int w)

    cdef void jerasure_print_matrix(int *matrix, int rows, int cols, int w)
    cdef void jerasure_print_bitmatrix(int *matrix, int rows, int cols, int w)
    cdef void jerasure_get_stats(double *fill_in)


cdef extern from "cauchy.h" nogil:
    cdef int *cauchy_original_coding_matrix(int k, int m, int w)
    cdef int *cauchy_xy_coding_matrix(int k, int m, int w, int *x, int *y)
    cdef void cauchy_improve_coding_matrix(int k, int m, int w, int *matrix)
    cdef int *cauchy_good_general_coding_matrix(int k, int m, int w)
    cdef int cauchy_n_ones(int n, int w)


cdef extern from "liberation.h" nogil:
    cdef int *liberation_coding_bitmatrix(int k, int w)
    cdef int *liber8tion_coding_bitmatrix(int k)
    cdef int *blaum_roth_coding_bitmatrix(int k, int w)


cdef extern from "reed_sol.h" nogil:
    cdef int *reed_sol_vandermonde_coding_matrix(int k, int m, int w)
    cdef int *reed_sol_extended_vandermonde_matrix(int rows, int cols, int w)
    cdef int *reed_sol_big_vandermonde_distribution_matrix(int rows, int cols, int w)

    cdef int reed_sol_r6_encode(int k, int w, char **data_ptrs, char **coding_ptrs, int size)
    cdef int *reed_sol_r6_coding_matrix(int k, int w)

    cdef void reed_sol_galois_w08_region_multby_2(char *region, int nbytes)
    cdef void reed_sol_galois_w16_region_multby_2(char *region, int nbytes)
    cdef void reed_sol_galois_w32_region_multby_2(char *region, int nbytes)


cdef class Matrix:
    cdef int *ptr
    cdef readonly str type
    cdef readonly int _k
    cdef readonly int _m
    cdef readonly int _w
    cdef readonly int row_k_ones
    cdef readonly bint is_bitmatrix