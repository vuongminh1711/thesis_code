function pber = LTETransmitDiversitySim(chanBW, contReg, numTx, numRx, ...
    modType, chanMdl, maxDopp, pathDelays, pathGains, corrLvl, snrdB, ...
    chanEst, numSFrames, showScopes, showSpectrum)
%LTETRANSMITDIVERSITYSIM LTE Transmit Diversity simulator.
%   LTE Transmit Diversity defined for 2 and 4 Tx antennas.
%   Single codeword transmission for FDD mode, PDSCH processing only.
%   Assumes channel is constant for 2 sub-carriers. 
%
%   PBER = LTETransmitDiversitySim(chanBW, contReg, numTx, numRx, modType, ...
%    chanMdl, maxDopp, pathDelays, pathGains, corrLvl, snrdB, chanEst,...
%    numSFrames, showScopes, showSpectrum)
%   where
%    chanBW       - {1,2,3,4,5,6} maps to [1.4, 3, 5, 10, 15, 20] MHz
%    contReg      - {1,2,3} for >=10MHz, {2,3,4} for <10Mhz
%    numTx        - {2, 4}
%    numRx        - {1, 2, 4}
%    modType      - [1,2,3] maps to ['QPSK','16QAM','64QAM']
%    chanMdl      - one of {'Frequency-flat static', 'User-defined'}
%    maxDopp      - scalar
%    pathDelays   - integer vector of multiples of channel input sample time
%    pathGains    - vector, same length as pathDelays
%    corrLvl      - one of {'Low', 'Medium', 'High'}
%    snrdB        - scalar
%    chanEst      - 1 for channel estimation, 0 for ideal estimates
%    numSFrames   - scalar, length of simulation
%    showScopes   - 1 to enable, 0 to disable
%    showSpectrum - 1 to enable, 0 to disable
%
%   The function uses persistent objects to help speed up the simulations.
%   Multiple runs with different parameter values may require a CLEAR
%   ALL to reinstantiate these objects.
%
%   Example: 10MHz, 16QAM, 2x1 link simulation with user-defined channel
%     clear all;    % clear any prior objects
%     PBER = LTETransmitDiversitySim(4, 2, 2, 1, 2, 'User-defined',...
%               5, [0 5 8]*1e-9, [0 -3 -6], 'Low', 12, 0, 30, 0, 0)
% Updated by D. Tan on 2024-09-11

disp('Simulating LTE Downlink PDSCH with Transmit Diversity')
%% Create the prm structures

% PDSCH and channel parameters
[prmLTEPDSCH, prmMdl] = ltePDSCHprms(2, chanBW, contReg, modType, ...
                                     chanMdl, numTx, numRx);

prmMdl.maxDopp = maxDopp;
prmMdl.pathGains = pathGains;
prmMdl.pathDelays = pathDelays;
prmMdl.corrLevel = corrLvl;
prmMdl.showScopes = showScopes;
                                                                     
%% Object constructions
disp('    Creating objects for simulation.');
switch modType
    case 1
        symMap = [0 2 3 1];
        % D. Tan 2024-09-11
        ModulationOrder = 4;
    case 2
        symMap = [11 10 14 15 9 8 12 13 1 0 4 5 3 2 6 7];
        % D. Tan 2024-09-11
        ModulationOrder = 16;
    case 3
        symMap = [47 46 42 43 59 58 62 63 45 44 40 41 57 56 60 61 37 ...
                  36 32 33 49 48 52 53 39 38 34 35 51 50 54 55 7 6 2 ...
                  3 19 18 22 23 5 4 0 1 17 16 20 21 13 12 8 9 25 24 28 ...
                  29 15 14 10 11 27 26 30 31];
        % D. Tan 2024-09-11
        ModulationOrder = 64;
end

% MIMO channel
if ( strcmp(chanMdl, 'Frequency-flat static') )
    chanObj = comm.MIMOChannel('SampleRate', prmLTEPDSCH.chanSRate, ...
        'MaximumDopplerShift', 0, ...
        'PathDelays', 0,...
        'AveragePathGains', 0,...
        'RandomStream', 'mt19937ar with seed',...
        'Seed', 100,...
        'SpatialCorrelation', false,...
        'NumTransmitAntennas', numTx,...
        'NumReceiveAntennas', numRx,...
        'PathGainsOutputPort', true);
