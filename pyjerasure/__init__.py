"""Init for Jerasure."""
from typing import Iterable

from .jerasure import Matrix, decode, encode, align_size


def decode_from_bytes(
    matrix: Matrix,
    data: bytes,
    erasures: Iterable[int],
    size: int,
    packetsize: int = 0,
    data_only: bool = False,
) -> bytes:
    """Return decoded data. Passthrough to decode.

    :param matrix: Matrix
    :param data: An array of bytes which is the original data with the coding data appended.
        All blocks must be zero padded to size.
        Erased blocks must consist of zeroed bytes (\x00)
    :param erasures: An iterable of ints which describes the indexes of missing/erased blocks.
    :param size: The size/length of a data block.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    :param data_only: If True return data blocks only, else return data and coding blocks.
    """
    return decode(matrix, data, erasures, size, packetsize, data_only)


def encode_from_bytes(
    matrix: Matrix, data: bytes, size: int, packetsize: int = 0
) -> bytes:
    """Return data with coding data appended. Passthrough to encode.

    :param matrix: Matrix
    :param data: An array of bytes which is the original data.
        All blocks must be zero padded to size.
    :param size: The size/length of a data block.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    """
    return encode(matrix, data, size, packetsize)


def decode_from_blocks(
    matrix: Matrix,
    blocks: Iterable[bytes],
    erasures: Iterable[int],
    packetsize: int = 0,
    data_only: bool = False,
) -> "list[bytes]":
    """Return list of decoded data blocks.

    :param matrix: Matrix
    :param blocks: An iterable of bytes which is the original data blocks with the coding blocks appended.
        Blocks will be padded automatically.
    :param erasures: An iterable of ints which describes the indexes of missing/erased blocks.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    :param data_only: If True return data blocks only, else return data and coding blocks.
    """
    if len(blocks) < 1:
        raise ValueError("Length of blocks cannot be < 1")

    max_size = max([len(block) for block in blocks])
    size = align_size(matrix, max_size, packetsize)
    data = []
    for block in blocks:
        data.append(block.ljust(size, b"\x00"))
    decoded = decode(matrix, b"".join(data), erasures, size, packetsize, data_only)
    if not decoded:
        return []
    if data_only:
        assert len(decoded) == matrix.k * size
        return [
            decoded[index * size : (index + 1) * size] for index in range(0, matrix.k)
        ]
    assert len(decoded) == (matrix.k + matrix.m) * size
    return [
        decoded[index * size : (index + 1) * size]
        for index in range(0, matrix.k + matrix.m)
    ]


def encode_from_blocks(
    matrix: Matrix,
    blocks: Iterable[bytes],
    packetsize: int = 0,
) -> "list[bytes]":
    """Return list of data blocks appended with coding blocks.

        First coding block is at index matrix.k

    :param matrix: Matrix
    :param blocks: An iterable of bytes which is the original data blocks.
        Blocks will be padded automatically.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    """
    if len(blocks) < 1:
        raise ValueError("Length of blocks cannot be < 1")
    max_size = max([len(block) for block in blocks])
    size = align_size(matrix, max_size, packetsize)
    data = []
    for block in blocks:
        data.append(block.ljust(size, b"\x00"))
    encoded = encode(matrix, b"".join(data), size, packetsize)
    if not encoded:
        return []
    assert len(encoded) == (matrix.k + matrix.m) * size
    return [
        encoded[index * size : (index + 1) * size]
        for index in range(0, matrix.k + matrix.m)
    ]
