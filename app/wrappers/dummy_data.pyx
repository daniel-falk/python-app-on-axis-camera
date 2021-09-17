cimport numpy as np
cimport cpython


cdef extern from "dummy_data.h":
    unsigned char *get_numbers(int)
    void free_numbers(unsigned char *)


def py_get_numbers(length: int):
    cdef unsigned char *data = get_numbers(length)
    try:
        return [data[addr] for addr in range(length)]
    finally:
        free_numbers(data)
