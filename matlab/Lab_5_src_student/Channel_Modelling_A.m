function  Channel_Modelling_A(chn)
%clear functions and mex in memory
clear functions;
%% common parameters          
FRM=2408;   
maxNumBits=2e6;
EbNo=15;
persistent AWGN;
persistent chanObj;
%% channel specific parameters prmLTE
prmLTE.Mode=1;  % 1 for QPSK or 2 for QAM16 or 3 for QAM64
prmLTE.chanSRate=3.654e6;
snr = EbNo + 10*log10(2*prmLTE.Mode);
noiseVar = 10.^(-snr/10);

switch chn
    case 2
        prmLTE.PathDelays=0*(1/prmLTE.chanSRate);
        prmLTE.PathGains= 0;
        prmLTE.DopplerShift= 0;

    case 4
        prmLTE.PathDelays=0*(1/prmLTE.chanSRate);
        prmLTE.PathGains= 0;
        prmLTE.DopplerShift= 70;

    case 1
        prmLTE.PathDelays= [0 10 20 30 100]*(1/prmLTE.chanSRate);
        prmLTE.PathGains= [0 -3 -6 -8 -172];
        prmLTE.DopplerShift= 0;

    case 3
        prmLTE.PathDelays= [0 10 20 30 100]*(1/prmLTE.chanSRate);
        prmLTE.PathGains= [0 -3 -6 -8 -172];
        prmLTE.DopplerShift= 70;

    otherwise
        prmLTE.PathDelays=0*(1/prmLTE.chanSRate);
        prmLTE.PathGains= 0;
        prmLTE.DopplerShift= 0;
end
                                           
%% Channel model processing
numBits = 0;
while (numBits < maxNumBits)
    % Transmitter
    u  =  randi([0 1], FRM,1);              % Randomly generated input bits
    t1 = Modulator(u, prmLTE.Mode);         % Modulator
    
    % Channel & Add AWG noise
    % Fading channel
    if isempty(chanObj)
        chanObj = comm.MIMOChannel(...
            'SampleRate', prmLTE.chanSRate, ...
            'MaximumDopplerShift', prmLTE.DopplerShift, ...
            'PathDelays', prmLTE.PathDelays,...
            'AveragePathGains', prmLTE.PathGains,...
            'TransmitCorrelationMatrix', eye(1),...
            'ReceiveCorrelationMatrix', eye(1),...
            'PathGainsOutputPort', false,...
            'NormalizePathGains', true,...
            'NormalizeChannelOutputs', true);
    end
    rxFade = step(chanObj, t1);
   
    % AWGN channel
    if isempty(AWGN)
    AWGN  = comm.AWGNChannel('NoiseMethod', 'Variance', ...
        'VarianceSource', 'Input port');
    end
    c0 = step(AWGN, rxFade, noiseVar);
    
   % Visualize channel response and constellation
    zVisualize_ex01(prmLTE, t1, c0);        

    numBits  = numBits + FRM;   
end

