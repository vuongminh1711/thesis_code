import numpy as np
import pandas as pd

# Read CSV, header is automatically handled
filepath = "/home/dawn/Documents/MATLAB/VRI/data/IQDataFile1.csv"
df = pd.read_csv(
    filepath,
    skiprows=19,
    header=None
)

# Column 0 = I, Column 1 = Q
I = pd.to_numeric(df.iloc[:, 0], errors="coerce")
Q = pd.to_numeric(df.iloc[:, 1], errors="coerce")

# Remove any bad/non-numeric rows
valid = I.notna() & Q.notna()
I = I[valid].to_numpy(dtype=np.float32)
Q = Q[valid].to_numpy(dtype=np.float32)

iq = I + 1j * Q

# GNU Radio complex64 binary
iq.astype(np.complex64).tofile("/home/dawn/Documents/VRI/iqdata_complex64.bin")

print("Saved iqdata_complex64.bin")
print("Number of IQ samples:", len(iq))
