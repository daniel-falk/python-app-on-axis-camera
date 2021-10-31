"""
Simple main file to test the cython wrappers for the c functions
"""

from dummy_data import py_get_numbers
import numpy as np

if __name__ == "__main__":
    numbers = np.array(py_get_numbers(5))
    print(numbers)
    print("Sum of numbers: ", np.sum(numbers))
