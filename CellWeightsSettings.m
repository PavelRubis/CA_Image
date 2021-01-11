function varargout = CellWeightsSettings(varargin)
% CELLWEIGHTSSETTINGS MATLAB code for CellWeightsSettings.fig
%      CELLWEIGHTSSETTINGS, by itself, creates a new CELLWEIGHTSSETTINGS or raises the existing
%      singleton*.
%
%      H = CELLWEIGHTSSETTINGS returns the handle to a new CELLWEIGHTSSETTINGS or the handle to
%      the existing singleton*.
%
%      CELLWEIGHTSSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CELLWEIGHTSSETTINGS.M with the given input arguments.
%
%      CELLWEIGHTSSETTINGS('Property','Value',...) creates a new CELLWEIGHTSSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CellWeightsSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CellWeightsSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CellWeightsSettings

% Last Modified by GUIDE v2.5 07-Jan-2021 18:52:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CellWeightsSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @CellWeightsSettings_OutputFcn, ...
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


% --- Executes just before CellWeightsSettings is made visible.
function CellWeightsSettings_OpeningFcn(hObject, eventdata, handles, varargin)
    axes(handles.axes2);
    axis image;
    set(gca, 'xtick', []);
    set(gca, 'ytick', []);
    
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CellWeightsSettings (see VARARGIN)

% Choose default command line output for CellWeightsSettings

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

tableData = get(handles.WeightsTable, 'data');
neighborhoodsMatr = [
                [0 0];
                [0 1];
                [1 0];
                [1 1];
                ];
neighborhoodType = find(ismember(cell2mat(varargin(2)) == neighborhoodsMatr, [1 1], 'rows'));

switch neighborhoodType
    %4
    case 2

        tableData(5:end - 1, :) = [];
        handles.WeightsTable.RowName(6:end)=[];


    %6
    case 3

        tableData(7:end - 1, :) = [];
        handles.WeightsTable.RowName(8:end)=[];

    %3
    case 4

        tableData(4:end - 1, :) = [];
        handles.WeightsTable.RowName(5:end)=[];

end

set(handles.WeightsTable, 'data',tableData);

title(handles.axes2, strcat('\fontsize{11}', 'Шаблон окрестности:'));
DataFormatting.DrawNeighborhood(neighborhoodType);

% --- Outputs from this function are returned to the command line.
function varargout = CellWeightsSettings_OutputFcn(hObject, eventdata, handles) 
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
