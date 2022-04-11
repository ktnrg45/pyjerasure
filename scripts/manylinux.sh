#!/bin/bash

DIR="/wheels"
apt update && apt install -y libjerasure-dev

py_versions=(/opt/python/*)

mkdir $DIR
mkdir dist

for ver in "${py_versions[@]}"; do
    echo $ver
    pip="$ver/bin/pip"
    $pip install --upgrade --no-cache-dir pip

    if [ -z $cythonized ]; then
        $pip install cython
        $ver/bin/python setup.py build_ext --inplace
        $pip uninstall cython -y
        cythonized=true
    fi

    $pip wheel . -w $DIR --no-deps
done

cd /
wheels=($DIR/*.whl)
for wheel in "${wheels[@]}"; do
    auditwheel repair $wheel
done

echo $(ls ./wheelhouse)
