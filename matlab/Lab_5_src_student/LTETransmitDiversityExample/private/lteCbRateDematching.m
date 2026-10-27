function out = lteCbRateDematching(in, Kplus, varargin)
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

Kw = 3*Kpi;
wk = zeros(Kw, 1);
% Recreate buffer at RX
%   Sub-block interleaving - per stream - for NAN location in buffer
v0_0 = subBlkInterl(zeros(D,1), colTcSb, rowTcSb, Nd);
v1_0 = subBlkInterl(zeros(D,1), colTcSb, rowTcSb, Nd);
v2_0 = subBlkInterl2(zeros(D,1), colTcSb, rowTcSb, Nd);

%   Concat 0, interleave 1, 2 sub-blk streams
wk(1:Kpi) = v0_0;
temp = [v1_0 v2_0].';
wk(Kpi+1:end) = temp(:); % has the NANs at the right locations

if (nargin==2)
    % no bit selection - assume full buffer passed in
    %   Fill incoming data at the right location accounting for NaNs in wk
    k = 1; j = 1;
    while (k <= 3*Kpi)  % wk is of length 3*Kpi
        w = wk(k);
        if ~isnan(w)
            wk(k) = in(j);
            j = j+1;
        end
        k = k+1;
    end
    
else
    % Account for bit selection and puncturing
    C = varargin{1};
    E = varargin{2};
    Nsoft = 3667200;  % Category 5, off Table 4.1-1, TS 36.306, v10.0.0
    Kmimo = 2;        % for Tx mode 4
    Mdlharq = 8;      % FDD, off Table 7-1, TS 36.213
    Nir = floor(Nsoft/(Kmimo*min(Mdlharq, 8)));
    
    rvidx = 0;                  % assume a value, no HARQ support yet
    Ncb = min(floor(Nir/C), Kw);
    k0 = rowTcSb*(2*ceil(Ncb/(8*rowTcSb))*rvidx + 2); % Offset

    %   Fill incoming data at the right location accounting for offset (k0)
    %   and NaNs in wk (using a circular buffer). 
    %   Trailing punctures are already zero'ed in the buffer.
    k = 1; j = 0;
    while (k <= E)  % "in" is of length E
        w = wk(mod(k0+j, Ncb)+1);
        if ~isnan(w)
            wk(mod(k0+j, Ncb)+1) = in(k);
            k = k+1;
        end
        j = j+1;
    end
        
end

% Separate bit streams - with NaNs
td0 = wk(1:Kpi);
td1 = wk(Kpi+1:2:end);
td2 = wk(Kpi+2:2:end);

% remove NANs from streams 
d0 = zeros(D, 1);  % systematic
k = 1; j = 1;
while (k <= D)
    temp = td0(j);
    if ~isnan(temp)
        d0(k) = temp;
        k = k+1;
    end
    j = j+1;
end    

d1 = zeros(D, 1); % parity 1st
k = 1; j = 1;
while (k <= D)
    temp = td1(j);
    if ~isnan(temp)
        d1(k) = temp;
        k = k+1;
    end
    j = j+1;
end

d2 = zeros(D, 1); % parity 2nd
k = 1; j = 1;
while (k <= D)
    temp = td2(j);
    if ~isnan(temp)
        d2(k) = temp;
        k = k+1;
    end
    j = j+1;
end    

% Sub-block deinterleaving - per stream
v0 = subBlkDeinterl(d0, colTcSb, rowTcSb, Nd);
v1 = subBlkDeinterl(d1, colTcSb, rowTcSb, Nd);
v2 = subBlkDeinterl2(d2, colTcSb, rowTcSb, Nd);

% Interleave 1, 2, 3 sub-blk streams - for turbo decoding
temp = [v0 v1 v2].';
out = temp(:);
    
end
%-------------------------------------------------------------------------
function out = subBlkDeinterl(in, colTcSb, rowTcSb, Nd)
% Sub-block deinterleaving - for d0 and d1 streams only

% Column permutation pattern
colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, ...
              30, 1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31];

% Find the NAN locations in the input (at the TX) 
%   => recreate the interleaving
%   add the NaN's to input, do the deinterleaving, remove the NaN
buff    = zeros(rowTcSb, colTcSb);
buff(1, 1:Nd) = NaN;
buffPerm = buff(: , colPermPat+1);
intrOut = buffPerm(:);

% intrOut(find(~isnan(intrOut))) = in;
k = 1; j = 1;
while (j <= length(intrOut))
    if ~isnan(intrOut(j))
        intrOut(j) = in(k);
        k = k+1;
    end
    j = j+1;
end

% For 1 and 2nd streams only - deinterleave
inpMat = reshape(intrOut, rowTcSb, colTcSb); 
permInpMat = inpMat(:, colPermPat+1);
temp = permInpMat.';
temp = temp(:);

%   Exclude the null bits
out = temp(Nd+1:end);

end
%-------------------------------------------------------------------------
function out = subBlkDeinterl2(in, colTcSb, rowTcSb, Nd)
% Sub-block interleaving - for d2 stream only

colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, ...
              30, 1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31];
pi = zeros(colTcSb*rowTcSb, 1);
for i = 1 : length(pi)
    pi(i) = mod(colPermPat(floor((i-1)/rowTcSb)+1) + ...
                colTcSb*(mod(i-1, rowTcSb)) + 1, colTcSb*rowTcSb) + 1;
end

% Find the NAN locations in the input (at the TX) 
%   => recreate the interleaving
%   add the NaN's to input, do the deinterleaving, remove the NaN
buff  = zeros(colTcSb, rowTcSb);
buff(1:Nd, 1) = NaN;
buffCol = buff(:);
intrOut = buffCol(pi);

% intrOut(find(~isnan(intrOut))) = in;
k = 1; j = 1;
while (j <= length(intrOut))
    if ~isnan(intrOut(j))
        intrOut(j) = in(k);
        k = k+1;
    end
    j = j+1;
end

% Deinterleave - for 3rd stream only 
outT = zeros(rowTcSb*colTcSb,1);
outT(pi) = intrOut;
out = outT(Nd+1:end);

end

%-------------------------------------------------------------------------
function v = subBlkInterl(d, colTcSb, rowTcSb, Nd)
% Sub-block interleaving - for d0 and d1 streams only

colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30,...
              1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31];

% For 1 and 2nd streams only
y = [NaN*ones(Nd, 1); d];       % null (NaN) filling
inpMat = reshape(y, colTcSb, rowTcSb).';
permInpMat = inpMat(:, colPermPat+1);
v = permInpMat(:);

end
%-------------------------------------------------------------------------
function v = subBlkInterl2(d, colTcSb, rowTcSb, Nd)
% Sub-block interleaving - for d2 stream only

colPermPat = [0, 16, 8, 24, 4, 20, 12, 28, 2, 18, 10, 26, 6, 22, 14, 30,...
              1, 17, 9, 25, 5, 21, 13, 29, 3, 19, 11, 27, 7, 23, 15, 31];
pi = zeros(colTcSb*rowTcSb, 1);
for i = 1 : length(pi)
    pi(i) = mod(colPermPat(floor((i-1)/rowTcSb)+1) + ...
                colTcSb*(mod(i-1, rowTcSb)) + 1, colTcSb*rowTcSb) + 1;
end

% For 3rd stream only
y = [NaN*ones(Nd, 1); d];       % null (NaN) filling
inpMat = reshape(y, colTcSb, rowTcSb).';
ytemp = inpMat.';
y = ytemp(:);
v = y(pi);

end
