function y = lteREMapper(in, csr, nS, prmLTEPDSCH)
%#codegen

% Copyright 2012 The MathWorks, Inc.

% Hard-coded parameters
NmaxDL_RB = 110;    % largest downlink bandwidth configuration, in resource blocks
NcellID = 0;        % One of possible 504 values

% Get input params
Nrb = prmLTEPDSCH.Nrb;              % = 100 for 20 MHz
Nrb_sc = prmLTEPDSCH.Nrb_sc;        % = 12
Ndl_symb = prmLTEPDSCH.Ndl_symb;    % = 7*2
numResources = prmLTEPDSCH.numResources;    
numContSymb    = prmLTEPDSCH.contReg;   % num OFDM symbols

% Preallocate output per subframe - zeros indicate no transmissions
% numTx == numLayers, switched for varS, else numLayers = size(in,2)
numTx = prmLTEPDSCH.numTx;    
y = complex(zeros(Nrb*Nrb_sc, Ndl_symb*2, numTx));

% Grid filling:
%     fill the input (keeping out the CSR indexes, plus the other overhead)
%     get the CSR indexes, add the CSR signals
%
%   For only data and CSR:
%     E.g. for 20Mhz, 100 - Nrb, 4x4 config, QPSK, 2 codewords
%       input data - 14400x4
%       csr - 220x2x2x4
%       Needed output - 16800x4 -> 1200x14x4
%     Input data filling:
%       14400 to be mapped to 16800 => 1200*8 + 800*6 as [800 800 1200 1200 800
%       1200 1200] for a slot, and then repeated for a subframe
%       Same for all ports
%     Reference signal (CSR) filling:
%       per subframe per port, 2400 values added => get out of CSR input
%       => 400x6 out of 220x2x2 
%          => 400 = 200 overlap not transmitted + 200 out of 220
%          => x6 = 2 overlap not transmitted + 4 out of 2x2
%       Different indices per antenna port
%
%   For data, CSR and full overhead of PBCH, PSS, SSS, PDCCH
%   E.g.: for 10Mhz, 2Tx, 2 Ctrl region scheme => 50 Nrb
%   Input varies as per [6216, 6600 6600 6600 6600, 6456, 6600 6600 6600
%   6600] for a radio frame where per subframe
%               MaxRE    CSR       PDCCH      PBCH        PSS  SSS   DATA
%   SubFrame0 = 600*14 - 4*50*4 - (8+12)*50 - (48+72*3) - 72 - 72  = 6192
%   SubFrame5 = 600*14 - 4*50*4 - (8+12)*50             - 72 - 72  = 6456
%   OtherSF   = 600*14 - 4*50*4 - (8+12)*50                        = 6600
%   For a 4Tx scenario, PBCH - 48+48+72*2 = 240

% Grid per subframe - columnized per port
%   initialized to all zeros
tmp = complex(zeros(numResources, numTx));

%% Build up data indices for symbols with CSR
%   Assumes NcellID = 0;
%   Account for PDCCH, PBCH, PSS, SSS after the CSR-less data indices

if (numTx>1) % for 2, 4    
    %   Per OFDM symbol is common for numLayers = 2, 4
    dtIdx_OFDMSym_wCsr = zeros((Nrb_sc-4), Nrb);
    for i = 1:Nrb
        dtIdx_OFDMSym_wCsr(:, i) = [2;3;5;6;8;9;11;12]+12*(i-1);
    end
    dtIdx_OFDMSym_wCsrCol = dtIdx_OFDMSym_wCsr(:);
else % for 1
    % Only 2 reference symbols per RB
    dtIdx_OFDMSym_wCsr = zeros((Nrb_sc-2), Nrb);
    dtIdx_OFDMSym2_wCsr = zeros((Nrb_sc-2), Nrb);
    for i = 1:Nrb
        dtIdx_OFDMSym_wCsr(:, i) = [2:6 8:12].'+12*(i-1);
        dtIdx_OFDMSym2_wCsr(:, i) = [1:3 5:9 11:12].'+12*(i-1);
    end
    dtIdx_OFDMSym_wCsrCol = dtIdx_OFDMSym_wCsr(:);
    dtIdx_OFDMSym2_wCsrCol = dtIdx_OFDMSym2_wCsr(:);
