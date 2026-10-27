function [p, prm] = ltePDSCHprms(txMode, chanBW, contReg, modType, ...
                                 chanMdl, varargin)
% LTEPDSCHPRMS Returns parameter structures for LTE PDSCH simulation.
%
%   Assumes a FDD, normal cyclic prefix, full-bandwidth, single-user 
%   SISO or MIMO downlink transmission.
%
%   Three modes of operation:
%   a) SISO transmission - txMode=1:
%   [p, prm] = ltePDSCHprms(txMode, chanBW, contReg, modType, chanMdl)
%
%   b) Transmit diversity (SFBC) - txMode=2:
%   [p, prm] = ltePDSCHprms(txMode, chanBW, contReg, modType, chanMdl,...
%                           numTx, numRx)
%
%   c) Multi-codeword Spatial Multiplexing - txMode=4:
%   [p, prm] = ltePDSCHprms(txMode, chanBW, contReg, modType, chanMdl, ...
%                           antConfig, enPMIfback, cbIdx)
%
%   Used by the LTE examples.

%   Copyright 2012-2013 The MathWorks, Inc.

%% PDSCH parameters
switch chanBW
    case 1      % 1.4 MHz
        BW = 1.4e6; N = 128; cpLen0 = 10; cpLenR = 9;
        Nrb = 6; chanSRate = 1.92e6;
    case 2      % 3 MHz
        BW = 3e6; N = 256; cpLen0 = 20; cpLenR = 18;
        Nrb = 15; chanSRate = 3.84e6;
    case 3      % 5 MHz
        BW = 5e6; N = 512; cpLen0 = 40; cpLenR = 36;
        Nrb = 25; chanSRate = 7.68e6;
    case 4      % 10 MHz
        BW = 10e6; N = 1024; cpLen0 = 80; cpLenR = 72;
        Nrb = 50; chanSRate = 15.36e6;
    case 5      % 15 MHz
        BW = 15e6; N = 1536; cpLen0 = 120; cpLenR = 108;
        Nrb = 75; chanSRate = 23.04e6;
    case 6      % 20 MHz
        BW = 20e6; N = 2048; cpLen0 = 160; cpLenR = 144;
        Nrb = 100; chanSRate = 30.72e6;
end
p.BW = BW;                  % Channel bandwidth
p.N = N;                    % NFFT
p.cpLen0 = cpLen0;          % Cyclic prefix length for 1st symbol
p.cpLenR = cpLenR;          % Cyclic prefix length for remaining
p.Nrb = Nrb;                % Number of resource blocks
p.chanSRate = chanSRate;    % Channel sampling rate

% Cyclic prefix vector for 14 symbols
p.subframeCPLen = [p.cpLen0,repmat(p.cpLenR,[1 6]),p.cpLen0,repmat(p.cpLenR,[1 6])]; 

if (Nrb<=10)
    if (~ismember(contReg, [2 3 4]))
        error(message('comm:ltePDSCHprms:InvalidCReg1'));
    end
else        % Nrb>10
    if (~ismember(contReg, [1 2 3]))
        error(message('comm:ltePDSCHprms:InvalidCReg2'));
    end
end
p.contReg = contReg;

if (txMode==1) % SISO transmission

    narginchk(5, 5);

    p.numTx = 1;
    p.numRx = 1;
    numCSRRE_RB = 2*2*2; % CSR, RE per OFDMsym/slot/subframe per RB
    p.numLayers = 1;
    p.numCodeWords = 1; 

elseif (txMode==2) % Transmit diversity

    narginchk(7, 7);
    numTx = varargin{1};
    numRx = varargin{2};

    switch numTx
        case 2    % 2xnumRx
            % RE - resource element, RB - resource block
            numCSRRE_RB = 4*2*2; % CSR, RE per OFDMsym/slot/subframe per RB
        case 4      % 4xnumRx
            numCSRRE_RB = 4*3*2; % CSR, RE per OFDMsym/slot/subframe per RB
    end
    p.numTx = numTx;
    p.numRx = numRx;
    p.numLayers = 1;
    p.numCodeWords = 1; % for transmit diversity

