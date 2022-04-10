"""Init for Jerasure."""
import sys
from typing import Iterable

# pylint: disable=import-outside-toplevel
def __load():
    """Try to load dlls."""
    from importlib import resources
    import platform
    import ctypes

    try:
        with resources.path("pyjerasure", ".libs") as lib_path:
            lib_path /= f"{sys.platform}_{platform.machine()}".lower()
        dll_files = [str(_file) for _file in lib_path.glob("*.dll")]
        for dll in dll_files:
            for lib_name in ("libJerasure", "libgf_complete"):
                if lib_name in dll:
                    ctypes.CDLL(dll)
    except Exception:  # pylint: disable=broad-except
        pass


if sys.platform == "win32":
    __load()

# pylint: disable=wrong-import-position
from .jerasure import Matrix, decode, encode


def align_size(matrix: Matrix, size: int, packetsize: int = 0) -> int:
    """Return Aligned Size."""
    if matrix.is_bitmatrix:
        if packetsize <= 0:
            raise ValueError("Packet size must be > 0")
        width = matrix.w * packetsize
    else:
        width = 16
    return ((size + width - 1) // width) * width


def decode_from_bytes(
    matrix: Matrix, data: bytes, erasures: Iterable[int], size: int, packetsize: int = 0
) -> bytes:
    """Return decoded data. Passthrough to decode.

    :param matrix: Matrix
    :param data: An array of bytes which is the original data with the coding data appended.
        All blocks must be zero padded to size.
        Erased blocks must consist of zeroed bytes (\x00)
    :param erasures: An iterable of ints which describes the indexes of missing/erased blocks.
    :param size: The size/length of a data block.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    """
    return decode(matrix, data, erasures, size, packetsize)


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
) -> "list[bytes]":
    """Return list of decoded data blocks.

    :param matrix: Matrix
    :param blocks: An iterable of bytes which is the original data blocks with the coding blocks appended.
        Blocks will be padded automatically.
    :param erasures: An iterable of ints which describes the indexes of missing/erased blocks.
    :param packetsize: Packet size of packets in blocks. Only needed for bitmatrixes.
    """
    if len(blocks) < 1:
        raise ValueError("Length of blocks cannot be < 1")
    max_size = len(sorted(blocks, key=lambda _block: len(_block), reverse=True)[0])
    size = align_size(matrix, max_size, packetsize)
    data = []
    for block in blocks:
        data.append(block.ljust(size, b"\x00"))
    decoded = decode(matrix, b"".join(data), erasures, size, packetsize)
    if not decoded:
        return []
    assert len(decoded) == matrix.k * size
    return [decoded[index * size : (index + 1) * size] for index in range(0, matrix.k)]


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
    max_size = len(sorted(blocks, key=lambda _block: len(_block), reverse=True)[0])
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
