function varargout = VisualizationSettings(varargin)
% VISUALIZATIONSETTINGS MATLAB code for VisualizationSettings.fig
%      VISUALIZATIONSETTINGS, by itself, creates a new VISUALIZATIONSETTINGS or raises the existing
%      singleton*.
%
%      H = VISUALIZATIONSETTINGS returns the handle to a new VISUALIZATIONSETTINGS or the handle to
%      the existing singleton*.
%
%      VISUALIZATIONSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALIZATIONSETTINGS.M with the given input arguments.
%
%      VISUALIZATIONSETTINGS('Property','Value',...) creates a new VISUALIZATIONSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualizationSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualizationSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualizationSettings

% Last Modified by GUIDE v2.5 07-Jan-2021 19:23:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VisualizationSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @VisualizationSettings_OutputFcn, ...
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


% --- Executes just before VisualizationSettings is made visible.
function VisualizationSettings_OpeningFcn(hObject, eventdata, handles, varargin)
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
% varargin   command line arguments to VisualizationSettings (see VARARGIN)

% Choose default command line output for VisualizationSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VisualizationSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VisualizationSettings_OutputFcn(hObject, eventdata, handles) 
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

ResultsProcessing.GetSetVisualizationSettings({handles.VisualiseDataMenu.Value, cell2mat(handles.ColorMapMenu.String(handles.ColorMapMenu.Value))});

msgbox('Настройки визуализации поля КА успешно заданы.');
close(handles.output);
% hObject    handle to SetVSettingsBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
