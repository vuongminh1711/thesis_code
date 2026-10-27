function [out, Wn] = lteSpatialMuxPrecoder(in, prmLTEPDSCH, cbIdx)
% LTE Precoder for PDSCH spatial multiplexing.
%
%   As per TS 36.211 v10.0.0, Section 6.3.4.2.3.

%   Copyright 2012 The MathWorks, Inc.

%#codegen

% Assumes the incoming codewords are of the same length
v = prmLTEPDSCH.numLayers;              % Number of layers
numTx = prmLTEPDSCH.numTx;              % Number of Tx antennas

inLen = size(in, 1);
j = complex(0,1);

switch numTx
    case 2
        Wn = complex(ones(numTx, v));
        switch cbIdx
            case 0
                switch v
                    case 1 
                        Wn = (1/sqrt(2))*[1 1].';
                    case 2
                        assert(false, 'Not used. Please try with a different index.');
                end
            case 1
                switch v
                    case 1 
                        Wn = (1/sqrt(2))*[1 -1].';
                    case 2
                        Wn = (1/2)*[1 1; 1 -1];
                end
            case 2
                switch v
                    case 1 
                        Wn = (1/sqrt(2))*[1 j].';
                    case 2
                        Wn = (1/2)*[1 1; j -j];
                end
            case 3
                switch v
                    case 1 
                        Wn = (1/sqrt(2))*[1 -j].';
                    case 2
                        assert(false, 'Not defined. Please try with a different index.');
                end                
        end
    case 4        
        un = complex(ones(numTx, 1));
        switch cbIdx
            case 0
                un = [1 -1 -1 -1].';
            case 1
                un = [1 -j 1 j].';
            case 2
                un = [1 1 -1 1].';
            case 3
                un = [1 j 1 -j].';
            case 4
                un = [1 (-1-j)/sqrt(2) -j (1-j)/sqrt(2)].';
            case 5
                un = [1 (1-j)/sqrt(2) j (-1-j)/sqrt(2)].';
            case 6
                un = [1 (1+j)/sqrt(2) -j (-1+j)/sqrt(2)].';
            case 7
                un = [1 (-1+j)/sqrt(2) j (1+j)/sqrt(2)].';
            case 8
                un = [1 -1 1 1].';
            case 9
                un = [1 -j -1 -j].';
            case 10
                un = [1 1 1 -1].';
            case 11
                un = [1 j -1 j].';
            case 12
                un = [1 -1 -1 1].';
            case 13
                un = [1 -1 1 -1].';
            case 14
                un = [1 1 -1 -1].';
            case 15
                un = [1 1 1 1].';
        end
        Wn = eye(4) - 2*(un*un')./(un'*un);
        switch cbIdx    % order columns, for numLayers=4 only
            case {2, 3, 14}
                Wn = Wn(:, [3 2 1 4]);
            case {6, 7, 10, 11, 13}
                Wn = Wn(:, [1 3 2 4]);
        end
        Wn = Wn./sqrt(v);
    case 8
        % Release 10
        assert(false, 'Not implemented yet.');
end

out = complex(zeros(size(in)));
% Apply the relevant precoding matrix to the symbol over all layers
for i = 1:inLen
    temp = Wn * (in(i, :).'); 
    out(i, :) = temp.';
end
