from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
        Extension(
            "dummy_data",
            ["wrappers/dummy_data.pyx", "src/dummy_data.c"],
            include_dirs=["src/"]
        )
]


setup(
        name="hello_numbers",
        ext_modules=cythonize(extensions)
)
