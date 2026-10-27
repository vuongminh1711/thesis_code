%% LTE PDSCH processing with Sphere Decoding
%
%   MATLAB counterpart of the Simulink model - LTEPDSCHExample.slx
%   This script uses soft sphere decoding, instead of a MMSE MIMO receiver,
%   to highlight the improved performance attained with spatial
%   multiplexing.
%
%   Limitation: Use Channel Estimation for EPA and EVA channel profiles. 
%               Can use Ideal Channels for flat channels.
%
%   Refer to html/LTEDownlinkExample.html for further link processing
%   details.
%
%   See also LTEDownlinkSim.

%   Copyright 2012-2013 The MathWorks, Inc.

clear functions;
%% User-configurable simulation parameters

chanBW      = 6;          % [1,2,3,4,5,6] maps to [1.4, 3, 5, 10, 15, 20]MHz
contReg     = 2;          % {1,2,3} for >=10MHz, {2,3,4} for <10Mhz
antConfig   = 1;          % [1, 2] maps to {2x2, 4x4}
modType     = 1;          % [1,2,3] maps to ['QPSK','16QAM','64QAM']
chanMdl     = 'EPA 0Hz';  % one of {'Frequency-flat static MIMO', ...
                          %   'EPA 0Hz', 'EPA 5Hz', 'EVA 5Hz', 'EVA 70Hz'}
corrLvl     = 'Low';      % one of {'Low', 'Medium', 'High'}
chEstOn     = 1;          % use channel estimation or ideal channel

snrdB       = 18;         % any value
enPMIfback  = 1;          % enable/disable PMI feedback
cbIdx       = 1;          % 1 or 2 for 2x2, 0-15 for 4x4

showResults  = 1;         % enable/disable received signal scatter plots
showSpectrum = 1;         % enable/disable spectrum plots
numSFrames   = 30;        % simulation length in 1ms subframes

% DO NOT change code in following sections
disp('Simulating LTE PDSCH Spatial Multiplexing with Sphere Decoding')

%% Create the prm structures

% PDSCH and channel parameters
[prmLTEPDSCH, prmMdl] = commExamplePrivate('ltePDSCHprms', 4, chanBW,...
                contReg, modType, chanMdl, antConfig, enPMIfback, cbIdx);
prmMdl.corrLevel = corrLvl;
prmMdl.showResults = showResults;
                                                                     
%% Object constructions
disp('    Creating objects for simulation.');

% Modulator-Demodulator
switch modType
    case 1
        symMap = [0 2 3 1];
        hMod = comm.PSKModulator('ModulationOrder', 4, 'BitInput', ...
            true, 'PhaseOffset', pi/4, 'SymbolMapping', 'Custom', ...
            'CustomSymbolMapping', symMap);        
    case 2
        symMap = [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7];
        hMod = comm.RectangularQAMModulator('BitInput', true, ...
            'NormalizationMethod', 'Average power',...
            'SymbolMapping', 'Custom', 'CustomSymbolMapping', symMap);        
    case 3
        symMap = [47 46 42 43 59 58 62 63 45 44 40 41 57 56 60 61 37 ...
            36 32 33 49 48 52 53 39 38 34 35 51 50 54 55 7 6 2 ...
            3 19 18 22 23 5 4 0 1 17 16 20 21 13 12 8 9 25 24 28 ...
            29 15 14 10 11 27 26 30 31];
        hMod = comm.RectangularQAMModulator('ModulationOrder', 64, ...
            'BitInput', true, 'NormalizationMethod', 'Average power', ...
            'SymbolMapping', 'Custom', 'CustomSymbolMapping', symMap);        
end
constell = constellation(hMod);
numBits = log2(hMod.ModulationOrder);

% MIMO Channel
if strcmp(chanMdl, 'Frequency-flat static MIMO')
    chanObj = comm.MIMOChannel('SampleRate', prmLTEPDSCH.chanSRate, ...
        'MaximumDopplerShift', 0, ...
        'PathDelays', 0,...
        'AveragePathGains', 0,...
        'RandomStream', 'mt19937ar with seed',...
        'Seed', 100,...
        'SpatialCorrelation', false,...
        'NumTransmitAntennas', prmLTEPDSCH.numTx,...
        'NumReceiveAntennas', prmLTEPDSCH.numRx,...
        'PathGainsOutputPort', true);
elseif strcmp(chanMdl, 'EPA 0Hz')
    EPAPathDelays = [0 30 70 90 110 190 410]*1e-9;
    EPAPathGains  = [0 -1 -2 -3 -8 -17.2 -20.8];

    chanObj = comm.MIMOChannel('SampleRate', prmLTEPDSCH.chanSRate, ...
        'MaximumDopplerShift', 0, ...
        'PathDelays', EPAPathDelays,...
        'AveragePathGains', EPAPathGains,...
        'RandomStream', 'mt19937ar with seed',...
        'Seed', 100,...
        'SpatialCorrelation', false,...
        'NumTransmitAntennas', prmLTEPDSCH.numTx,...
        'NumReceiveAntennas', prmLTEPDSCH.numRx,...
        'PathGainsOutputPort', true);
