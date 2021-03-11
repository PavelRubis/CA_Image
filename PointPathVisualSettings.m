function varargout = PointPathVisualSettings(varargin)
% POINTPATHVISUALSETTINGS MATLAB code for PointPathVisualSettings.fig
%      POINTPATHVISUALSETTINGS, by itself, creates a new POINTPATHVISUALSETTINGS or raises the existing
%      singleton*.
%
%      H = POINTPATHVISUALSETTINGS returns the handle to a new POINTPATHVISUALSETTINGS or the handle to
%      the existing singleton*.
%
%      POINTPATHVISUALSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POINTPATHVISUALSETTINGS.M with the given input arguments.
%
%      POINTPATHVISUALSETTINGS('Property','Value',...) creates a new POINTPATHVISUALSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PointPathVisualSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PointPathVisualSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PointPathVisualSettings

% Last Modified by GUIDE v2.5 16-Jan-2021 19:56:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PointPathVisualSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @PointPathVisualSettings_OutputFcn, ...
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


% --- Executes just before PointPathVisualSettings is made visible.
function PointPathVisualSettings_OpeningFcn(hObject, eventdata, handles, varargin)
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
% varargin   command line arguments to PointPathVisualSettings (see VARARGIN)

% Choose default command line output for PointPathVisualSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PointPathVisualSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PointPathVisualSettings_OutputFcn(hObject, eventdata, handles) 
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

    
%{
 Re - > Im
    | z | - > ?(z)
    lg | z + 1 | - > ?(z)
    lg | Re + 1 | - > lg | Im + 1 | 
%}
switch handles.VisualiseDataMenu.Value

    case 1
        xLabel = 'Re(z)';
        xFunc = @(z)z(1, :);
        yLabel = 'Im(z)';
        yFunc = @(z)z(2, :);
    case 2
        xLabel = ('\midz\mid');
        xFunc = @(N1PathNewVisual)abs(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));
        yLabel = ('\phi(z)');
        yFunc = @(N1PathNewVisual)angle(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));
    case 3
        xLabel = ('lg\midz+1\mid');
        xFunc = @(N1PathNewVisual)log(abs(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)) + 1)) / log(10);
        yLabel = ('\phi(z)');
        yFunc = @(N1PathNewVisual)angle(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));
    case 4
        xLabel = ('lg\midRe+1\mid');
        xFunc = @(N1PathNewVisual)log(abs(N1PathNewVisual(1, :) + 1)) / log(10);
        yLabel = ('lg\midIm+1\mid');
        yFunc = @(N1PathNewVisual)log(abs(N1PathNewVisual(2, :) + 1)) / log(10);
end

vsOptions = PointPathVisualisationOptions.GetSetPointPathVisualisationOptions;

PointPathVisualisationOptions.GetSetPointPathVisualisationOptions(cell2mat(handles.ColorMapMenu.String(handles.ColorMapMenu.Value)), xFunc, yFunc, xLabel, yLabel, vsOptions.VisualPath);
IteratedPoint.VisualPointCallBack(handles.output.UserData);

msgbox('Настройки визуализации траектории точки успешно заданы.');
close(handles.output);
% hObject    handle to SetVSettingsBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
