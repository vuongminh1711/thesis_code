classdef (StrictDefaults)FrameFormation < matlab.System
%FrameFormation Frame Formation
%   This System object converts fixed-size or variable-size inputs into
%   fixed-size output frames with a specified length, which is the first
%   output of the step function call. The second output of the step
%   function call is a boolean signal indicating if the first output is a
%   valid frame. 
% 
%   When a frame header is specified in the object, it performs frame
%   synchronization based on the header. Otherwise, it operates in a
%   streaming mode without synchronization.

% Copyright 2014-2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

properties (Nontunable)
    %OutputFrameLength Output frame length
    %   Specify the output frame length as a numeric, real, positive
    %   integer scalar. The default value of this property is 100.
    OutputFrameLength = 100
    %InternalBufferLength Internal buffer length
    %   Specify the internal buffer length as a numeric, real, positive
    %   integer scalar. This property applies when you set the
    %   PerformSynchronization property to false. The default value of this
    %   property is 300.
    InternalBufferLength = 300
    %FrameHeader Frame header
    %   Specify the frame header as a numeric, real or complex column
    %   vector. This property applies when you set the
    %   PerformSynchronization property to true. The default value of this
    %   property is [-1; -1; 1; -1].
    FrameHeader = [-1; -1; 1; -1]
end

properties (Logical, Nontunable)
    %PerformSynchronization Perform synchronization
    %   Set this property to true to perform synchronization based on the
    %   FrameHeader property before outputting the frames. The default
    %   value of this property is true.
    PerformSynchronization = true
end

properties (Constant, Access = private)
    pNumFramesInBuffer = 5  % Buffer length in number of frames, for sync mode only 
end

properties (Access = private, Nontunable)
    pBufferLength       % Buffer length
    pFrameHeader        % Frame header, for sync mode only
    pStepFcnPointer     % Function pointer to perform frame sync or not (streaming)
end

properties (Access = private)
    pOutputBuffer       % Internal buffer
    pSyncDelay          % Sync delay, for sync mode only
    pFrameIdxInBuf      % Frame index for valid outputs in buffer, for sync mode only
    pOutStartIdxInBuf   % Starting index for valid outputs in buffer, for streaming mode only
    pNumValidOutInBuf   % Number of valid outputs (elements) in buffer
end

properties (Access = private, Logical)
    pSyncDelayFound     % Flag to indicate if a sync delay has been found, for sync mode only
end
    
methods    
  function fFormat = FrameFormation(varargin) 
    setProperties(fFormat, nargin, varargin{:});
  end
    
  function set.OutputFrameLength(fFormat, outFrmLen)
    propName = 'OutputFrameLength';
    validateattributes(outFrmLen, {'numeric'}, ...
        {'real','scalar','positive','integer','finite'}, ...
        [class(fFormat) '.' propName], propName);

    fFormat.OutputFrameLength = outFrmLen;
  end
  
  function set.InternalBufferLength(fFormat, bufferLen)
    propName = 'InternalBufferLength';
    validateattributes(bufferLen, {'numeric'}, ...
        {'real','scalar','positive','integer','finite'}, ...
        [class(fFormat) '.' propName], propName);

    fFormat.InternalBufferLength = bufferLen;
  end
  
  function set.FrameHeader(fFormat, frmHeader)
    propName = 'FrameHeader';
    validateattributes(frmHeader, {'numeric'}, ...
        {'column', 'finite'}, ..., ...
        [class(fFormat) '.' propName], propName);
    
    coder.internal.errorIf(isscalar(frmHeader), 'comm:FrameFormation:ScalarHeader');

    fFormat.FrameHeader = frmHeader;
  end
end
    
