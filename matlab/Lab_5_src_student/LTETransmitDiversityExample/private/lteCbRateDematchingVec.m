function outcast = lteCbRateDematchingVec(in, Kplus, varargin)
% Undoes the Rate matching per coded block.
%   As per TS 36.212 v10.0.0, Section 5.1.4.1.

% Copyright 2011-2013 The MathWorks, Inc.

%#codegen

% Parameters
colTcSb = 32;
D = Kplus+4;
rowTcSb = ceil(D/colTcSb);
Kpi = colTcSb * rowTcSb;
Nd = Kpi - D;

colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30,...
              1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31] + 1;

% Interleaving array
p = bsxfun(@plus, colPermPat, colTcSb*(0:(rowTcSb-1))');
p = reshape(p, [], 1);
p = mod(p, colTcSb*rowTcSb)+1;

% Recreate buffer at RX
%   Sub-block interleaving - per stream - for NAN location in buffer
l0 = subBlkInterl(colTcSb, rowTcSb, Nd, colPermPat);
l1 = l0;
l2 = subBlkInterl2(colTcSb, rowTcSb, Nd, p);
lk = [l0; reshape([l1 l2]', [], 1)];

% if (nargin==2)
    % no bit selection - assume full buffer passed in
    % Bit streams
    
    frameLen = D*3;
    NumFrames = numel(in)/frameLen;
    in = reshape(in, frameLen, NumFrames); 

    lkMat = lk(:, ones(1, NumFrames));
    lkMatNan = zeros(size(lkMat));
    lkMatNan(lkMat==0) = NaN;
    
    lkMatNan(~isnan(lkMatNan)) = in;
    out = zeros(numel(in), 1);

% else % unused for now
%     % Account for bit selection and puncturing
%     C = varargin{1};
%     E = varargin{2};
%     
%     frameLen = E;
%     NumFrames = numel(in)/frameLen;
%     in = reshape(in, frameLen, NumFrames); 
% 
%     out = zeros((Kplus*3 + 12)* NumFrames, 1);
%     
%     Nsoft = 3667200;  % Category 5, off Table 4.1-1, TS 36.306, v10.0.0
%     Kmimo = 2;        % for Tx mode 4
%     Mdlharq = 8;      % FDD, off Table 7-1, TS 36.213
%     Nir = floor(Nsoft/(Kmimo*min(Mdlharq, 8)));
%     
%     Kw = 3*Kpi;
%     rvidx = 0;                  % assume a value, no HARQ support yet
%     Ncb = min(floor(Nir/C), Kw);
%     k0 = rowTcSb*(2*ceil(Ncb/(8*rowTcSb))*rvidx + 2); % Offset
% 
%     lkMat = lk(:, ones(1, NumFrames));
%     lkMatNan = zeros(size(lkMat));
%     lkMatNan(lkMat==0) = NaN;
% 
%     k = 1; j = 0;
%     while (k <= frameLen) 
%         temp = lkMatNan(mod(k0+j, Ncb)+1,1);
%         if (~isnan(temp))
%             lkMatNan(mod(k0+j, Ncb)+1, :) = in(k, :);
%             k = k+1;
%         end
%         j = j+1;
%     end
%     
% end

% Separate bit streams - with NaNs
td0 = lkMatNan(1:Kpi, :);
td1 = lkMatNan(Kpi+1:2:end, :);
td2 = lkMatNan(Kpi+2:2:end, :);

d0 = td0(~isnan(td0(:,1)), :);
d1 = td1(~isnan(td1(:,1)), :);
d2 = td2(~isnan(td2(:,1)), :);

% Sub-block deinterleaving - per stream
v0 = subBlkDeinterl(d0, colTcSb, rowTcSb, Nd, colPermPat);
v1 = subBlkDeinterl(d1, colTcSb, rowTcSb, Nd, colPermPat);
v2 = subBlkDeinterl2(d2, colTcSb, rowTcSb, Nd, p);

% Interleave 1, 2, 3 sub-blk streams - for turbo decoding
temp = permute([v0 v1 v2], [2 1 3]);
out(:) = temp(:);
outcast = cast(out, class(in));

end

%-------------------------------------------------------------------------
function out = subBlkDeinterl(in, colTcSb, rowTcSb, Nd, colPermPat)
% Sub-block deinterleaving - for d0 and d1 streams only

numCol = size(in,2);

%Create a logical array with 'trues' where data should be written. Write
%the input data to an array of the same size. Transpose, interleave rows,
%and output.

coder.varsize('inMat');

inMat = zeros(rowTcSb, colTcSb, numCol);
inMatlidx = true(rowTcSb, colTcSb, numCol);

inMatlidx(1, colPermPat(1:Nd),:) = false;
inMat(inMatlidx) = in;

inMatPerm = permute(inMat(:, colPermPat, :), [2 1 3]);  %Transpose
inMatPermReduced = reshape(inMatPerm, [], numCol);
inMatPermReduced = inMatPermReduced(Nd+1:end, :);   %interleave rows
out = reshape(inMatPermReduced, [], 1, numCol);     %output as a column

end

%-------------------------------------------------------------------------
function out = subBlkDeinterl2(in, colTcSb, rowTcSb, Nd, p)
% Sub-block interleaving - for d2 stream only

numCol = size(in,2);

%Create a logical array with 'trues' where data should be written. Write
%the input data to an array of the same size. Create a permutation vector
%p. Shuffle the logical indexing array using p. Use the new index array to
%permute the input. Suffle into the output.

coder.varsize('inPerm');
coder.varsize('out');

lidx = true(colTcSb, rowTcSb);
lidx(1:Nd,1) = false;
lidx = reshape(lidx(p), [], 1);
inPerm = zeros(rowTcSb*colTcSb, numCol);
inPerm(lidx, :) = in;
outtmp = zeros(rowTcSb*colTcSb,numCol);
outtmp(p,:) = inPerm;
outtmp2 = outtmp((Nd+1):end, :); % Delete first Nd elements in each column.
out = zeros(size(in,1), 1, size(in,2));
out(:) = outtmp2;

end

%-------------------------------------------------------------------------
function l = subBlkInterl(colTcSb, rowTcSb, Nd, colPermPat)
% Sub-block interleaving - for d0 and d1 streams only
%Create a logical matrix, l, which is true where data should be written and
%false otherwise.

x = true(rowTcSb, colTcSb);
x(1,(colPermPat(1:Nd))) = false; % Assumes Nd<colTcSb, Nd<numel(colPermPat)
l = x(:);

end

%-------------------------------------------------------------------------
function l = subBlkInterl2(colTcSb, rowTcSb, Nd, p)
% Sub-block interleaving - for d2 stream only

%Create a logical matrix, l, which is true where data should be written and
%false otherwise. Create a permutation vector, p, to interleave the trues
%and falses.

x = true(rowTcSb*colTcSb,1);
x(1:Nd) = false;
l = x(p);

end
