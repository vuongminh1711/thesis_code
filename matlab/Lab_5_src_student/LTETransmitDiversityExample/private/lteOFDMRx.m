function y = lteOFDMRx(in, Nrb, Nrb_sc, Ndl_symb)
%#codegen

% Copyright 2012-2013 The MathWorks, Inc.

% OFDM Receiver: inverse of OFDM Transmitter, includes
%   Remove Cyclic prefix per symbol
%       Get back per symbol per Rx antenna - N x numSymbs x numLayers
%   Take FFT and gain scale
%   Remove guards and reorder
%   Get back to numDataTones x numSymb x numLayers
%
%   Assumes receiving one subframe of data per timestep
%   Uses different FFT lengths based on the channel bandwidth used.

persistent hOFDMDemod;

% For a subframe of data
numDataTones = Nrb*Nrb_sc;
numSymb = Ndl_symb*2; 
[~, numLayers] = size(in);
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

if isempty(hOFDMDemod)
    hOFDMDemod = comm.OFDMDemodulator( ...
        'FFTLength',            N, ...
        'NumGuardBandCarriers', [(N-numDataTones)/2; (N-numDataTones)/2-1], ...
        'RemoveDCCarrier',      true, ...
        'PilotOutputPort',      false, ...
        'CyclicPrefixLength',   [cpLen0,repmat(cpLenR,[1 6]),cpLen0,repmat(cpLenR,[1 6])], ...
        'NumSymbols',           numSymb, ...
        'NumReceiveAntennas',   numLayers);
end

y = step(hOFDMDemod, in)/(N/sqrt(numDataTones));

% [EOF]