elseif strcmp(chanMdl, 'User-defined')
    
    switch prmMdl.corrLevel
        case 'Low'
            txCorrelationCoeff = 0;
            rxCorrelationCoeff = 0;
        case 'Medium'
            txCorrelationCoeff = 0.3;
            rxCorrelationCoeff = 0.9;
        case 'High'
            txCorrelationCoeff = 0.9;
            rxCorrelationCoeff = 0.9;
    end
    Rt = getCorrelationMatrix(numTx, txCorrelationCoeff);
    Rr = getCorrelationMatrix(numRx, rxCorrelationCoeff);
    
    chanObj = comm.MIMOChannel('SampleRate', prmLTEPDSCH.chanSRate, ...
        'MaximumDopplerShift', prmMdl.maxDopp, ...
        'PathDelays', prmMdl.pathDelays,...
        'AveragePathGains', prmMdl.pathGains,...
        'RandomStream', 'mt19937ar with seed',...
        'Seed', 100,...
        'TransmitCorrelationMatrix', Rt,...
        'ReceiveCorrelationMatrix', Rr,...
        'PathGainsOutputPort', true);
end
%         'PathDelays', prmMdl.pathDelays*(1/prmLTEPDSCH.chanSRate),...

% AWGN channel
nVar = 10.^(0.1.*(-snrdB)); % assume unit sigPower
hAWGN = comm.AWGNChannel('NoiseMethod', 'Signal to noise ratio (SNR)',...
    'SNR', snrdB, 'RandomStream', 'mt19937ar with seed', 'Seed', 67);

% Error meter
hPBer = comm.ErrorRate;

% Constellation Scopes - D. Tan 2024-09-01
if showScopes
    persistent hScope1_1 hScope2; % need to retain figures after run
    constell = qammod(0:ModulationOrder-1,ModulationOrder, UnitAveragePower=true);
    hScope1_1 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
        'YLimits', [-2 2], 'XLimits', [-2 2], 'Position',...
        figposition([5 50 17 30]), 'Name', 'Post OFDM Rx - 1st Rx');
    if (prmLTEPDSCH.numRx>1)
        persistent hScope1_2; %#ok
        hScope1_2 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
            'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
            figposition([5 15 17 30]), 'Name', 'Post OFDM Rx - 2nd Rx');
    end
    if (prmLTEPDSCH.numRx>2)
        persistent hScope1_3; %#ok
        hScope1_3 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
            'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
            figposition([26 50 17 30]), 'Name', 'Post OFDM Rx - 3rd Rx');
    end
    if (prmLTEPDSCH.numRx>3)
        persistent hScope1_4; %#ok
        hScope1_4 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
            'YLimits', [-2 2], 'XLimits', [-2 2], 'Position', ...
            figposition([26 15 17 30]), 'Name', 'Post OFDM Rx - 4th Rx');
    end
    hScope2 = comm.ConstellationDiagram('ReferenceConstellation', constell,...
        'YLimits', [-1.5 1.5], 'XLimits', [-1.5 1.5], 'Position', ...
        figposition([50 32 17 30]), 'Name', 'Post MIMO Rx - combined stream');
end

% Spectrum Scope
if showSpectrum
    persistent hSpecAnal; %#ok, need to retain figures after run
    % D. Tan 2024-09-11 prmLTEPDSCH.chanSRate=15360000
    hSpecAnal = spectrumAnalyzer(SampleRate=prmLTEPDSCH.chanSRate, ...
        SpectrumType='power-density', SpectrumUnits='dBw',...
        RBWSource='property',   RBW=15e3, ...
        FrequencySpan='span-and-center-frequency', ...
        Span=prmLTEPDSCH.BW, CenterFrequency=0, ...
        Method='welch', Window='rectangular', ...
        YLimits=[-115 -45], YLabel='PSD', ...
        Title='Transmitted & Received Signal Spectrum', ...
        ChannelNames={'Transmitted', 'Received'}, ShowLegend=true); %'PowerUnits', 'dBW'

end

%% LTE PDSCH processing
nS = 0; % Slot number, one of [0:2:18]

if chanEst
    disp('        MIMO channel estimation will be used.')
else
    disp('        Ideal channel gains will be used.')
end

