#!/usr/bin/env python
"""Setup for Jerasure."""
import sys
import subprocess
from pathlib import Path
from setuptools import find_packages, setup, Extension


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
    if sys.platform == "win32":
        include_path = "Include"
    else:
        include_path = get_include_path()

    name = "pyjerasure.jerasure"
    include_dirs = [include_path]
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
                ),
            ]
        )
    except ImportError:
        sources = ["pyjerasure/jerasure.c"]
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