methods (Access = protected)  
  function validatePropertiesImpl(fFormat)
    coder.internal.errorIf(~fFormat.PerformSynchronization && ...
        (fFormat.InternalBufferLength < fFormat.OutputFrameLength), ...
        'comm:FrameFormation:BufLenLessThanFrmLen');
  end
  
  function validateInputsImpl(fFormat, x)            
    % Only floating-point supported for now. Also note that only 0-by-1
    % empty matrix is allowed, which is considered as a column vector.
    validateattributes(x, {'double','single'}, ... 
        {'2d', 'finite', 'column'}, [class(fFormat) '.' 'Input'], 'Input');
  end
  
  function setupImpl(fFormat, x)
    if fFormat.PerformSynchronization 
        fFormat.pFrameHeader    = cast(fFormat.FrameHeader(:), 'like', x);
        fFormat.pBufferLength   = fFormat.pNumFramesInBuffer * fFormat.OutputFrameLength; % Fixed buffer length
        fFormat.pStepFcnPointer = @stepSyncMode;
    else
        fFormat.pBufferLength   = fFormat.InternalBufferLength;
        fFormat.pStepFcnPointer = @stepStreamingMode;
    end
    
    % Set up internal buffer
    fFormat.pOutputBuffer = zeros(fFormat.pBufferLength, 1, 'like', x);
  end
  
  function resetImpl(fFormat)
    % Initialize internal buffer and related properties  
    fFormat.pOutputBuffer = zeros(fFormat.pBufferLength, 1, 'like', fFormat.pOutputBuffer);
        
    fFormat.pNumValidOutInBuf = 0;
    
    if fFormat.PerformSynchronization
        fFormat.pFrameIdxInBuf    = 0;
        fFormat.pSyncDelayFound   = false;
        fFormat.pSyncDelay        = 0;
    else
        fFormat.pOutStartIdxInBuf = 0;
    end
  end

  function [y, validFrm] = stepImpl(fFormat, x)
    coder.extrinsic('num2str');
    if length(x) > (fFormat.pBufferLength+fFormat.OutputFrameLength-fFormat.pNumValidOutInBuf)
        coder.internal.warning('comm:FrameFormation:BufferOverflow', ...
            num2str(length(x)-(fFormat.pBufferLength+fFormat.OutputFrameLength-fFormat.pNumValidOutInBuf)));
    end
      
    [y, validFrm] = fFormat.pStepFcnPointer(fFormat, x);
  end      
  
  function flag = isInactivePropertyImpl(fFormat, prop)
    if strcmp(prop, 'InternalBufferLength')
        flag = fFormat.PerformSynchronization;
    elseif strcmp(prop, 'FrameHeader')
        flag = ~fFormat.PerformSynchronization;
    else
        flag = false;
    end
  end
  
  function s = saveObjectImpl(fFormat)    
    s = saveObjectImpl@matlab.System(fFormat);
    if isLocked(fFormat)   
        s.pBufferLength     = fFormat.pBufferLength;
        s.pFrameHeader      = fFormat.pFrameHeader;
        s.pStepFcnPointer   = fFormat.pStepFcnPointer;
        s.pOutputBuffer     = fFormat.pOutputBuffer;
        s.pSyncDelay        = fFormat.pSyncDelay;
        s.pFrameIdxInBuf    = fFormat.pFrameIdxInBuf;
        s.pOutStartIdxInBuf = fFormat.pOutStartIdxInBuf;
        s.pNumValidOutInBuf = fFormat.pNumValidOutInBuf;
        s.pSyncDelayFound   = fFormat.pSyncDelayFound;
    end
  end
  
  function loadObjectImpl(fFormat, s, wasLocked)
    if wasLocked
        fFormat.pBufferLength     = s.pBufferLength;
        fFormat.pFrameHeader      = s.pFrameHeader;
        fFormat.pStepFcnPointer   = s.pStepFcnPointer;
        fFormat.pOutputBuffer     = s.pOutputBuffer;
        fFormat.pSyncDelay        = s.pSyncDelay;
        fFormat.pFrameIdxInBuf    = s.pFrameIdxInBuf;
        fFormat.pOutStartIdxInBuf = s.pOutStartIdxInBuf;
        fFormat.pNumValidOutInBuf = s.pNumValidOutInBuf;
        fFormat.pSyncDelayFound   = s.pSyncDelayFound;
    end
    loadObjectImpl@matlab.System(fFormat, s);
  end

  function num = getNumOutputsImpl(~)
    num = 2;
  end
  
  % D. Tan 2024-09-20
  % function flag = isInputSizeLockedImpl(~,~)
  %    flag = false;
  % end
  function flag = isInputSizeMutableImpl(~,~)
     flag = true;
  end
  
  % D. Tan 2024-09-20
  % function flag = isInputComplexityLockedImpl(~,~)
  %   flag = true; % Complexity locked for now
  % end
  function flag = isInputComplexityMutableImpl(~,~)
    flag = false;
  end
  
   % D. Tan 2024-09-20
  % function flag = isOutputComplexityLockedImpl(~,~)
  %   flag = true;
  % end
  
  function varargout = isOutputFixedSizeImpl(~)
    varargout = {true, true};
  end
  
  function varargout = getOutputSizeImpl(fFormat)
    % Do some maximum input size checking here because maximum size only
    % exists in Simulink and should be checked only in propagators.
    % D. Tan 2024-09-20
    % inSigMaxDim = propagatedInputSize(fFormat, 1);
    % coder.internal.errorIf((length(inSigMaxDim) ~= 2) || ...
    %     (inSigMaxDim(2) ~= 1), 'comm:FrameFormation:BlkInputNotColumn');

    % Consider throwing out a warning or error when the input is fixed-size
    % and its length is larger than the OutputFrameLength property.
    
    varargout = {[fFormat.OutputFrameLength 1], [1 1]};
  end
  
  function varargout = getOutputDataTypeImpl(fFormat)
    varargout = {propagatedInputDataType(fFormat, 1), 'logical'};
  end
  
  function varargout = isOutputComplexImpl(fFormat)
    varargout = {propagatedInputComplexity(fFormat, 1), false};
  end
  
  function icon = getIconImpl(fFormat)
    if fFormat.PerformSynchronization
        icon = sprintf('Frame\nSynchronizer');
    else
        icon = sprintf('Frame\nFormation');
    end
  end
  
  function varargout = getInputNamesImpl(~)
    varargout = {''};
  end
  
  function varargout = getOutputNamesImpl(~)
    varargout = {'Frame', 'Valid'};
  end
