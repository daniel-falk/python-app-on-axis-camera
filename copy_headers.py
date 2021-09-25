from pathlib import Path
import numpy as np
import shutil
import os
import sysconfig
import sys


def _mk_and_copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dst)


def copy_headers(to_dir):
    to_dir = Path(to_dir)

    arch = os.popen("gcc -dumpmachine").read().strip()
    python_include = Path(sysconfig.get_paths()["include"])
    python_name = python_include.name
    python_arch_include = python_include.parent / arch / python_name
    numpy_include = Path(np.get_include())

    _mk_and_copy(python_include, to_dir / "python")
    _mk_and_copy(python_arch_include, to_dir / "arch" / arch / python_name)
    _mk_and_copy(numpy_include, to_dir / "packages")


if __name__ == "__main__":
    copy_headers(sys.argv[1])
