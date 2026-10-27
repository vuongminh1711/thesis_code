function data = lteGenPayload(nS, seed, outLenVec)
%LTEGENPAYLOAD Generate the data payload per subframe.
%   Due to the varying overheads the output length of the payload can vary
%   with the slot number, which varies from [0, 19].

%   Copyright 2012 The MathWorks, Inc.

%#codegen

% Extract parameters
outLen = max(outLenVec);

persistent init;
if isempty(init)
    init = 1;
    rng(seed);
end

switch nS
    case {0}
        outLen = outLenVec(1);
    case {2, 4, 6, 8, 12, 14, 16, 18}
        outLen = outLenVec(3);
    case {10}
        outLen = outLenVec(2);
    otherwise
        % Do nothing
end

data = logical(randi([0 1], outLen, 1));

% [EOF]