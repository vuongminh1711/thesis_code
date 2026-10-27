function varargout = LTETransmitDiversityExample(varargin)
%LTETransmitDiversityExample MATLAB code for LTETransmitDiversityExample.fig
%   LTETransmitDiversityExample, by itself, creates a new
%   LTETransmitDiversityExample or raises the existing singleton*.
%
%   H = LTETransmitDiversityExample returns the handle to a new
%   LTETransmitDiversityExample or the handle to the existing singleton*.
%
%   LTETransmitDiversityExample('CALLBACK',hObject,eventData,handles,...)
%   calls the local function named CALLBACK in

%   LTETransmitDiversityExample.M with the given input arguments.
%
%   LTETransmitDiversityExample('Property','Value',...) creates a new
%   LTETransmitDiversityExample or raises the existing singleton*.
%   Starting from the left, property value pairs are applied to the GUI
%   before LTETransmitDiversityExample_OpeningFcn gets called.  An
%   unrecognized property name or invalid value makes property application
%   stop.  All inputs are passed to LTETransmitDiversityExample_OpeningFcn
%   via varargin.
%
%   *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%   instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES.

% Copyright 2012 The MathWorks, Inc.

% Last Modified by GUIDE v2.5 13-Sep-2024 22:16:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LTETransmitDiversityExample_OpeningFcn, ...
                   'gui_OutputFcn',  @LTETransmitDiversityExample_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
                
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before LTETransmitDiversityExample is made visible.
function LTETransmitDiversityExample_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LTETransmitDiversityExample (see VARARGIN)

% Choose default command line output for LTETransmitDiversityExample
handles.output = hObject;
%handles = guidata( hObject );

% Default values
% Parameters
handles.chanBWVal = '10';       % 10MHz
handles.contRegVal = 2;
handles.numTxVal = 2;
handles.numRxVal = 2;
handles.modTypeVal = '16QAM'; 
handles.chanMdlVal = 'User-defined'; 
handles.maxDoppVal = 5;
handles.pathDelaysVal = [0 5 8]*1e-9;
handles.pathGainsVal = [0 -3 -6];
handles.corrLvlVal = 'Low';   
handles.snrdBVal = 20;
handles.numSFramesVal = 30;
handles.chanEstVal = 0;         % off
handles.showScopesVal = 1;      % on
handles.showSpectrumVal = 1;    % on

% Update handles structure
guidata(hObject, handles);
%drawnow

% UIWAIT makes LTETransmitDiversityExample wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = LTETransmitDiversityExample_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in simulate.
function simulate_Callback(hObject, eventdata, handles)
% hObject    handle to simulate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

buttonVal = get(hObject, 'Value');
if(buttonVal == get(hObject, 'Max')), %push it down
    
   chanBW       = handles.chanBWVal;
    switch chanBW
        case '1.3'
            chanBWL = 1;
        case '3'
            chanBWL = 2;
        case '5'
            chanBWL = 3;
        case '10'
            chanBWL = 4;
        case '15'
            chanBWL = 5;
        case '20'
            chanBWL = 6;
    end                
    contReg      = handles.contRegVal;
    numTx        = handles.numTxVal;
    numRx        = handles.numRxVal;    
    modType      = handles.modTypeVal;
    switch modType
        case 'QPSK'
            modTypeL = 1;
        case '16QAM'
            modTypeL = 2;
        case '64QAM'
            modTypeL = 3;
    end
    chanMdl      = handles.chanMdlVal;
    maxDopp      = handles.maxDoppVal;
    pathDelays   = handles.pathDelaysVal;
    pathGains    = handles.pathGainsVal;
    corrLvl      = handles.corrLvlVal;
    snrdB        = handles.snrdBVal;
    numSFrames   = handles.numSFramesVal;
    chanEst      = handles.chanEstVal;
    showScopes   = handles.showScopesVal;
    showSpectrum = handles.showSpectrumVal;

    % Parameter checking
    if (length(pathDelays) ~= length(pathGains))
        error(['Average path gain vector must be of the same length as',...
               'the path delay vector.']);
    end
    
    % Call the fcn with parameters
    clear functions;
    tic;
    pber = LTETransmitDiversitySim(chanBWL, contReg, numTx, numRx, ...
        modTypeL, chanMdl, maxDopp, pathDelays, pathGains, corrLvl,...
        snrdB, chanEst, numSFrames, showScopes, showSpectrum);
    toc;                
    disp(['BER:              ' num2str(pber(1))]);
    disp(['Number of errors: ' num2str(pber(2))]);
    disp(['Number of bits:   ' num2str(pber(3))]);    
    assignin('base', 'pber', pber); 

    % Update results group
    set(handles.BER, 'String', num2str(pber(1)));
    set(handles.numErrs, 'String', num2str(pber(2)));
    set(handles.numBits, 'String', num2str(pber(3)));
    
    set(hObject, 'Value', get(hObject,'Min'), 'String', 'Simulate Link');
    guidata(hObject, handles);
else % pop it up 
    set(hObject, 'String', 'Simulate Link');
end


% --- Executes on button press in openMCode.
function openMCode_Callback(hObject, eventdata, handles)
% hObject    handle to openMCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

edit LTETransmitDiversitySim.m


% --- Executes on button press in chanEst.
function chanEst_Callback(hObject, eventdata, handles)
% hObject    handle to chanEst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chanEst
% Radio-button
val = get(hObject, 'Value');
handles.chanEstVal = val;
guidata(hObject, handles);


% --- Executes on button press in showScopes.
function showScopes_Callback(hObject, eventdata, handles)
% hObject    handle to showScopes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showScopes
% Radio-button
val = get(hObject, 'Value');
handles.showScopesVal = val;
guidata(hObject, handles);


