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
    axis image;
    set(gca, 'xtick', []);
    set(gca, 'ytick', []);
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
    close(handles.output);

% hObject    handle to CancelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in SetWeightBtn.
function SetWeightBtn_Callback(hObject, eventdata, handles)
WeightsArr=str2double(handles.WeightsTable.Data(:,1));

neighborHood = getappdata(handles.output, 'NeighborHood');

neighborhoodsMatr = [
                [0 0];
                [0 1];
                [1 0];
                [1 1];
                ];
neighborhoodType = find(ismember(neighborHood == neighborhoodsMatr, [1 1], 'rows'));

error = false;
neighborsCount=0;
switch neighborhoodType
    case 1
        neighborsCount=8;
        if any(isnan(WeightsArr(1:8)))
            error = true;
        end

    case 2
        neighborsCount=4;
        if any(isnan(WeightsArr(1:4)))
            error = true;
        end

    case 3
        neighborsCount=6;
        if any(isnan(WeightsArr(1:6)))
            error = true;
        end

    case 4
        neighborsCount=3;
        if any(isnan(WeightsArr(1:3)))
            error = true;
        end

end
if isnan(WeightsArr(neighborsCount + 1))
    error = true;
end

if error
    errordlg('Недопустимый формат весов ячеек.', 'Ошибки ввода:');
else
    CellularAutomat.GetSetWeights(WeightsArr(1:neighborsCount+1));
    msgbox('Веса ячеек успешно заданы.');
    close(handles.output);
end

% hObject    handle to SetWeightBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
