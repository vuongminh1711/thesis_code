function y = lteMIMOReceiver(in, chEst, prmLTEPDSCH, snrdB, Wn)
%#codegen

% Copyright 2012 The MathWorks, Inc.

% LTE MIMO Receiver:
%   Based on received channel estimates, process the data elements
%   to equalize the MIMO channel. Uses the ZF or the MMSE detector.
%   For now, MMSE detector is active, uncomment lines below to switch
%   to ZF detector.

% Get params
numLayers = prmLTEPDSCH.numLayers;              % Number of layers
% Assume same number of Tx and Rx antennas = numLayers
snrLin = 10^(0.1*snrdB);
noisFac = numLayers/snrLin * eye(numLayers);

numData = size(in, 1);
y = complex(zeros(size(in)));

iWn = inv(Wn);

% ZF receiver
% for i = 1:numData
%     h = squeeze(chEst(i, :, :)); % numTx x numRx
%     h = h.';                     % numRx x numTx
%     
%     Q = inv(h);
%     x = Q * in(i, :).';
%     tmp = iWn * x;
%     y(i, :) = tmp.';
% 
%     % Alternate implementation of ZF
% %     w = h*Wn*(inv(Wn'*h'*h*Wn));
% %     tmp = w' * in(i, :).';
% %     y(i, :) = tmp.';
% end

% MMSE receiver
for i = 1:numData
    h = chEst(i, :, :);                         % numTx x numRx
    h = reshape(h(:), numLayers, numLayers).';  % numRx x numTx

    Q = (h'*h + noisFac)\h';
    x = Q * in(i, :).';
    tmp = iWn * x; %#ok
    y(i, :) = tmp.';

    % Alternate implementations of MMSE
%     w = h * (inv(h'*h + noisFac));
%     tmp = w' * in(i, :).';
%     x = iWn*tmp;
%     y(i, :) = x.';

%     w = h*Wn * (inv(Wn'*h'*h*Wn + noisFac));
%     tmp = w' * in(i, :).';
%     y(i, :) = tmp.';
end

% [EOF]
