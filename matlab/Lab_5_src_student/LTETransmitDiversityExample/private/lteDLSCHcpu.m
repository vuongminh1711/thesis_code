function BER = lteDLSCHcpu(prm, maxErrs, gui)
%Implements the LTE DL-SCH processing with early termination turbo
%decoding.

%   Copyright 2012 The MathWorks, Inc.

%Setup GUI if used
if nargin > 2
    usegui = true;
    buttonObj = gui.buttonObj;
    guiRunCheckPass = @() isequal(get(buttonObj, 'Value'), get(buttonObj, 'Max'));
else
    usegui = false;
end

%Setup message generation random number generator
rspv = {'mrg32k3a', 'NormalTransform', 'Inversion', ...
    'Seed', 10, 'NumStreams', 2};
[s1, s2] = RandStream.create(rspv{:});
oldrs = RandStream.getGlobalStream;
RandStream.setGlobalStream(s2);

% Setup parameters
numCRCbits = 24;

%Define BER loop termination conditions
minFrames = 10;
maxFrames = 1e5;

%Calculated the coded ebNo and variance
NumTails = 2*2*log2(prm.trellis.numStates);
subpacketbits = ((prm.tbLen + numCRCbits)/prm.C);
subpacketTBbits = 3*(subpacketbits+numCRCbits) + NumTails;
encodedbits = subpacketTBbits*prm.C;
R   = prm.tbLen/encodedbits;
noiseVar = single(1./(2*R*10.^(prm.ebNoVec./10)));

% System objects
crcPoly = logical([1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0  1 1 1 1 1 0 1 1]);

frameCRC = comm.CRCGenerator('Polynomial', crcPoly);

% CRC generator - CB level
hCBCRCGen = comm.CRCGenerator('Polynomial', [1 1 zeros(1, 16) 1 1 0 0 0 1 1]);

% Turbo Encoder - CB level
hCBTEnc = comm.TurboEncoder('TrellisStructure', prm.trellis, ...
    'InterleaverIndicesSource',  'Property', 'InterleaverIndices',...
    prm.intrlvrIndices);

hChan = comm.AWGNChannel('NoiseMethod', 'Variance', ...
    'VarianceSource', 'Input Port');

hMod = comm.PSKModulator(4, 'BitInput', true, ...
    'OutputDataType', 'single');

hDemod = comm.PSKDemodulator(4, 'BitOutput', true, ...
    'DecisionMethod', 'Approximate log-likelihood ratio', ...
    'VarianceSource', 'Input port');

hCBTDecCRC = commLTETurboDecoder(...
    'InterleaverIndicesSource',  'Property', 'InterleaverIndices',...
    prm.intrlvrIndices, 'MaximumIterations', prm.maxIter);

frameCRCDet = comm.CRCDetector('Polynomial', crcPoly);

%Initialize variables
tEncCbData = false((prm.Kplus*3+12), prm.C);
decTbData = zeros( (prm.tbLen+numCRCbits)/prm.C, prm.C , 'single');
numEbNo = numel(prm.ebNoVec);
BER = struct('frameCount', zeros(1,numEbNo), 'errors', zeros(1,numEbNo), ...
    'rate', zeros(1,numEbNo), 'runtime', zeros(1,numEbNo), 'lastiter', 0);

for nn = 1:numEbNo,
    disp(['running EbNo = ', num2str(prm.ebNoVec(nn))]);
    errCnt = 0;
    frameCnt = 0;
    ts = tic;
    while ( ((frameCnt < minFrames) || (errCnt < maxErrs) ) && (frameCnt < maxFrames))
        if usegui
            drawnow;
            if ~guiRunCheckPass()
                fprintf('\b***Ended early. Cumulative Runtime : %.2f sec\n', ...
                    sum(BER.runtime) + toc(ts));
                return;
            end
        end
        
        %Generate payload of random message bits
        msg = logical(randi(s1, [0 1], prm.tbLen, 1));
        
        %***********TRANSMIT *************
        %Begin transmitter chain
        %Frame level CRC
        frameAndCRC = step(frameCRC, msg);
        frameAndCRCMtx = reshape(frameAndCRC, prm.Kplus-24, []);
        for cbIdx = 1:prm.C
            % Code-block segmentation
            cbData = frameAndCRCMtx(:,cbIdx);
            
            % Append checksum to each CB
            crcCbData = step(hCBCRCGen, cbData);
            
            % Turbo encode each CB
            tEncCbData(:,cbIdx) = step(hCBTEnc, crcCbData);
        end
        % Rate matching, minus bit selection
        enc = lteCbRateMatchingVec(tEncCbData(:), prm.Kplus);

        %*** MODULATE, CHANNEL, DEMODULATE ***
        modOut = step(hMod, enc);
        chanOut  = step(hChan, modOut, noiseVar(nn));
        demodOut= step(hDemod, chanOut, noiseVar(nn));
        
        %************* RECEIVE **************
        rxCbData = -demodOut;
        % Rate dematching, minus bit selection
        deRMCbData = lteCbRateDematchingVec(rxCbData, prm.Kplus);
        deRMCbData = reshape(deRMCbData, [], prm.C);
 
        % Turbo decode each CB with CRC detection
        %   - uses early decoder termination at the CB level
        for cbIdx=1:prm.C
            decTbData(:,cbIdx) = step(hCBTDecCRC, single(deRMCbData(:,cbIdx)));
        end
        %Packet level CRC
        decoded_msg = step(frameCRCDet, logical(decTbData(:)));
        
        %Compute BER
        errCnt = errCnt + sum(abs(decoded_msg - msg));
        frameCnt = frameCnt + 1;
    end
    
    BER.frameCount(nn) = frameCnt;
    BER.errors(nn) = errCnt;
    BER.rate(nn) = errCnt/(frameCnt*prm.tbLen);
    rt = toc(ts);
    BER.runtime(nn) = rt;
    BER.lastiter = nn;
    if usegui
        set(gui.linehandle, 'XData', prm.ebNoVec(1:nn), 'YData', BER.rate(1:nn));
        updateLTEcpugpuStats(gui.runtime, sum(BER.runtime));
        drawnow;
    end
end

RandStream.setGlobalStream(oldrs);