else % LTE profiles
    switch antConfig
        case 1
            antConfigLit = '2x2';
        case 2
            antConfigLit = '4x4';
    end
    chanObj = comm.LTEMIMOChannel('SampleRate', prmLTEPDSCH.chanSRate, ...
        'Profile', chanMdl, ...
        'AntennaConfiguration', antConfigLit, ...
        'CorrelationLevel', 'Low',...
        'RandomStream', 'mt19937ar with seed',...
        'Seed', 100,...
        'PathGainsOutputPort', true);
end

% AWGN channel
hAWGN = comm.AWGNChannel('NoiseMethod', 'Variance', 'VarianceSource',...
    'Input port', 'RandomStream', 'mt19937ar with seed', 'Seed', 67);

% Error meters
hPBer1 = comm.ErrorRate; hPBer2 = comm.ErrorRate;

% Constellation Scopes
if showResults
    hScope1_1 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
        'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ... 
        figposition([5 60 20 25]), 'Name', 'Post OFDM Rx - 1st stream');
    hScope1_2 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
        'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
        figposition([26 60 20 25]), 'Name', 'Post OFDM Rx - 2nd stream');
    
    if (prmLTEPDSCH.numTx==4)
        hScope1_3 = comm.ConstellationDiagram('ReferenceConstellation', ...
            constell, 'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
            figposition([5 24 20 25]), 'Name', 'Post OFDM Rx - 3rd stream');
        hScope1_4 = comm.ConstellationDiagram('ReferenceConstellation', ...
            constell, 'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
            figposition([26 24 20 25]), 'Name', 'Post OFDM Rx - 4th stream');        
    end
end

if showSpectrum
    hSpecAnal = dsp.SpectrumAnalyzer('SampleRate', prmLTEPDSCH.chanSRate, ...
        'SpectrumType', 'Power density', 'PowerUnits', 'dBW', ...
        'RBWSource', 'Property',   'RBW', 15e3, ...
        'FrequencySpan', 'Span and center frequency', ...
        'Span', prmLTEPDSCH.BW, 'CenterFrequency', 0, ...
        'Window', 'Rectangular', 'SpectralAverages', 10, ...
        'Title', 'Transmitted & Received Signal Spectrum', ...
        'YLimits', [-115 -45], 'YLabel', 'PSD', 'ShowLegend', true);
    hSpecAnal.getFramework.Visual.Plotter.UserDefinedChannelNames = ...
        {'Transmitted', 'Received'};    
end

% Soft-Sphere Decoder
bittable = de2bi(symMap, numBits, 'left-msb');
hSphereDec = comm.SphereDecoder('Constellation', constell, ...
                                'BitTable', bittable, 'InitialRadius',...
                                'Infinity', 'DecisionType', 'Soft');

%% LTE PDSCH processing
calcCbIdx = 1;
nS = 0;         % Slot number, one of [0:2:18]