elseif (txMode==4) % Spatial multiplexing

    narginchk(8, 8);
    antConfig  = varargin{1};
    enPMIfback = varargin{2};
    cbIdx      = varargin{3};
    
    switch antConfig
        case 1      % 2x2
            p.numTx = 2; p.numRx = 2;
            % RE - resource element, RB - resource block
            numCSRRE_RB = 4*2*2; % CSR, RE per OFDMsym/slot/subframe per RB
        case 2      % 4x4
            p.numTx = 4; p.numRx = 4;
            numCSRRE_RB = 4*3*2; % CSR, RE per OFDMsym/slot/subframe per RB
    end
    p.antConfig = antConfig;
    p.numLayers = min([p.numTx, p.numRx]);
    
    p.numCodeWords = 2; % for spatial multiplexing

end

% For Normal cyclic prefix, FDD mode
p.deltaF = 15e3;    % subcarrier spacing
p.Nrb_sc = 12;      % no. of subcarriers per resource block
p.Ndl_symb = 7;     % no. of OFDM symbols in a slot

% Left and right guard bands
p.guardBands = [(p.N-p.Nrb*p.Nrb_sc)/2; (p.N-p.Nrb*p.Nrb_sc)/2-1]; 

% Modeling a subframe worth of data (=> 2 slots)
p.numResources = (p.Nrb*p.Nrb_sc)*(p.Ndl_symb*2);
p.numCSRResources = p.Nrb * numCSRRE_RB;  
% Maximum data resources - with no extra overheads (only CSR + data)
p.numDataResources = p.numResources - p.numCSRResources; 

% Actual PDSCH bits calculation - accounting for PDCCH, PBCH, PSS, SSS
switch p.numTx
    % numRE in control region - minus the CSR
    case 1
        numContRE = (10 + 12*(p.contReg-1))*p.Nrb;
        numBCHRE = 60+72+72+72; % removing the CSR present in 1st symbol
    case 2
        numContRE = (8 + 12*(p.contReg-1))*p.Nrb; 
        numBCHRE = 48+72+72+72; % removing the CSR present in 1st symbol
    case 4
        numContRE = (8 + (p.contReg>1)*(8+ 12*(p.contReg-2)))*Nrb; 
        numBCHRE = 48+48+72+72; % removing the CSR present in 1,2 symbol
end
p.numContRE = numContRE;
p.numBCHRE = numBCHRE;

if modType==1       % QPSK
    Qm = 2;
elseif modType==2   % 16QAM
    Qm = 4;
elseif modType==3   % 64QAM
    Qm = 6;
end
p.Qm = Qm;
p.numLayPerCW = p.numLayers/p.numCodeWords;

% Maximum data bits - with no extra overheads (only CSR + data)
p.numDataBits = p.numDataResources*Qm*p.numLayPerCW;

numPDSCHBits = zeros(1,3);
% Account for BCH, PSS, SSS and PDCCH for subframe 0
numPDSCHBits(1) = (p.numDataResources - ...
                   (numBCHRE+72+72+numContRE))*Qm*p.numLayPerCW;
% Account for PSS, SSS and PDCCH for subframe 5
numPDSCHBits(2) = (p.numDataResources - (72+72+numContRE))*Qm*p.numLayPerCW;
% Account for PDCCH only in all other subframes
numPDSCHBits(3) = (p.numDataResources - numContRE)*Qm*p.numLayPerCW;
% Note, the above array-filling order is used while simulating
p.numPDSCHBits = numPDSCHBits;
p.maxG = max(numPDSCHBits);

% Channel parameters
prm.chanMdl = chanMdl;

% PDSCH Receiver parameters
if (txMode==4) % Spatial multiplexing
    prm.enPMIfback = enPMIfback;
    if (~prm.enPMIfback) % when feedback is off, check index values specified
        if (p.numTx==2) && (cbIdx < 1 || cbIdx > 2)
            error(message('comm:ltePDSCHprms:InvalidCbIdx2'));
        elseif (p.numTx==4) && (cbIdx > 15 || cbIdx < 0)
            error(message('comm:ltePDSCHprms:InvalidCbIdx4'));
        end
    end
    prm.cbIdx = cbIdx;
end

% [EOF]
