function varargout = CAVisualizationSettings(varargin)
% CAVisualizationSettings MATLAB code for CAVisualizationSettings.fig
%      CAVisualizationSettings, by itself, creates a new CAVisualizationSettings or raises the existing
%      singleton*.
%
%      H = CAVisualizationSettings returns the handle to a new CAVisualizationSettings or the handle to
%      the existing singleton*.
%
%      CAVisualizationSettings('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAVisualizationSettings.M with the given input arguments.
%
%      CAVisualizationSettings('Property','Value',...) creates a new CAVisualizationSettings or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CAVisualizationSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CAVisualizationSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CAVisualizationSettings

% Last Modified by GUIDE v2.5 05-May-2021 07:50:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CAVisualizationSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @CAVisualizationSettings_OutputFcn, ...
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


% --- Executes just before CAVisualizationSettings is made visible.
function CAVisualizationSettings_OpeningFcn(hObject, eventdata, handles, varargin)
    
jFrame=get(hObject, 'javaframe');
jicon=javax.swing.ImageIcon('icon.png');
jFrame.setFigureIcon(jicon);

axes(handles.ColorMapAxes);
clrMap = meshgrid(0:0.001:0.255, 0:0.001:0.255);
pcolor(0:255, 0:255, clrMap);
shading flat
set(gca, 'xtick', []);
set(gca, 'ytick', []);
colormap('jet');
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CAVisualizationSettings (see VARARGIN)

% Choose default command line output for CAVisualizationSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CAVisualizationSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CAVisualizationSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in ColorMapMenu.
function ColorMapMenu_Callback(hObject, eventdata, handles)
clrMap = meshgrid(0:0.001:0.255, 0:0.001:0.255);
pcolor(0:255, 0:255, clrMap);
shading flat
set(gca, 'xtick', []);
set(gca, 'ytick', []);
colormap(cell2mat(hObject.String(hObject.Value)));

% hObject    handle to ColorMapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ColorMapMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ColorMapMenu


% --- Executes during object creation, after setting all properties.
function ColorMapMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColorMapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in VisualiseDataMenu.
function VisualiseDataMenu_Callback(hObject, eventdata, handles)
% hObject    handle to VisualiseDataMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VisualiseDataMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VisualiseDataMenu


% --- Executes during object creation, after setting all properties.
function VisualiseDataMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VisualiseDataMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CancelVSettingsBtn.
function CancelVSettingsBtn_Callback(hObject, eventdata, handles)
close(handles.output);
% hObject    handle to CancelVSettingsBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in SetVSettingsBtn.
function SetVSettingsBtn_Callback(hObject, eventdata, handles)

mainWindowHandles = getappdata(handles.output, 'MainWindowHandles');

caVisualOptions = getappdata(mainWindowHandles.output, 'CAVisOptions');

clrbrTitle = '';
visFunc = [];
switch handles.VisualiseDataMenu.Value
    case 1
        visFunc = @(val,zbase) abs(val);
        paramFunc = @(param)param;
        clrbrTitle = '\fontsize{16}\midz\mid';
    case 2
        visFunc = @(val,zbase) log(abs(val - zbase)) / log(10);
        paramFunc = @(param) log(param) / log(10);
        clrbrTitle = '\fontsize{16}log_{10}(\midz-z^{*}\mid)';
end

caVisualOptions.DataProcessingFunc = visFunc;
caVisualOptions.PrecisionParmsFunc = paramFunc;
caVisualOptions.ColorBarLabel = clrbrTitle;
caVisualOptions.ColorMap = cell2mat(handles.ColorMapMenu.String(handles.ColorMapMenu.Value));

ca = getappdata(mainWindowHandles.output, 'IIteratedObject');
if ~isempty(ca)
    if string(class(ca)) == "CellularAutomat"
        PrepareDataAndAxes(caVisualOptions, ca, mainWindowHandles);
    end
end

msgbox('Настройки визуализации поля КА успешно заданы.');
close(handles.output);
% hObject    handle to SetVSettingsBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function ColorMapAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColorMapAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate ColorMapAxes
