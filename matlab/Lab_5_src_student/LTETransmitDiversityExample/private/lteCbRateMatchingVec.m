function outcast = lteCbRateMatchingVec(in, Kplus, varargin)
% Rate matching per coded block, with and without the bit selection.
%   As per TS 36.212 v10.0.0, Section 5.1.4.1.

% Copyright 2011-2013 The MathWorks, Inc.

%#codegen

% Parameters
colTcSb = 32;
D = Kplus+4;
rowTcSb = ceil(D/colTcSb);
Kpi = colTcSb * rowTcSb; 
Nd = Kpi - D;

frameLen = D*3;
NumFrames = numel(in)/frameLen;
in = reshape(in,frameLen, NumFrames);  %reshape into NumFrames columns

% Bit streams
d0 = in(1:3:end, :); % systematic
d1 = in(2:3:end, :); % parity 1st
d2 = in(3:3:end, :); % parity 2nd

colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30,...
              1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31] + 1;

%Interleaving array
p = bsxfun(@plus, colPermPat, colTcSb*(0:(rowTcSb-1))');
p = reshape(p, [],1);
p = mod(p, colTcSb*rowTcSb)+1;

% Sub-block interleaving - per stream
v = subBlkInterl([d0 d1], colTcSb, rowTcSb, Nd, colPermPat);
v0 = v(:,1:NumFrames);
v1 = v(:,NumFrames+1:end);
v2 = subBlkInterl2(d2, colTcSb, rowTcSb, Nd, p);

% Bit collection
Kw = 3*Kpi;
wk = zeros(Kw, NumFrames);

%   Concat 0, interleave 1, 2 sub-blk streams
wk(1:Kpi, :) = v0;
temp = reshape( [v1(:), v2(:)]', [], NumFrames);
wk(Kpi+1:end, :) = temp;

if (nargin==2)
    % No bit selection - output the whole buffer
    % Bit pruning and transmission (minus the null bits)

    out = zeros(numel(in),1);

    %Remove the NaNs
    if isempty(coder.target),
        out = reshape(wk(~isnan(wk)), [],1);
    else
       jj=1;
       for ii=1:numel(wk),
           if ~isnan(wk(ii)),
               out(jj) = wk(ii);
               jj = jj+1;
           end
       end
    end
    
else
    % With bit selection
    C = varargin{1};
    E = varargin{2};
    
    out = zeros(E*NumFrames, 1);
    
    % Bit Selection Parameters
    Nsoft = 3667200;  % Category 5, off Table 4.1-1, TS 36.306, v10.0.0
    Kmimo = 2;        % for Tx mode 4
    Mdlharq = 8;      % FDD, off Table 7-1, TS 36.213
    Nir = floor(Nsoft/(Kmimo*min(Mdlharq, 8)));

    rvidx = 0;        % assume a value, no HARQ support yet
    Ncb = min(floor(Nir/C), Kw);
    k0 = rowTcSb*(2*ceil(Ncb/(8*rowTcSb))*rvidx + 2);

    %Remove the NaNs using a circular buffer. To implement circular
    %buffering, create and index array that is 1x larger than it needs to
    %be and start at offset k0+1.
    %Use the shorted index array to read wk (i.e. start reading wk at
    %offset k0). Remove NaNs, and then shorten to the required output
    %length E.
    idx = [(k0+1):Ncb, 1:Ncb];
    out2tmp = wk(idx, :);
   
    %Delete the NaNs
    if isempty(coder.target),
        out2 = out2tmp(~isnan(out2tmp));
    else
       out2 = zeros(E,NumFrames);
       jj = 1;
       for ii=1:numel(out2tmp),
           if ~isnan(out2tmp(ii)),
               out2(jj) = out2tmp(ii);
               jj = jj+1;
           end
       end
    end
    out2 = reshape(out2, [], NumFrames);
    out(:) = out2(1:E, :);
    out(:) = reshape(out, [],1);
    
end
outcast = cast(out, class(in));
end

%-------------------------------------------------------------------------
function v = subBlkInterl(d, colTcSb, rowTcSb, Nd, colPermPat)
% Sub-block interleaving - for d0 and d1 streams only

%Use NaNs to mark "don't fill" locations. Interleave the NaNs using
%transpose. Note that this is vectorized in 3-dimensions to operate over
%multiple frames of data. As such the algorith uses 'permute' which is a
%generalized transpose operation.
          
numCol = size(d,2);
y = [NaN(Nd,1,numCol) ; reshape(d, [],1,numCol)];

inpMat = reshape(y, colTcSb, rowTcSb, numCol);
inpMat = permute(inpMat, [2,1,3]);
permInpMat = inpMat(:, colPermPat, :);

v = reshape(permInpMat, [], numCol);

end

%-------------------------------------------------------------------------
function v = subBlkInterl2(d, colTcSb, rowTcSb, Nd, p)
% Sub-block interleaving - for d2 stream only

%Use NaNs to mark "don't fill" locations. Interleave those with permutation
%array p. Vectorized to operate over several frames of data.
          
numCol = size(d,2); %Number of frames to operate over.

y = [NaN(Nd,numCol); d];

v = y(p,:);   %interleave the NaNs

end