% Simulation loop
tic
for idx = 1:numSFrames  % subframe processing
    disp(['      Processing #' num2str(idx) ' subframe.']);

    %% Transmitter
    % Generate two codewords
    data1 = commExamplePrivate('lteGenPayload', nS, 12345, ...
                                prmLTEPDSCH.numPDSCHBits);
    data2 = commExamplePrivate('lteGenPayload', nS, 98765, ...
                                prmLTEPDSCH.numPDSCHBits);

    % Scramble both codewords 
    scramOut1 = commExamplePrivate('lteScramble', data1, nS, 0, ...
                                   prmLTEPDSCH.maxG);
    scramOut2 = commExamplePrivate('lteScramble', data2, nS, 1, ...
                                   prmLTEPDSCH.maxG);
    
    % Modulate both codewords
    modOut1 = step(hMod, scramOut1);
    modOut2 = step(hMod, scramOut2);
    
    % Map both codewords to layers
    lMapOut = commExamplePrivate('lteSMLayerMapper', modOut1, modOut2, ...
                                 prmLTEPDSCH);

    % Control for codebook feedback
    if prmMdl.enPMIfback
        useCbIdx = calcCbIdx;
    else
        useCbIdx = prmMdl.cbIdx;
    end
    
    % Precoding
    [preOut, Wn] = commExamplePrivate('lteSpatialMuxPrecoder', lMapOut, ...
                                      prmLTEPDSCH, useCbIdx);
    
    % Generate Cell-Specific Reference (CSR) signals
    csr = commExamplePrivate('lteCSRGen', nS, prmLTEPDSCH.numLayers);

    % Resource grid filling
    txGrid = commExamplePrivate('lteREMapper', preOut, csr, nS, ...
                                prmLTEPDSCH);

    % OFDM transmitter
    txSig = commExamplePrivate('lteOFDMTx', txGrid, prmLTEPDSCH.Nrb);

    %% Channel
    % MIMO Fading channel
    [rxFade, chPathG] = step(chanObj, txSig);
    
    % Add AWG noise 
    sigPow = 10*log10(var(rxFade));
    nVar = 10.^(0.1.*(sigPow-snrdB));
    rxSig = step(hAWGN, rxFade, nVar);
    
    % Update Spectrum scope
    if (showSpectrum)
        % Take last OFDM symbol of the subframe, for the first antenna.
        %       - no overhead, CSR, or nulls are present.
        step(hSpecAnal, [txSig(end-prmLTEPDSCH.N+1:end, 1) ...
                         rxSig(end-prmLTEPDSCH.N+1:end, 1)]);
    end
    
    %% Receiver
    % OFDM Rx
    rxGrid = commExamplePrivate('lteOFDMRx', rxSig, prmLTEPDSCH.Nrb,...
                                prmLTEPDSCH.Nrb_sc, prmLTEPDSCH.Ndl_symb);
    
    % Extract data and pilot signals
    [dataRx, csrRx] = commExamplePrivate('lteExtData', rxGrid, nS, ...
                                         prmLTEPDSCH);

    % Plot received data - dataRx
    if showResults && (nS~=0 && nS~=10)
        step(hScope1_1, dataRx(:, 1));
        step(hScope1_2, dataRx(:, 2));
        if prmLTEPDSCH.numRx==4
            step(hScope1_3, dataRx(:, 3));
            step(hScope1_4, dataRx(:, 4));
        end
    end
    
    % MIMO receiver
    if chEstOn
        chEst = commExamplePrivate('lteChanEstimate', ...
                                   prmLTEPDSCH, csrRx, csr);
        hD = commExamplePrivate('lteExtractHData', chEst, nS, prmLTEPDSCH);
    else
        hD = commExamplePrivate('lteIdChEst', ...
                                prmLTEPDSCH, prmMdl, chPathG, nS); %#ok
    end
    if prmMdl.enPMIfback
       % codebook selection for next subframe
       calcCbIdx = commExamplePrivate('lteCbSelect', hD, ...
           prmMdl.enPMIfback, prmLTEPDSCH.numTx, prmLTEPDSCH.numLayers,...
           snrdB);
    end
    
    % SSD receiver
    temp = complex(zeros(size(hD)));
    % Account for precoding
    for i = 1:length(hD)
       temp(i, :, :) = Wn.' * squeeze(hD(i, :, :)); 
    end            
    hD = temp;            
    yRec = step(hSphereDec, dataRx, hD);
        
    % Demap received to two codewords
    if (prmLTEPDSCH.numLayers==2)
        % Works with bits for numLayers=2 only
        [cwOut1, cwOut2] = commExamplePrivate('lteSMLayerDemapper', yRec, ...
                                              prmLTEPDSCH);
    else % numLayers==4
        % Bit-wise layer demapping
        temp = [reshape(yRec(:, 1), numBits, []); 
                reshape(yRec(:, 2), numBits, [])];
        cwOut1 = temp(:);

        temp = [reshape(yRec(:, 3), numBits, []); 
                reshape(yRec(:, 4), numBits, [])];
        cwOut2 = temp(:);        
    end
    
    % Descramble both received codewords
    %   No demodulation, only invert bit polarity
    rxCW1 = commExamplePrivate('lteDescramble', -cwOut1, nS, 0, ...
                               prmLTEPDSCH.maxG);
    rxCW2 = commExamplePrivate('lteDescramble', -cwOut2, nS, 1, ...
                               prmLTEPDSCH.maxG);

    %% Analysis
    % Calculate PDSCH bit errors
    pber1 = step(hPBer1, data1, logical((1-sign(rxCW1))./2));
    pber2 = step(hPBer2, data2, logical((1-sign(rxCW2))./2));
                                               
    % Manage slot number with each subframe processed
    nS = nS + 2;
    if nS > 19
        nS = mod(nS, 20);
    end
end
toc;

%% Results
disp('PBER per Codeword (2x1 matrix)')
errorRates = [pber1(1); pber2(1)];
disp(errorRates)

disp('Errors and bits/blocks processed per codeword')
CW1_errs_processed = pber1(2:3);
CW2_errs_processed = pber2(2:3);
disp(CW1_errs_processed)
disp(CW2_errs_processed)

% [EOF]
