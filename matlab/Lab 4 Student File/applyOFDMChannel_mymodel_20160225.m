function rxSig = applyOFDMChannel_mymodel_20160225(txSig, EbN0dB, delay, freqShift, phaseOffset, s)
% APPLYOFDMChannel: Add AWGN, random symbol delay, and frequency and phase
% offsets to the input OFDM signal. Finally white noise is also appended to
% the signal to represent signal recorded data where no signal is present.

% Copyright 2014 The MathWorks, Inc.

% System constants
sampleRate      = s.sampleRate;
FFTLength       = s.FFTLength; 
numDataCarriers = s.numDataCarriers;
CPLength        = s.CPLength;

% Add AWGN
EsN0dB = EbN0dB + 10*log10((numDataCarriers)/FFTLength) ...
                + 10*log10(FFTLength/(FFTLength+CPLength));             
SNR    = EsN0dB - 10*log10((numDataCarriers)/FFTLength); % Power normalization
chOut  = sqrt((FFTLength+CPLength)/numDataCarriers) * awgn(txSig, SNR, 'measured'); 

% Introduce random delay
chOut = [randn(delay, 1); chOut]; 

% Introduce phase and frequency offsets
hPFO = comm.PhaseFrequencyOffset( ...
    'PhaseOffset',     phaseOffset, ...
    'FrequencyOffset', freqShift,...
    'SampleRate',      sampleRate);
chOut = step(hPFO, chOut);

% Append a white noise signal of length 10000 to the input signal
numTailNoiseSamples =  10000;
rxSig = [chOut; randn(numTailNoiseSamples, 1)];
rxSig = rxSig(1:length(txSig));
end

% [EOF]