end
lenOFDM = dtIdx_OFDMSym_wCsrCol(end);
dtIdx_OFDMSym = (1:lenOFDM).';    

if (numTx==1)
    % Slot filling specific to numLayers = 1
    dtIdx_slot = [dtIdx_OFDMSym_wCsrCol; dtIdx_OFDMSym+lenOFDM; ...
                  dtIdx_OFDMSym+2*lenOFDM; dtIdx_OFDMSym+3*lenOFDM;...
                  dtIdx_OFDMSym2_wCsrCol+4*lenOFDM;...
                  dtIdx_OFDMSym+5*lenOFDM; dtIdx_OFDMSym+6*lenOFDM];    
elseif (numTx==2)
    % Slot filling specific to numLayers = 2
    dtIdx_slot = [dtIdx_OFDMSym_wCsrCol; dtIdx_OFDMSym+lenOFDM; ...
                  dtIdx_OFDMSym+2*lenOFDM; dtIdx_OFDMSym+3*lenOFDM;...
                  dtIdx_OFDMSym_wCsrCol+4*lenOFDM;...
                  dtIdx_OFDMSym+5*lenOFDM; dtIdx_OFDMSym+6*lenOFDM];    
elseif (numTx==4)
    % Slot filling specific to numLayers = 4
    dtIdx_slot = [dtIdx_OFDMSym_wCsrCol; dtIdx_OFDMSym_wCsrCol+lenOFDM; ...
                  dtIdx_OFDMSym+2*lenOFDM; dtIdx_OFDMSym+3*lenOFDM;...
                  dtIdx_OFDMSym_wCsrCol+4*lenOFDM;...
                  dtIdx_OFDMSym+5*lenOFDM; dtIdx_OFDMSym+6*lenOFDM];    
end
lenSlot = dtIdx_slot(end);
dtIdx_subframe = [dtIdx_slot; dtIdx_slot+lenSlot];

%%
% Account for PDCCH - remove the data idxes for these RE - in all subframes
numContRE = numContSymb * Nrb * Nrb_sc;
dtIdx_subframe(dtIdx_subframe <= numContRE) = [];

% PBCH, PSS, SSS share the same center sub-carrier locations
%   they differ in the OFDM symbol number in the slots/subframe
idx = (0:71).';
centerReIdx = idx - 36 + Nrb*Nrb_sc/2;
PSSReIdx = centerReIdx + lenOFDM*6;
SSSReIdx = centerReIdx + lenOFDM*5;
PBCHStrIdx = ones(4,1);
switch nS
    case {0}
        % Account for PBCH - first 4 symbols in slot 1
        for i = 1:4
            PBCHReIdx = centerReIdx+lenSlot+(i-1)*lenOFDM;
            PBCHStrIdx(i) = find(dtIdx_subframe==PBCHReIdx(1));
        end
        if (numTx==1)
            % Account for CSR only
            temp = reshape(idx, [], Nrb_sc);
            temp2 = temp(1:5, :);
            idx2 = temp2(:);
            % In reverse order - 4th, 3rd, 2nd symbols of slot1 - no CSR
            dtIdx_subframe(PBCHStrIdx(4)+idx) = [];
            dtIdx_subframe(PBCHStrIdx(3)+idx) = [];
            dtIdx_subframe(PBCHStrIdx(2)+idx) = [];
        else
            % Account for CSR & null indices
            temp = reshape(idx, 3, 24);
            temp2 = temp(1:2, :);
            idx2 = temp2(:);
            % In reverse order - 4th and 3rd symbols of slot1 - no CSR
            dtIdx_subframe(PBCHStrIdx(4)+idx) = [];
            dtIdx_subframe(PBCHStrIdx(3)+idx) = [];
            % 2nd symbol of slot1
            if (numTx==2)
                dtIdx_subframe(PBCHStrIdx(2)+idx) = []; % no CSR
            elseif (numTx==4)
                dtIdx_subframe(PBCHStrIdx(2)+idx2) = []; % has CSR
            end
        end
        % 1st symbol of slot1 - has CSR
        dtIdx_subframe(PBCHStrIdx(1)+idx2) = [];
                
        % Account for PSS, SSS 
        for i=1:length(PSSReIdx)
            dtIdx_subframe(dtIdx_subframe==PSSReIdx(i)) = [];
            dtIdx_subframe(dtIdx_subframe==SSSReIdx(i)) = [];
        end
    case {10}
        % Account for PSS, SSS 
        for i=1:length(PSSReIdx)
            dtIdx_subframe(dtIdx_subframe==PSSReIdx(i)) = [];
            dtIdx_subframe(dtIdx_subframe==SSSReIdx(i)) = [];
        end
    otherwise % no other overheads
        % Do nothing
