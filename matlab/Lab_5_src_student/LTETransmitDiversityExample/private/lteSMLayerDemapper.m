function [out1, out2] = lteSMLayerDemapper(in, prmLTEPDSCH)
% LTE Layer demapper for spatial multiplexing.
%
%   Assumes two codeword input for spatial multiplexing.
%   Based on TS 36.211 v10.0.0, Section 6.3.3.2.

%   Copyright 2012-2013 The MathWorks, Inc.

%#codegen
%   Assumes the incoming codewords are of the same length. Assumes the
%   input signal is oriented similarly as the output of the layer mapper.

q = prmLTEPDSCH.numCodeWords;       % Number of codewords
v = size(in, 2);                    % Number of layers

switch q
    case 1  % Single codeword
        temp = in.';
        out1 = temp(:);
        out2 = out1; % dummy
    case 2  % Two codewords
        switch v
            case 2
                out1 = in(:,1);
                out2 = in(:,2);
            case 4
                temp = in(:,1:2).';
                out1 = temp(:);
                temp = in(:,3:4).';
                out2 = temp(:);
            case 6
                temp = in(:,1:3).';
                out1 = temp(:);
                temp = in(:,4:6).';
                out2 = temp(:);
            case 8
                temp = in(:,1:4).';
                out1 = temp(:);
                temp = in(:,5:8).';
                out2 = temp(:);
            otherwise
                out1 = in;
                out2 = in;
        end
    otherwise
        out1 = in;
        out2 = in;
end