%% Simulation loop
for idx = 1:numSFrames  % subframe processing
    disp(['    Processing #' num2str(idx) ' subframe.']); 

    numTx = prmLTEPDSCH.numTx;
    
    %% Generate codeword
    data = lteGenPayload(nS, 0, prmLTEPDSCH.numPDSCHBits); % seed = 0 

    %% Transmitter
    % Scramble codeword (=0)
    scramOut = lteScramble(data, nS, 0, prmLTEPDSCH.maxG);
    
    % Modulate - D. Tan 2024-09-11
    modOut = qammod(uint8(scramOut), ModulationOrder, symMap,...
        InputType='bit', UnitAveragePower=true);
    
    % Map codeword to layers
    % and Transmit Diversity encoding
    preOut = lteTDEncode(modOut, numTx);
        
    % Generate Cell-Specific Reference (CSR) signals
    csr = lteCSRGen(nS, numTx);

    % Resource grid filling
    txGrid = lteREMapper(preOut, csr, nS, prmLTEPDSCH);

    % OFDM transmitter
    txSig = lteOFDMTx(txGrid, prmLTEPDSCH.Nrb);
        
    %% Channel
    % MIMO Fading channel - D. Tan 2024-09-11
    %[rxFade, chPathG] = step(chanObj, txSig);
    [rxFade, chPathG] = chanObj(txSig);
    
    % Add AWG noise - D. Tan 2024-09-11
    % rxSig = step(hAWGN, rxFade);
    rxSig = hAWGN(rxFade);
    
    % Update Spectrum scope
    if (showSpectrum) 
       % Take last OFDM symbol of the subframe, for the first antenna.
        %       - no overhead, CSR, or nulls are present.
        % D. Tan 2024-09-11
        hSpecAnal([txSig(end-prmLTEPDSCH.N+1:end, 1) ...
                   rxSig(end-prmLTEPDSCH.N+1:end, 1)]);
    end

    %% Receiver
    % OFDM Rx
    rxGrid = lteOFDMRx(rxSig, prmLTEPDSCH.Nrb, prmLTEPDSCH.Nrb_sc,...
                       prmLTEPDSCH.Ndl_symb);
    
    % Extract data and pilot signals
    [dataRx, csrRx] = lteExtData(rxGrid, nS, prmLTEPDSCH);

    % Plot received data - dataRx
    if showScopes && (nS~=0 && nS~=10)
        % D. Tan 2024-09-11
        hScope1_1(dataRx(:, 1));
        if (prmLTEPDSCH.numRx>1)
            % D. Tan 2024-09-11
            hScope1_2(dataRx(:, 2));
        end
        if (prmLTEPDSCH.numRx>2)
            % D. Tan 2024-09-11
            hScope1_3(dataRx(:, 3));
        end
        if (prmLTEPDSCH.numRx>3)
            % D. Tan 2024-09-11
            hScope1_4(dataRx(:, 4));
        end
    end
    
    % MIMO channel estimation
    if chanEst % estimate channel
        chEst = lteChanEstimate(prmLTEPDSCH, csrRx, csr);
        hD = lteExtractHData(chEst, nS, prmLTEPDSCH);
    else % use ideal channel - from MIMO object
        hD = lteIdChEst(prmLTEPDSCH, prmMdl, chPathG, nS);
    end

    % Transmit diversity combining - SFBC & SFBC with FSTD
    yRec = lteTDCombine(dataRx, hD, numTx, prmLTEPDSCH.numRx);

    % Plot received MIMO combined data - yRec
    if showScopes && (nS~=0 && nS~=10) 
        % D. Tan 2024-09-11
        hScope2(yRec(:, 1));
    end
        
    % Demodulate - D. Tan 2024-09-11
    demodOut = qamdemod(yRec, ModulationOrder, symMap,...
            OutputType='approxllr', OutputDataType='logical', ...
            UnitAveragePower=true,  NoiseVariance=nVar);
            %PlotConstellation=showScopes);
    
    % Descramble both received codewords
    rxCW = lteDescramble(demodOut, nS, 0, prmLTEPDSCH.maxG);

    %% Analysis
    % Calculate PDSCH bit errors - D. Tan 2024-09-11
    pber = hPBer(data, logical((1-sign(rxCW))./2));
                                               
    % Manage slot number with each subframe processed
    nS = nS + 2;
    if nS > 19
        nS = mod(nS, 20);
    end
end

end

%--------------------------------------------------------------------------
function R = getCorrelationMatrix(NumAntennas, r)
    switch NumAntennas
        case 1
            R = 1;
        case 2
            R = [1 r; r 1];
        case 4
            R = [1          r^(1/9)    r^(4/9)    r;       ...
                (r^(1/9))  1          r^(1/9)    r^(4/9); ...
                (r^(4/9))  (r^(1/9))  1          r^(1/9); ...
                r          (r^(4/9))  (r^(1/9))  1];
    end
end

% [EOF]
