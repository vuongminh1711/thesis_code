import numpy as np

def load_iq_u8(filename: str, normalize: bool = True) -> np.ndarray:
    raw = np.fromfile(filename, dtype=np.uint8)

    if raw.size % 2 != 0:
        raise ValueError("IQ file contains odd number of samples")

    # Convert to float [-1, 1]
    raw = raw.astype(np.float32)
    raw = (raw - 127.5) / 127.5

    i = raw[0::2]
    q = raw[1::2]

    iq = i + 1j * q

    return iq.astype(np.complex64)


def save_complex_npy(filename: str, iq: np.ndarray) -> None:
    np.save(filename, iq)


def load_complex_npy(filename: str) -> np.ndarray:
    iq = np.load(filename)
    return iq.astype(np.complex64)