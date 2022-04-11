#!/bin/bash

DIR="/wheels"
sudo apt update && sudo apt install -y libjerasure-dev

py_versions=(/opt/python/*)

mkdir $DIR

for ver in "${py_versions[@]}"; do
    pip="$ver/bin/pip"
    $pip install --upgrade --no-cache-dir pip
    $pip wheel /src -w $DIR --no-deps
done

cd /
wheels=($DIR/*.whl)
for wheel in "${wheels[@]}"; do
    auditwheel repair $wheel
done

built_wheels=(wheelhouse/*.whl)
echo $built_wheels
