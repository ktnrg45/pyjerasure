#!/bin/sh

is_alpine=$(find "/etc/alpine-release")
if [ -z $is_alpine ]; then
    apt update && apt install libjerasure-dev -y && exit 0
fi

apk add build-base autoconf automake libtool git

cd /
git clone https://github.com/ktnrg45/jerasure.git --recurse-submodules
cd jerasure/gf-complete
autoreconf -fvi
./configure
make install -j4
cd ../
autoreconf -fvi
./configure
make install -j4
mv /usr/local/include/jerasure/* /usr/local/include
cd /project