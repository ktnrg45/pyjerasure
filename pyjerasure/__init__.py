"""Init for Jerasure."""
import sys

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


def align_size(w: int, size: int) -> int:
    """Return Aligned Size. Size should be divisible by w."""
    return ((size + w - 1) // w) * w
