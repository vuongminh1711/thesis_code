function y = lteTDEncode(in, numTx)
%LTETDENCODE Encode input using transmit diversity as per LTE.
%
%   Reference: Section 6.3.4.3 of 3GPP TS 36.211, v10.0.0.

%   Copyright 2012 The MathWorks, Inc.

%   Both SFBC and SFBC with FSTD
%   With no input validation, using the OSTBC objects.

persistent hTDEnc;
if isempty(hTDEnc)
    % Use same object for either scheme
    hTDEnc = comm.OSTBCEncoder('NumTransmitAntennas', 2);
end

inLen = size(in, 1);
in(2:2:end) = -conj(in(2:2:end)); % Apply SF to ST transformation

if (numTx == 2) % SFBC
    y = step(hTDEnc, in);
elseif (numTx == 4) % SFBC with FSTD
    y = complex(zeros(inLen, numTx));
    idx12 = ([1:4:inLen; 2:4:inLen]); idx12 = idx12(:);
    idx34 = ([3:4:inLen; 4:4:inLen]); idx34 = idx34(:);
    y(idx12, [1 3]) = step(hTDEnc, in(idx12));
    y(idx34, [2 4]) = step(hTDEnc, in(idx34));
end

% Scale
y = y/sqrt(2);

% [EOF]
