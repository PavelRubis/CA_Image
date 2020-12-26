function varargout = AdvancedCASettings(varargin)
% ADVANCEDCASETTINGS MATLAB code for AdvancedCASettings.fig
%      ADVANCEDCASETTINGS, by itself, creates a new ADVANCEDCASETTINGS or raises the existing
%      singleton*.
%
%      H = ADVANCEDCASETTINGS returns the handle to a new ADVANCEDCASETTINGS or the handle to
%      the existing singleton*.
%
%      ADVANCEDCASETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADVANCEDCASETTINGS.M with the given input arguments.
%
%      ADVANCEDCASETTINGS('Property','Value',...) creates a new ADVANCEDCASETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AdvancedCASettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AdvancedCASettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AdvancedCASettings

% Last Modified by GUIDE v2.5 25-Dec-2020 18:50:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AdvancedCASettings_OpeningFcn, ...
                   'gui_OutputFcn',  @AdvancedCASettings_OutputFcn, ...
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


% --- Executes just before AdvancedCASettings is made visible.
function AdvancedCASettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AdvancedCASettings (see VARARGIN)

% Choose default command line output for AdvancedCASettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AdvancedCASettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AdvancedCASettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in CancelBtn.
function CancelBtn_Callback(hObject, eventdata, handles)

% hObject    handle to CancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in SetWeightBtn.
function SetWeightBtn_Callback(hObject, eventdata, handles)
if getappdata(handles.output,'NeighborCount')==4
    NeighborWeights=[1 1 1 1 1 1 1 1];
end 
% hObject    handle to SetWeightBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
