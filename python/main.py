import io_utils
import pss

NFFT_BANDWIDTH = {
    1.4: 128,
    3: 256,
    5: 512,
    10: 1024,
    20: 2048
}

def main():
    iq = io_utils.load_iq_u8("data/lte_763.iq")
    nfft = NFFT_BANDWIDTH[10]
    result = pss.detect_pss(iq, nfft)
    print(f"Detected PSS: nid2={result[0]}, peak={result[1]:.4f}, index={result[2]}")

if __name__ == "__main__":
    main()