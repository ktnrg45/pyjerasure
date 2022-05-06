#!/bin/sh

is_alpine=$(find "/etc/alpine-release")
[[ $OSTYPE == 'darwin'* ]] && is_macos=1
echo $is_macos

if [ -z $is_alpine ] && [ -z $is_macos ]; then
    apt update && apt install libjerasure-dev -y && exit 0
fi

if [ ! -z $is_macos ]; then
    brew install autoconf automake libtool
else
    apk add build-base autoconf automake libtool git
fi

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