end

% Assign input data to output grid per antenna port
tmp(dtIdx_subframe, :) = in;

% Grid output
for i = 1:numTx
   y(:, :, i)  = reshape(tmp(:, i), Nrb*Nrb_sc, Ndl_symb*2);
end

% Assign CSR signals to the grid
% Add the cell-specific reference signals as per Section 6.10.1.2.
%     Based on the actual Nrb in use - subselect the samples within the 
%     OFDM symbol - from the center outward.
%     apply this per antenna port 

%% Determine CSR indices in subframe - per antenna port
%   Assign out of csr input into the grid using the CSR indices
csrIdx = zeros(Nrb*2, 2, 2, numTx);

%   Get the common first antenna port sequence indexes
vsh = mod(NcellID, 6);
numRb = (0:2*Nrb-1).';
for lIdx = 1:2  % symbol-wise
   v = 3*(lIdx-1);  
   csrIdx(:, lIdx, 1, 1) = 6*numRb + mod(v+vsh, 6) + 1; % 1-based indexes 
end
csrIdx(:,:,2,1) = csrIdx(:,:,1,1); % second slot = first slot
    
%   Flip the set of indices for second antenna port, if it exists
if (numTx > 1) % == 2
    csrIdx(:,1,1,2) = csrIdx(:,2,1,1); % first slot, first symbol
    csrIdx(:,2,1,2) = csrIdx(:,1,1,1); % first slot, second symbol
    csrIdx(:,:,2,2) = csrIdx(:,:,1,2); % second slot = first slot
end    

%   Also generate the sequence indexes for l=1 index for numTx = 4
if (numTx > 2) % == 3, 4
    for i = 1:2  % slot-wise
        v = 3*(i-1); % for AP=3
        csrIdx(:, 1, i, 3) = 6*numRb + mod(v+vsh, 6) + 1; % 1-based indexes 
    end
    
    for i = 1:2  % slot-wise
        v = 3 + 3*(i-1); % for AP=4
        csrIdx(:, 1, i, 4) = 6*numRb + mod(v+vsh, 6) + 1; % 1-based indexes 
    end
end

% CSR read indices per OFDM symbol - for the input sequences
mp = numRb + NmaxDL_RB - Nrb + 1; % 1-based indexes

%% Add the CSR to the grid in the pre-determined indices
%   Common first antenna port
y(csrIdx(:, 1, 1, 1), 1, 1) = csr(mp, 1, 1, 1);
y(csrIdx(:, 2, 1, 1), 5, 1) = csr(mp, 2, 1, 1);
y(csrIdx(:, 1, 2, 1), 8, 1) = csr(mp, 1, 2, 1);
y(csrIdx(:, 2, 2, 1), 12, 1) = csr(mp, 2, 2, 1);

%   for second antenna port, if it exists
if (numTx > 1) % == 2
    y(csrIdx(:, 1, 1, 2), 1, 2) = csr(mp, 1, 1, 2);
    y(csrIdx(:, 2, 1, 2), 5, 2) = csr(mp, 2, 1, 2);
    y(csrIdx(:, 1, 2, 2), 8, 2) = csr(mp, 1, 2, 2);
    y(csrIdx(:, 2, 2, 2), 12, 2) = csr(mp, 2, 2, 2);
end

%   for third and fourth antenna ports, if they exist
if (numTx > 2) % == 3, 4
    y(csrIdx(:, 1, 1, 3), 2, 3) = csr(mp, 1, 1, 3);
    y(csrIdx(:, 1, 2, 3), 9, 3) = csr(mp, 1, 2, 3);

    y(csrIdx(:, 1, 1, 4), 2, 4) = csr(mp, 1, 1, 4);
    y(csrIdx(:, 1, 2, 4), 9, 4) = csr(mp, 1, 2, 4);
end

% [EOF]
