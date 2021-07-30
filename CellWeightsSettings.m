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
   
    jFrame=get(hObject, 'javaframe');
    jicon=javax.swing.ImageIcon('icon.png');
    jFrame.setFigureIcon(jicon);

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
neighborhood = varargin;
neighborhoodType = find(ismember([neighborhood{1}(1) == "1", neighborhood{1}(2) == "NeumannRB"] == neighborhoodsMatr, [1 1], 'rows'));

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
DrawNeighborhood(neighborhoodType);

function DrawNeighborhood(neighborhoodType)

            switch neighborhoodType
                    %8
                case 1
                    %???????????
                    xArrCenter = [0 1 1 0];
                    yArrCenter = [0 0 1 1];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(0.4, 0.5, 'i', 'FontSize', 16);

                    %??
                    xArr1 = [0 1 1 0];
                    yArr1 = [-1 -1 0 0];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(0.4, -0.5, '1', 'FontSize', 16);

                    %???-?????
                    xArr2 = [-1 0 0 -1];
                    yArr2 = [-1 -1 0 0];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(-0.6, -0.5, '2', 'FontSize', 16);

                    %?????
                    xArr3 = [-1 0 0 -1];
                    yArr3 = [0 0 1 1];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(-0.6, 0.5, '3', 'FontSize', 16);

                    %??????-?????
                    xArr4 = [-1 0 0 -1];
                    yArr4 = [1 1 2 2];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(-0.6, 1.5, '4', 'FontSize', 16);

                    %?????
                    xArr5 = [0 1 1 0];
                    yArr5 = [1 1 2 2];

                    patch(xArr5, yArr5, [1 1 1]);
                    text(0.4, 1.5, '5', 'FontSize', 16);

                    %??????-??????
                    xArr6 = [1 2 2 1];
                    yArr6 = [1 1 2 2];

                    patch(xArr6, yArr6, [1 1 1]);
                    text(1.4, 1.5, '6', 'FontSize', 16);

                    %??????
                    xArr7 = [1 2 2 1];
                    yArr7 = [0 0 1 1];

                    patch(xArr7, yArr7, [1 1 1]);
                    text(1.4, 0.5, '7', 'FontSize', 16);

                    %???-??????
                    xArr8 = [1 2 2 1];
                    yArr8 = [-1 -1 0 0];

                    patch(xArr8, yArr8, [1 1 1]);
                    text(1.4, -0.5, '8', 'FontSize', 16);

                    %4
                case 2
                    %???????????
                    xArrCenter = [0 1 1 0];
                    yArrCenter = [0 0 1 1];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(0.4, 0.5, 'i', 'FontSize', 16);

                    %?????
                    xArr1 = [0 1 1 0];
                    yArr1 = [-1 -1 0 0];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(0.4, -0.5, '1', 'FontSize', 16);

                    %?????
                    xArr2 = [-1 0 0 -1];
                    yArr2 = [0 0 1 1];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(-0.6, 0.5, '2', 'FontSize', 16);

                    %??????
                    xArr3 = [0 1 1 0];
                    yArr3 = [1 1 2 2];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(0.4, 1.5, '3', 'FontSize', 16);

                    %??????
                    xArr4 = [1 2 2 1];
                    yArr4 = [0 0 1 1];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(1.4, 0.5, '4', 'FontSize', 16);

                    %6
                case 3
                    %???????????
                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    xArrCenter = [0 0 + dx 0 + dx 0 0 - dx 0 - dx];
                    yArrCenter = [0 0 + dy 0 + 3 * dy 0 + 4 * dy 0 + 3 * dy 0 + dy];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(-dx / 4, 2 * dy, 'i', 'FontSize', 16);

                    %??? ????
                    xDiff = -(sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr1 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr1 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '1', 'FontSize', 16);

                    %????
                    xDiff = -2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '2', 'FontSize', 16);

                    %???? ????
                    xDiff = -(sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr3 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr3 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '3', 'FontSize', 16);

                    %???? ?????
                    xDiff = (sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr4 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr4 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '4', 'FontSize', 16);

                    %?????
                    xDiff = 2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr5 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr5 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr5, yArr5, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '5', 'FontSize', 16);

                    %??? ?????
                    xDiff = (sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr6 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr6 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr6, yArr6, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '6', 'FontSize', 16);

                    %3
                case 4
                    %???????????
                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    xArrCenter = [0 0 + dx 0 + dx 0 0 - dx 0 - dx];
                    yArrCenter = [0 0 + dy 0 + 3 * dy 0 + 4 * dy 0 + 3 * dy 0 + dy];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(-dx / 4, 2 * dy, 'i', 'FontSize', 16);

                    %??? ????
                    xDiff = -(sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr1 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr1 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '1', 'FontSize', 16);

                    %???? ????
                    xDiff = -(sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '2', 'FontSize', 16);

                    %?????
                    xDiff = 2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '3', 'FontSize', 16);

            end

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

neighborhood = getappdata(handles.output, 'Neighborhood');

neighborhoodsMatr = [
                [0 0];
                [0 1];
                [1 0];
                [1 1];
                ];
neighborhoodType = find(ismember([neighborhood(1) == "HexFieldRB", neighborhood(2)  == "NeumannRB"] == neighborhoodsMatr, [1 1], 'rows'));

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
