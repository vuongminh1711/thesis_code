import numpy as np
from scipy.signal import correlate
PSS_ROOTS = {0: 25, 1: 29, 2: 34}

def generate_pss_sequence(nid2: int) -> np.ndarray:
    if nid2 not in PSS_ROOTS:
        raise ValueError("nid2 must be 0, 1, or 2")

    u = PSS_ROOTS[nid2]
    Nzc = 63

    pss = np.zeros(62, dtype=np.complex64)

    # n = 0..30
    for n in range(31):
        pss[n] = np.exp(-1j * np.pi * u * n * (n + 1) / Nzc)

    # n = 31..61
    for n in range(31, 62):
        pss[n] = np.exp(-1j * np.pi * u * (n + 1) * (n + 2) / Nzc)

    return pss

def map_pss_to_bins(pss_62: np.ndarray, nfft: int) -> np.ndarray:
    if len(pss_62) != 62:
        raise ValueError("pss_62 must have length 62")

    X = np.zeros(nfft, dtype=np.complex64)
    center = nfft // 2

    # 31 bins below DC
    X[center - 31:center] = pss_62[:31]

    # 31 bins above DC
    X[center + 1:center + 32] = pss_62[31:]

    return X

def generate_pss_time_domain(nid2: int, nfft: int) -> np.ndarray:
    """
    Generate time-domain LTE PSS OFDM symbol (without CP).
    """
    pss_62 = generate_pss_sequence(nid2)
    X = map_pss_to_bins(pss_62, nfft)

    x = np.fft.ifft(np.fft.ifftshift(X))

    norm = np.linalg.norm(x)
    if norm > 0:
        x = x / norm

    return x.astype(np.complex64)

def detect_pss(iq: np.ndarray, nfft: int) -> list:
    iq = iq / (np.max(np.abs(iq)) + 1e-12)
    best_nid2 = None
    best_peak = -1
    best_index = None
    

    for nid2 in range(3):
        pss = generate_pss_time_domain(nid2, nfft)
        metric = np.abs(correlate(iq, np.conj(pss[::-1]), mode="valid"))

        peak_index = int(np.argmax(metric))
        peak_value = float(metric[peak_index])

        print(f"NID2={nid2}, peak={peak_value:.4f}, index={peak_index}")

        if peak_value > best_peak:
            best_peak = peak_value
            best_index = peak_index
            best_nid2 = nid2

    result = [best_nid2, best_peak, best_index]
    return result
