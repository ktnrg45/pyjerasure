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
  b"data-456",
]
```
First we import the library and setup our matrix.

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
#   b'data-456\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'\x1f\n\x1e\x00\x0b\x05\x07\x05\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'\x0c\r\xc2\x02fy}a\x00\x00\x00\x00\x00\x00\x00\x00']
#
```
Notice how our data has been padded with zeroed bytes.
This is necessary for encoding our data.
The `*_from_blocks` method automatically pads data to the correct length.


Now we're going to simulate a loss of data by deleting 'm' blocks.

```
missing = [2, 3]
for i in missing:
  coded_data[i] = b""
print(coded_data)

#  Outputs:
#
#  [b'hello\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'world\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'',
#   b'',
#   b'\x1f\n\x1e\x00\x0b\x05\x07\x05\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'\x0c\r\xc2\x02fy}a\x00\x00\x00\x00\x00\x00\x00\x00']
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
#   b'data-456\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'\x1f\n\x1e\x00\x0b\x05\x07\x05\x00\x00\x00\x00\x00\x00\x00\x00',
#   b'\x0c\r\xc2\x02fy}a\x00\x00\x00\x00\x00\x00\x00\x00']
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
