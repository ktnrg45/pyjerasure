# pyjerasure
Python Wrapper library for libjerasure

Only basic encoding/decoding methods are implemented.

## Usage

In this example we have blocks of data that we would like to protect against data loss. 

```
data = [
  b"hello",
  b"world",
  b"data-123",
  b"data-0123456789A",
]
```
First we import the library and setup our matrix.

There are multiple matrix types available which can be shown with `Matrix.TYPES`
```
import pyjerasure

matrix_type = "rs_r6"
k = 4  # Number of data blocks
m = 2  # Number of coding blocks. This is also the maximum number of blocks that can be lost.
w = 8  # Word Size

matrix = pyjerasure.Matrix(matrix_type, k, m, w)
```
Next we encode our data using the matrix.
This adds redundant coding blocks to our data.

```
coded_data = pyjerasure.encode_from_blocks(matrix, data)
print(coded_data)

#  Outputs:
#
#  [b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'world\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'data-123\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'data-0123456789A',
#   b'\x1f\n\x1e\x00\x0b\x01\x03\x013456789A',
#   b'\x0c\r\xc2\x02fY]A\x85\xbd\xb5\xad\xa5\xdd\xd52']
#
```
Notice how some of our data has been padded with zeroed bytes.
This is necessary for encoding our data.
The `*_from_blocks` method automatically pads data to the correct length.


Now we're going to simulate a loss of data by deleting 'm' blocks.

```
missing = [1, 3]
for i in missing:
  coded_data[i] = b""
print(coded_data)

#  Outputs:
#
#  [b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'',
#   b'data-123\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'',
#   b'\x1f\n\x1e\x00\x0b\x01\x03\x013456789A',
#   b'\x0c\r\xc2\x02fY]A\x85\xbd\xb5\xad\xa5\xdd\xd52']
#
```

Recovering the data can be done if we know the indexes of the missing blocks.

```
restored = pyjerasure.decode_from_blocks(matrix, coded_data, missing)
print(restored)

#  Outputs:
#
#  [b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'world\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'data-123\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'data-0123456789A',
#   b'\x1f\n\x1e\x00\x0b\x01\x03\x013456789A',
#   b'\x0c\r\xc2\x02fY]A\x85\xbd\xb5\xad\xa5\xdd\xd52']
#
```
Blocks can be encoded and decoded as a byte string using the `*_from_bytes` methods.
Each block needs to be padded in respect to the longest block. The `align_size` method returns the appropriate size for each block.
The `Matrix.align_block` method pads each block.

```
matrix_type = "cauchy"
matrix = pyjerasure.Matrix(matrix_type, k, m, w)
size = max([len(block) for block in data])
padded = [matrix.align_block(block, size) for block in data]
padded_data = b"".join(padded)
encoded = pyjerasure.encode_from_bytes(matrix, padded_data, size)
print(encoded)

#  Outputs:
#
#  b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
#    world\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
#    data-123\x00\x00\x00\x00\x00\x00\x00\x00
#    data-0123456789A
#    M\x8a\xea\x01+\xb0\xdem\x0f]\xfa\x0e\xa9\xaa\r\x15
#    2\x89\xef\x01RP\xe3\x8d\xc5\rJ\x83\xc4\x0eIW'
#

block_size = len(encoded) // (matrix.k + matrix.m)
erased = bytearray(encoded)
erased[:block_size * 2] = bytes(block_size * 2) # Erase first two blocks.
erased = bytes(erased)
print(erased)

#  Outputs:
#
#  b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
#    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00 
#    data-123\x00\x00\x00\x00\x00\x00\x00\x00
#    data-0123456789A
#    M\x8a\xea\x01+\xb0\xdem\x0f]\xfa\x0e\xa9\xaa\r\x15
#    2\x89\xef\x01RP\xe3\x8d\xc5\rJ\x83\xc4\x0eIW'
#

erasures = [0, 1]
restored = pyjerasure.decode_from_bytes(matrix, erased, erasures, size)
print(restored)

#  Outputs:
#
#  b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
#    world\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00
#    data-123\x00\x00\x00\x00\x00\x00\x00\x00
#    data-0123456789A
#    M\x8a\xea\x01+\xb0\xdem\x0f]\xfa\x0e\xa9\xaa\r\x15
#    2\x89\xef\x01RP\xe3\x8d\xc5\rJ\x83\xc4\x0eIW'
#

```

# Installing

## Using pip
```
pip install pyjerasure
```

## From Source
Installing from source requires `libjerasure-dev` to be installed.
In addition, `cython` may need to be installed as well.

```
pip install cython
python setup.py install build_ext
```


# Original License

Copyright (c) 2013, James S. Plank and Kevin Greenan
All rights reserved.

Jerasure - A C/C++ Library for a Variety of Reed-Solomon and RAID-6 Erasure Coding Techniques

Revision 2.0: Galois Field backend now links to GF-Complete

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

 - Neither the name of the University of Tennessee nor the names of its
   contributors may be used to endorse or promote products derived
   from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
