function y = lteOFDMTx(in, Nrb)
%#codegen

% Copyright 2012-2013 The MathWorks, Inc.

% OFDM Transmitter includes:
%   Pack data with guards, add DC, reorder
%   IFFT and gain scale - per symbol per antenna port
%   Add cylic prefix - different length across symbols in a slot
%   Serialize subframe per antenna port
%
%   Assumes transmitting one subframe of data per timestep
%   Uses different IFFT lengths based on the channel bandwidth used.
%       - changes the output sampling rate

persistent hOFDMMod;

[len, numSymb, numLayers] = size(in);
% N assumes 15KHz subcarrier spacing, else N = 4096
switch Nrb % depends on the chanBW
    case 6
        N = 128;
        cpLen0 = 10; cpLenR = 9;
    case 15
        N = 256;
        cpLen0 = 20; cpLenR = 18;
    case 25
        N = 512;
        cpLen0 = 40; cpLenR = 36;
    case 50
        N = 1024;
        cpLen0 = 80; cpLenR = 72;
    case 75 
        N = 1536;                   
        cpLen0 = 120; cpLenR = 108; 
    case 100
        N = 2048;
        cpLen0 = 160; cpLenR = 144;
end

if isempty(hOFDMMod)
    hOFDMMod = comm.OFDMModulator( ...
        'FFTLength',            N, ...
        'NumGuardBandCarriers', [(N-len)/2; (N-len)/2-1], ...
        'InsertDCNull',         true, ...
        'PilotInputPort',       false, ...
        'CyclicPrefixLength',   [cpLen0,repmat(cpLenR,[1 6]),cpLen0,repmat(cpLenR,[1 6])], ...
        'Windowing',            false,...
        'NumSymbols',           numSymb, ...
        'NumTransmitAntennas',  numLayers);
end

y = step(hOFDMMod, in)*(N/sqrt(len));

% [EOF]