% --- Executes on button press in showSpectrum.
function showSpectrum_Callback(hObject, eventdata, handles)
% hObject    handle to showSpectrum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSpectrum
% Radio-button
val = get(hObject, 'Value');
handles.showSpectrumVal = val;
guidata(hObject, handles);


% --- Executes on selection change in chanBW.
function chanBW_Callback(hObject, eventdata, handles)
% hObject    handle to chanBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns chanBW contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chanBW

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = contents{get(hObject, 'Value')};

handles.chanBWVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function chanBW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chanBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in numTx.
function numTx_Callback(hObject, eventdata, handles)
% hObject    handle to numTx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns numTx contents as cell array
%        contents{get(hObject,'Value')} returns selected item from numTx

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = str2double(contents{get(hObject, 'Value')});

handles.numTxVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function numTx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numTx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in numRx.
function numRx_Callback(hObject, eventdata, handles)
% hObject    handle to numRx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns numRx contents as cell array
%        contents{get(hObject,'Value')} returns selected item from numRx

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = str2double(contents{get(hObject, 'Value')});

handles.numRxVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function numRx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numRx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in modType.
function modType_Callback(hObject, eventdata, handles)
% hObject    handle to modType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modType

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = contents{get(hObject, 'Value')};

handles.modTypeVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function modType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in corrLvl.
function corrLvl_Callback(hObject, eventdata, handles)
% hObject    handle to corrLvl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns corrLvl contents as cell array
%        contents{get(hObject,'Value')} returns selected item from corrLvl

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = contents{get(hObject, 'Value')};

handles.corrLvlVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function corrLvl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to corrLvl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in chanMdl.
function chanMdl_Callback(hObject, eventdata, handles)
% hObject    handle to chanMdl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns chanMdl contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chanMdl

% Pull-down options
contents = cellstr(get(hObject,'String'));
val = contents{get(hObject, 'Value')};

handles.chanMdlVal = val;
if strcmp(val, 'User-defined')
    set(handles.maxDopp, 'visible', 'on');
    set(handles.pathDelays, 'visible', 'on');
    set(handles.pathGains, 'visible', 'on');
    set(handles.corrLvl, 'visible', 'on')
    set(handles.text7, 'visible', 'on');
    set(handles.text13, 'visible', 'on');
    set(handles.text14, 'visible', 'on');
    set(handles.text15, 'visible', 'on');
else
    set(handles.maxDopp, 'visible', 'off');
    set(handles.pathDelays, 'visible', 'off');
    set(handles.pathGains, 'visible', 'off');
    set(handles.corrLvl, 'visible', 'off')
    set(handles.text7, 'visible', 'off');
    set(handles.text13, 'visible', 'off');
    set(handles.text14, 'visible', 'off');
    set(handles.text15, 'visible', 'off');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function chanMdl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chanMdl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function contReg_Callback(hObject, eventdata, handles)
% hObject    handle to contReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of contReg as text
%        str2double(get(hObject,'String')) returns contents of contReg as a double

% Edit box parameter
val = round(str2double(get(hObject,'String')));

if isnan(val) || (val < 1)
   set(hObject, 'String', handles.contRegVal)
else
   handles.contRegVal = val;
   set(hObject, 'String', val) %reset to deal with round
   guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function contReg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function snrdB_Callback(hObject, eventdata, handles)
% hObject    handle to snrdB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of snrdB as text
%        str2double(get(hObject,'String')) returns contents of snrdB as a double

% Edit box parameter
val = str2double(get(hObject,'String'));

if isnan(val)
   set(hObject, 'String', handles.snrdBVal)
else
   handles.snrdBVal = val;
   set(hObject, 'String', val);
   guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function snrdB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to snrdB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function numSFrames_Callback(hObject, eventdata, handles)
% hObject    handle to numSFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numSFrames as text
%        str2double(get(hObject,'String')) returns contents of numSFrames as a double

% Edit box parameter
val = round(str2double(get(hObject,'String')));

if isnan(val) || (val < 1)
   set(hObject, 'String', handles.numSFramesVal)
else
   handles.numSFramesVal = val;
   set(hObject, 'String', val); %reset to deal with round
   guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function numSFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numSFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxDopp_Callback(hObject, eventdata, handles)
% hObject    handle to maxDopp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxDopp as text
%        str2double(get(hObject,'String')) returns contents of maxDopp as a double

% Edit box parameter
val = str2double(get(hObject,'String'));

if isnan(val) || (val < 0)
   set(hObject, 'String', handles.maxDoppVal)
else
   handles.maxDoppVal = val;
   set(hObject, 'String', val); 
   guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function maxDopp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxDopp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pathDelays_Callback(hObject, eventdata, handles)
% hObject    handle to pathDelays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pathDelays as text
%        str2double(get(hObject,'String')) returns contents of pathDelays as a double

% Edit box parameter - vector
val = str2num(get(hObject,'String'));

handles.pathDelaysVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function pathDelays_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pathDelays (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pathGains_Callback(hObject, eventdata, handles)
% hObject    handle to pathGains (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pathGains as text
%        str2double(get(hObject,'String')) returns contents of pathGains as a double

% Edit box parameter - vector
val = str2num(get(hObject,'String'));

handles.pathGainsVal = val;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function pathGains_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pathGains (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

helpview(fullfile(matlabroot, 'toolbox', 'comm', 'commdemos',...
        'html', 'commlteTransmitDiversity.html'));


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over chanBW.
function chanBW_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to chanBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