end

methods(Static, Access = protected)
  function header = getHeaderImpl
    header = matlab.system.display.Header('FrameFormation', ...
        'ShowSourceLink', true, ... 
        'Title', 'Frame Formation', 'Text', ...
        ['Generate fixed-size output frames from variable-size or ', ...
         'fixed-size inputs, with or without performing frame ', ...
         'synchronization. The second output is a boolean value ', ...
         'indicating if the first output is a valid frame.']);
  end
    
  function groups = getPropertyGroupsImpl
    params = matlab.system.display.Section(...
        'Title', 'Parameters',...
        'PropertyList', {'OutputFrameLength', 'PerformSynchronization', ...
                         'InternalBufferLength', 'FrameHeader'});
    groups = params;
  end
end

methods(Access = private)
  function setBuffer(fFormat, linearIdx, value)
    fFormat.pOutputBuffer(mod(linearIdx-1, fFormat.pBufferLength)+1, 1) = value;
  end
  
  function value = getBuffer(fFormat, linearIdx)
    value = fFormat.pOutputBuffer(mod(linearIdx-1, fFormat.pBufferLength)+1, 1);    
  end
  
  function [y, validFrm] = stepSyncMode(fFormat, x) 
    outFrmLen   = fFormat.OutputFrameLength;
    bufferLen   = fFormat.pBufferLength;
    frmIdx      = fFormat.pFrameIdxInBuf;
    numValidOut = fFormat.pNumValidOutInBuf;
    headerLen   = length(fFormat.pFrameHeader);
    
    % Cut input as necessary
    inLen = min(length(x), bufferLen + outFrmLen - numValidOut);
    
    % Buffer as much input as possible before outputting the frame
    partialXToFill = max(min(inLen, bufferLen - numValidOut), 0); % Write in this way to give a lower bound for code generation
    setBuffer(fFormat, frmIdx*outFrmLen + numValidOut + (1:partialXToFill), x(1:partialXToFill, 1)); 
    numValidOut = numValidOut + partialXToFill; % Update number of available data
    
    if numValidOut >= (outFrmLen + headerLen - 1) % Enough data to find the header point in current frame
        if ~fFormat.pSyncDelayFound 
            % Normalize header matches so a strong payload peak cannot
            % outweigh a weaker but better-matched header during fading.
            % ponytail: no rejection/tracking; weak headers can still cause false locks.
            samples = getBuffer(fFormat, frmIdx*outFrmLen + (1:outFrmLen+headerLen-1));
            correlation = abs(conv(samples, conj(flipud(fFormat.pFrameHeader)), 'valid'));
            windowEnergy = conv(abs(samples).^2, ones(headerLen,1,'like',real(samples)), 'valid');
            scale = sqrt(windowEnergy * sum(abs(fFormat.pFrameHeader).^2));
            [~, maxIdx] = max(correlation ./ max(scale, eps(class(scale))));
            fFormat.pSyncDelay = maxIdx - 1; % In [0, outFrmLen-1]
            fFormat.pSyncDelayFound = true;
        end
        
        % Get output frame from the buffer and set its validity
        y = getBuffer(fFormat, frmIdx*outFrmLen + fFormat.pSyncDelay + (1:outFrmLen));
        % Valid when the available data is enough to cover one frame from the header point
        validFrm = (numValidOut >= fFormat.pSyncDelay + outFrmLen);
        
        if validFrm
            if (partialXToFill < inLen) % Buffer the rest of the input
                setBuffer(fFormat, frmIdx*outFrmLen + (1:inLen-partialXToFill), x(partialXToFill+1:inLen, 1));
                numValidOut = numValidOut + inLen - partialXToFill; % Update number of available data
            end
            % Reset/update related variables
            fFormat.pSyncDelayFound = false;
            fFormat.pSyncDelay = 0;
            numValidOut = numValidOut - outFrmLen; 
            fFormat.pFrameIdxInBuf = mod(frmIdx+1, fFormat.pNumFramesInBuffer);
        end
    else % Keep buffering and output an invalid frame
        y = getBuffer(fFormat, frmIdx*outFrmLen + (1:outFrmLen));
        validFrm = false;
    end
    
    fFormat.pNumValidOutInBuf = numValidOut;
  end
  
  function [y, validFrm] = stepStreamingMode(fFormat, x)
    outFrmLen   = fFormat.OutputFrameLength;
    bufferLen   = fFormat.pBufferLength;
    startIdx    = fFormat.pOutStartIdxInBuf;
    numValidOut = fFormat.pNumValidOutInBuf;        

    % Cut input as necessary
    inLen = min(length(x), bufferLen + outFrmLen - numValidOut);
    
    if numValidOut >= outFrmLen
        % Available data are already more than a frame: Output a valid
        % frame and then buffer the whole input
        y = getBuffer(fFormat, startIdx+(1:outFrmLen));
        validFrm = true;        
        setBuffer(fFormat, startIdx+numValidOut+(1:inLen), x(1:inLen, 1));
    else
        % Buffer as much input as possible before outputting the frame
        partialXToFill = max(min(inLen, bufferLen - numValidOut), 0); % Write in this way to give a lower bound for code generation
        setBuffer(fFormat, startIdx+numValidOut+(1:partialXToFill), x(1:partialXToFill, 1));
        
        % Get output frame from the buffer and set its validity
        y = getBuffer(fFormat, startIdx+(1:outFrmLen));
        validFrm = (numValidOut+partialXToFill >= outFrmLen);
        
        if partialXToFill < inLen % Buffer the rest of the input
            setBuffer(fFormat, startIdx+(1:inLen-partialXToFill), x(partialXToFill+1:inLen, 1));
        end
    end

    % Update available data and their starting point in buffer
    fFormat.pOutStartIdxInBuf = mod(startIdx + validFrm*outFrmLen, bufferLen);
    fFormat.pNumValidOutInBuf = numValidOut + inLen - validFrm*outFrmLen;
  end
end

end

% [EOF]
