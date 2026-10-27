function sig = getOFDMPreambleAndPilot_mymodel(sigType, varargin)
% GETOFDMPREAMBLEANDPILOT: Return either the preamble OFDM symbols or the
% pilot signals for one frame transmission based on the 802.11a standard.

% Copyright 2014 The MathWorks, Inc.

switch sigType
  case 'Preamble'
    [FFTLen, numGuardBandCarriers] = deal(varargin{:});
    
    % Create short preamble
    shortPreamble = ...
        [ 0    0  1+1i 0  0    0 -1-1i 0  0    0 ...                % [-27: -17]
          1+1i 0  0    0 -1-1i 0  0    0 -1-1i 0 0 0 1+1i 0 0 0 ... % [-16: -1 ]
          0    0  0    0 -1-1i 0  0    0 -1-1i 0 0 0 1+1i 0 0 0 ... % [ 0 :  15]
          1+1i 0  0    0  1+1i 0  0    0  1+1i 0 0 ].';             % [ 16:  27]

    % Create long Preamble
    longPreamble = complex(...
        [ 1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,...
          1,  1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,  1, 0,...
          1, -1, -1,  1,  1, -1,  1, -1,  1, -1, -1, -1, -1, -1,...
          1,  1, -1, -1,  1, -1,  1, -1,  1,  1,  1,  1].', 0);

    % OFDM preamble modulator
    hPreambleOFDMod = comm.OFDMModulator(...
        'FFTLength' ,           FFTLen,...
        'NumGuardBandCarriers', numGuardBandCarriers,...
        'CyclicPrefixLength',   0);

    % Modulate and scale short preamble
    shortPreamblePostOFDM = sqrt(13/6)*step(hPreambleOFDMod, shortPreamble);
    % Modulate long preamble
    longPreamblePostOFDM = step(hPreambleOFDMod, longPreamble);

    % Preamble for one frame
    sig = [shortPreamblePostOFDM; ...
           shortPreamblePostOFDM; ...
           shortPreamblePostOFDM(1:end/2); ...
           longPreamblePostOFDM(end/2+1:end); ...
           longPreamblePostOFDM; ...
           longPreamblePostOFDM];
       
  case 'Pilot'
    numOFDMSym = varargin{1};
    
    % PN sequence for pilot generation
    obj.pPNSeq = comm.PNSequence(...
        'Polynomial',        [1 0 0 0 1 0 0 1],...
        'SamplesPerFrame',   numOFDMSym,...
        'InitialConditions', [1 1 1 1 1 1 1]);

    % Pilot signals for one frame
    pilotForOneCarrier  = step(obj.pPNSeq);
    sig = [repmat(1 - 2 * pilotForOneCarrier, 1, 3), ...
                      2 * pilotForOneCarrier - 1]';
end

end

% [EOF]