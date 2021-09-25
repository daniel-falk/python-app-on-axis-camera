import os
from setuptools import setup, Extension
from Cython.Build import cythonize

def get_include_dirs():
    def all_subdirs(path):
        return [os.path.join(path, sub_dir) for sub_dir in os.listdir(path)]
    return ["src/", *all_subdirs("/include")]

extensions = [
        Extension(
            "dummy_data",
            ["wrappers/dummy_data.pyx", "src/dummy_data.c"],
            include_dirs=get_include_dirs(),
        )
]


setup(
        name="hello_numbers",
        ext_modules=cythonize(extensions)
)
