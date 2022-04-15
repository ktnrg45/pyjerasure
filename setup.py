#!/usr/bin/env python
"""Setup for Jerasure."""
import sys
import os
import subprocess
from pathlib import Path
from setuptools import find_packages, setup, Extension


ARG_INCLUDE = "--include="  # include dir
ARG_LIB = "--lib="  # library dir
PYJERASURE_INCLUDE = "PYJERASURE_INCLUDE"
PYJERASURE_LIB = "PYJERASURE_LIB"


def get_include_path():
    """Find default gcc include path.

    jerasure.h expects galois.h to be in the same directory so we need to specify the header directory.
    """
    default = "/usr/include/jerasure"
    try:
        process = subprocess.run(
            ["gcc", "-E", "-Wp,", "-v", "-xc", "/dev/null"],
            check=True,
            timeout=1,
            capture_output=True,
        )
    except Exception:  # pylint: disable=broad-except
        return default
    output = process.stderr
    if not output:
        return default
    lines = output.decode().splitlines()
    for line in lines:
        path = Path(line.lstrip())
        if path.is_dir():
            include_path = path / "jerasure"
            if include_path.is_dir():
                return str(include_path)
    return default


def build_extensions():
    """Return extensions."""
    library_dirs = []
    include_dirs = []
    # Check args first
    args = list(sys.argv)
    for arg in args:
        if arg.startswith(ARG_INCLUDE):
            include_dirs = [arg.split("=")[-1]]
            sys.argv.remove(arg)
            continue
        if arg.startswith(ARG_LIB):
            library_dirs = [arg.split("=")[-1]]
            sys.argv.remove(arg)
            continue

    # Check env vars
    if not include_dirs:
        env_include = os.environ.get(PYJERASURE_INCLUDE)
        if env_include:
            include_dirs = [env_include]
    if not library_dirs:
        env_lib = os.environ.get(PYJERASURE_LIB)
        if env_lib:
            library_dirs = [env_lib]

    if not include_dirs:
        if sys.platform == "win32":
            include_dirs = ["Include"]
        else:
            include_dirs = [get_include_path()]
    if not library_dirs:
        if sys.platform == "win32":
            library_dirs = ["libs"]

    name = "pyjerasure.jerasure"
    libraries = ["Jerasure", "gf_complete"]
    try:
        # pylint: disable=import-outside-toplevel
        from Cython.Build import cythonize

        sources = ["pyjerasure/jerasure.pyx"]
        extensions = cythonize(
            [
                Extension(
                    name,
                    sources,
                    include_dirs=include_dirs,
                    libraries=libraries,
                    library_dirs=library_dirs,
                ),
            ]
        )
    except ImportError:
        sources = ["pyjerasure/jerasure.cpp"]
        extensions = [
            Extension(
                name,
                sources,
                include_dirs=include_dirs,
                libraries=libraries,
            ),
        ]
    return extensions


SRC_DIR = "pyjerasure"
version_data = {}
version_path = Path.cwd() / SRC_DIR / "__version__.py"
with open(version_path, encoding="utf-8") as fp:
    exec(fp.read(), version_data)

VERSION = version_data["VERSION"]
MIN_PY_VERSION = version_data["MIN_PY_VERSION"]

REQUIRES = list(open("requirements.txt"))

CLASSIFIERS = [
    "Development Status :: 4 - Beta",
    "License :: OSI Approved :: Apache Software License",
    "Natural Language :: English",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3.8",
    "Topic :: Software Development :: Libraries :: Python Modules",
]

with open("README.md") as f:
    README = f.read()

setup(
    name="pyjerasure",
    version=VERSION,
    description="Python Wrapper for Jerasure",
    long_description=README,
    long_description_content_type="text/markdown",
    author="ktnrg45",
    author_email="ktnrg45dev@gmail.com",
    packages=find_packages(exclude=["tests"]),
    url="https://github.com/ktnrg45/pyjerasure",
    license="Apache",
    classifiers=CLASSIFIERS,
    keywords="jerasure erasure erasures",
    install_requires=REQUIRES,
    python_requires=">={}".format(MIN_PY_VERSION),
    test_suite="tests",
    ext_modules=build_extensions(),
    zip_safe=False,
)
