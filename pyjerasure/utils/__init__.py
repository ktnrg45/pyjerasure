"""Utils."""
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from pyjerasure import Matrix


def align_size(matrix: "Matrix", size: int, packetsize: int = 0) -> int:
    """Return Aligned Size."""
    if matrix.is_bitmatrix:
        if packetsize <= 0:
            raise ValueError("packetsize must be > 0")
        width = matrix.w * packetsize
    else:
        width = 16
    if size % width == 0:
        return size
    return ((size + width - 1) // width) * width
