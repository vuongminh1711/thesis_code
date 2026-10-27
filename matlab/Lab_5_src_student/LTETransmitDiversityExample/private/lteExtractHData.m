function hD  = lteExtractHData(h, nS, prmLTEPDSCH)
%LTEEXTRACTHDATA Extract channel estimates for data RE.
%
%   From the input channel estimates for all RE in the grid (minus the CSR)
%   extract, the CE for the DATA RE, 
%   i.e. ignore REs for PDCCH, PBCH, PSS, SSS.

%   Copyright 2012 The MathWorks, Inc.

%#codegen

maxK = size(h, 1);
coder.varsize('dtIdx_subframe', [maxK 1], [1 0]);
dtIdx_subframe = (1:maxK).';

Nrb = prmLTEPDSCH.Nrb;              % = 100 for 20 MHz
Nrb_sc = prmLTEPDSCH.Nrb_sc;        % = 12
numContSymb    = prmLTEPDSCH.contReg;   % control region, numOFDM symbols
numTx = prmLTEPDSCH.numTx;  
numRx = prmLTEPDSCH.numRx;  

lenOFDM = Nrb*Nrb_sc;
lenSlot = maxK/2;
idx = (0:71).';
offset = Nrb*Nrb_sc/2 - 36;
centerReIdx = offset + idx;
centerReIdxMinusCSR = offset/3;  %account for lack of CSR in idx_subframe
PBCHStrIdx = ones(4,1); 
switch numTx
    case 1
        numContRE = (10 + 12*(numContSymb-1))*Nrb;
        lenOFDMwCSR = Nrb*(Nrb_sc-2); 
        PSSStrReIdx = lenOFDMwCSR*2 + lenOFDM*4 + centerReIdx(1);
        SSSStrReIdx = lenOFDMwCSR*2 + lenOFDM*3 + centerReIdx(1);
        PBCHStrIdx(1) = centerReIdx(1)-centerReIdxMinusCSR+lenSlot;
        PBCHStrIdx(2) = centerReIdx(1)+lenSlot+lenOFDMwCSR;
        PBCHStrIdx(3) = centerReIdx(1)+lenSlot+lenOFDMwCSR+lenOFDM;
        PBCHStrIdx(4) = centerReIdx(1)+lenSlot+lenOFDMwCSR+lenOFDM*2;
    case 2
        numContRE = (8 + 12*(numContSymb-1))*Nrb; 
        lenOFDMwCSR = Nrb*(Nrb_sc-4); 
        PSSStrReIdx = lenOFDMwCSR*2 + lenOFDM*4 + centerReIdx(1);
        SSSStrReIdx = lenOFDMwCSR*2 + lenOFDM*3 + centerReIdx(1);
        PBCHStrIdx(1) = centerReIdx(1)-centerReIdxMinusCSR+lenSlot;
        PBCHStrIdx(2) = centerReIdx(1)+lenSlot+lenOFDMwCSR;
        PBCHStrIdx(3) = centerReIdx(1)+lenSlot+lenOFDMwCSR+lenOFDM;
        PBCHStrIdx(4) = centerReIdx(1)+lenSlot+lenOFDMwCSR+lenOFDM*2;
    case 4
        numContRE = (8 + (numContSymb>1)*(8+ 12*(numContSymb-2)))*Nrb; 
        lenOFDMwCSR = Nrb*(Nrb_sc-4); 
        PSSStrReIdx = lenOFDMwCSR*3 + lenOFDM*3 + centerReIdx(1);
        SSSStrReIdx = lenOFDMwCSR*3 + lenOFDM*2 + centerReIdx(1);
        PBCHStrIdx(1) = centerReIdx(1)-centerReIdxMinusCSR+lenSlot;
        PBCHStrIdx(2) = centerReIdx(1)-centerReIdxMinusCSR+lenSlot+lenOFDMwCSR;
        PBCHStrIdx(3) = centerReIdx(1)+lenSlot+lenOFDMwCSR*2;
        PBCHStrIdx(4) = centerReIdx(1)+lenSlot+lenOFDMwCSR*2+lenOFDM;
    otherwise
        % Do nothing
end

%Remove indices in reverse order
switch nS
    case {0}
        % Account for PBCH - first 4 symbols in slot 1
        dtIdx_subframe(PBCHStrIdx(4)+idx) = []; % no CSR
        dtIdx_subframe(PBCHStrIdx(3)+idx) = []; % no CSR
        temp = reshape(idx, 3, 24);
        temp2 = temp(1:2, :);
        idx2 = temp2(:);
        if numTx==2
            dtIdx_subframe(PBCHStrIdx(2)+idx) = []; % no CSR
        elseif numTx==4
            dtIdx_subframe(PBCHStrIdx(2)+idx2) = []; % has CSR
        end
        % 1st symbol of slot1 - has CSR
        dtIdx_subframe(PBCHStrIdx(1)+idx2) = [];

        % Account for PSS, SSS 
        dtIdx_subframe(PSSStrReIdx + idx) = [];
        dtIdx_subframe(SSSStrReIdx + idx) = [];
    case {10}
        % Account for PSS, SSS 
        dtIdx_subframe(PSSStrReIdx + idx) = [];
        dtIdx_subframe(SSSStrReIdx + idx) = [];
    otherwise % no extra per subframe overheads
        % Do nothing
end

%% Account for PDCCH - minus CSR, for all subframes
dtIdx_subframe(dtIdx_subframe <= numContRE) = [];

%% Output channel estimates for Data REs only
hD = complex(zeros(length(dtIdx_subframe), numTx, numRx));
for i=1:numTx
    for j = 1:numRx
        hD(:, i, j) = h(dtIdx_subframe, i, j);
    end
end

% [EOF]
