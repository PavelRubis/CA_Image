function varargout = CA(varargin)
% CA MATLAB code for CA.fig
%      CA, by itself, creates a new CA or raises the existing
%      singleton*.
%
%      H = CA returns the handle to a new CA or the handle to
%      the existing singleton*.
%
%      CA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CA.M with the given input arguments.
%
%      CA('Property','Value',...) creates a new CA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CA_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CA_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CA

% Last Modified by GUIDE v2.5 30-Jul-2021 02:16:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CA_OpeningFcn, ...
                   'gui_OutputFcn',  @CA_OutputFcn, ...
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


% --- Executes just before CA is made visible.
function CA_OpeningFcn(hObject, eventdata, handles, varargin)
set(hObject,'units','normalized','outerposition',[0 0 1 1])

jFrame=get(hObject, 'javaframe');
jicon=javax.swing.ImageIcon('icon.png');
jFrame.setFigureIcon(jicon);

xLabel = 'Re(z)';
xFunc = @(z)z(1, :);
yLabel = 'Im(z)';
yFunc = @(z)z(2, :);

pointVisOptions = PointPathVisualisationOptions('jet', xFunc, yFunc, xLabel, yLabel, []);
setappdata(hObject, 'pointVisOptions', pointVisOptions);

caVisualOptions = CAVisualisationOptions('jet',@(val,zbase) log(abs(val - zbase)) / log(10),'\fontsize{16}log_{10}(\midz-z^{*}\mid)');
setappdata(hObject, 'CAVisOptions', caVisualOptions);

saveRes = SaveResults();
setappdata(hObject, 'SaveResults', saveRes);

handles.LambdaMenu.Value=5;

handles.FieldTypeGroup.UserData = 0;
handles.NeighborhoodTemp.UserData = 'NeumannRB';
handles.HexOrientationPanel.UserData = [{@SquareCACell} -1];
handles.BordersTypePanel.UserData=2;

newNeighborhood = NeumannNeighbourHood(handles.BordersTypePanel.UserData);
setappdata(hObject,'Neighborhood',newNeighborhood);
setappdata(hObject, 'DistributionFig',[]);

handles.SaveParamsButton.UserData = 'CA';

axis image;

% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CA (see VARARGIN)

% Choose default command line output for CA
handles.output = hObject;
fieldNames = fieldnames(handles);

for ind=1:length(fieldNames)
    if any(arrayfun(@(prop) string(cell2mat(prop))=="ButtonDownFcn",properties(getfield(handles,fieldNames{ind}))))
        set(getfield(handles,fieldNames{ind}), 'ButtonDownFcn', @CA_cell.showCellInfo);
    end
end

CA_cell.GetOrSetHandles(handles);

% Update handles structure
guidata(hObject, handles);
% if isempty(gcp('nocreate'))
%     parpool;
% end


% UIWAIT makes CA wait for user response (see UIRESUME)
% uiwait(handles.MainWindow);


% --- Outputs from this function are returned to the command line.
function varargout = CA_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in StartButton.
function StartButton_Callback(hObject, eventdata, handles)
%%

SaveParamsButton_Callback(handles.SaveParamsButton, eventdata, handles)

badObjectStatus = getappdata(handles.output, 'badObjectStatus');
if ~isempty(badObjectStatus)
    errordlg(badObjectStatus,'Ошибка:');
    setappdata(handles.output, 'badObjectStatus',[]);
    return;
end

IteratedObject = getappdata(handles.output, 'IIteratedObject');
calcParams = getappdata(handles.output, 'calcParams');
saveRes = getappdata(handles.output, 'SaveResults');
visualOptions = getappdata(handles.output, 'VisOptions');

errStruct = getappdata(handles.output, 'errStruct');

if any([isempty(IteratedObject) isempty(calcParams) isempty(saveRes)])
    errordlg(errStruct.msg,'Ошибка:');
    setappdata(handles.output, 'errStruct',[]);
    setappdata(handles.output, 'IIteratedObject',[]);
    return;
end

oldIteratedObject = IteratedObject;

wb = waitbar(0, 'Выполняется расчет...', 'WindowStyle', 'modal');

switch class(IteratedObject)
    case 'IteratedMatrix'
        IteratedObject = Iteration(IteratedObject, calcParams, wb);
    otherwise
        IteratedObject = BeforeModeling(IteratedObject);
        wbStep = ceil(calcParams.IterCount / 20);

        for iter = 1:calcParams.IterCount
            IteratedObject = Iteration(IteratedObject, calcParams);

            if ~IsContinue(IteratedObject)
                break;
            end

            if mod(iter, wbStep) == 0
                waitbar(iter / calcParams.IterCount, wb, 'Выполняется расчет...', 'WindowStyle', 'modal');
            end

        end
end
delete(wb);

wb = waitbar(0, 'Отрисовка...', 'WindowStyle', 'modal');

axes(handles.CAField);
[res visualOptions graphics] = PrepareDataAndAxes(visualOptions, IteratedObject, handles);

if saveRes.IsSaveData
    waitbar(1, wb, 'Сохранение выходных данных...', 'WindowStyle', 'modal');
    saveRes = SaveModelingResults(saveRes, res, oldIteratedObject, IteratedObject, calcParams, graphics);
end

setappdata(handles.output, 'graphics', graphics);
setappdata(handles.output, 'IIteratedObject', IteratedObject);
setappdata(handles.output, 'VisOptions', visualOptions);
setappdata(handles.output, 'SaveResults',saveRes);
handles.ResetButton.Enable='on';

delete(wb);
return;

% hObject    handle to StartButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function MuReEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MuReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MuReEdit as text
%        str2double(get(hObject,'String')) returns contents of MuReEdit as a double


% --- Executes during object creation, after setting all properties.
function MuReEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MuReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MuImEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MuImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MuImEdit as text
%        str2double(get(hObject,'String')) returns contents of MuImEdit as a double


% --- Executes during object creation, after setting all properties.
function MuImEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MuImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NEdit_Callback(hObject, eventdata, handles)
% hObject    handle to NEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NEdit as text
%        str2double(get(hObject,'String')) returns contents of NEdit as a double


% --- Executes during object creation, after setting all properties.
function NEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function uipanel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function Mu0ReEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Mu0ReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mu0ReEdit as text
%        str2double(get(hObject,'String')) returns contents of Mu0ReEdit as a double


% --- Executes during object creation, after setting all properties.
function Mu0ReEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mu0ReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Mu0ImEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Mu0ImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mu0ImEdit as text
%        str2double(get(hObject,'String')) returns contents of Mu0ImEdit as a double


% --- Executes during object creation, after setting all properties.
function Mu0ImEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mu0ImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on NEdit and none of its controls.
function Edit_KeyPressFcn(hObject, eventdata, handles)
    if(length(eventdata.Character)~=0)       
        if(~any(eventdata.Character == [char(48:57),'.']))
            set(hObject, 'String', '');
        end
    end
% hObject    handle to NEdit (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Save_Callback(~, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SaveJpg_Callback(hObject, eventdata, handles)
% hObject    handle to SaveJpg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SavePng_Callback(hObject, eventdata, handles)
% hObject    handle to SavePng (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SavePdf_Callback(hObject, eventdata, handles)
% hObject    handle to SavePdf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in LambdaMenu.
function LambdaMenu_Callback(hObject, eventdata, handles)
% currCA=getappdata(handles.output,'CurrCA');
% contParms = getappdata(handles.output,'ContParms');
% switch hObject.Value
%     
%     case 1
%         if contParms.SingleOrMultipleCalc
%             currCA.Lambda = @(z_k)Miu0 + sum(z_k);
%         else
%             contParms.Lambda='*(Miu+z)';
%         end
%     case 2
%         if contParms.SingleOrMultipleCalc
%             currCA.Lambda = @(z_k)Miu + Miu0*(abs(sum(z_k-Zbase)/(length(z_k))));
%         else
%             contParms.Lambda='*(Miu+(Miu0*abs(z-(eq))))';
%         end
%     case 3
%         if contParms.SingleOrMultipleCalc
%             currCA.Lambda = @(z_k,n)Miu + Miu0*abs(sum(arrayfun(@(z_n,o)o*z_n ,z_k,n)));
%         else
%             contParms.Lambda='*(Miu+(Miu0*abs(z)))';
%         end
%     case 4
%         if contParms.SingleOrMultipleCalc
%             currCA.Lambda = @(z_k)Miu + Miu0*(sum(z_k-Zbase)/(length(z_k)));
%         else
%             contParms.Lambda='*(Miu+(Miu0*(z-(eq))))';
%         end
%     case 5
%         if contParms.SingleOrMultipleCalc
%             currCA.Lambda = @(z_k)(Miu + Miu0);
%         else
%             contParms.Lambda='*(Miu+Miu0)';
%         end
% end
% 
% setappdata(handles.output,'CurrCA',currCA);
% setappdata(handles.output,'ContParms',contParms);
        
% hObject    handle to LambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LambdaMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LambdaMenu


% --- Executes during object creation, after setting all properties.
function LambdaMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MakeIterButton.
function MakeIterButton_Callback(hObject, eventdata, handles)
% hObject    handle to MakeIterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function Nedit_Callback(hObject, eventdata, handles)
% hObject    handle to Nedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Nedit as text
%        str2double(get(hObject,'String')) returns contents of Nedit as a double


% --- Executes during object creation, after setting all properties.
function Nedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Nedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function UpEdit_Callback(hObject, eventdata, handles)
% hObject    handle to UpEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
str=get(hObject,'String');
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of UpEdit as text
%        str2double(get(hObject,'String')) returns contents of UpEdit as a double


% --- Executes during object creation, after setting all properties.
function UpEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UpEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DownEdit_Callback(hObject, eventdata, handles)
% hObject    handle to DownEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DownEdit as text
%        str2double(get(hObject,'String')) returns contents of DownEdit as a double


% --- Executes during object creation, after setting all properties.
function DownEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DownEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LeftEdit_Callback(hObject, eventdata, handles)
% hObject    handle to LeftEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LeftEdit as text
%        str2double(get(hObject,'String')) returns contents of LeftEdit as a double


% --- Executes during object creation, after setting all properties.
function LeftEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LeftEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function RightEdit_Callback(hObject, eventdata, handles)
% hObject    handle to RightEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RightEdit as text
%        str2double(get(hObject,'String')) returns contents of RightEdit as a double


% --- Executes during object creation, after setting all properties.
function RightEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RightEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Mu0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Mu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mu0Edit as text
%        str2double(get(hObject,'String')) returns contents of Mu0Edit as a double


% --- Executes during object creation, after setting all properties.
function Mu0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MuEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MuEdit as text
%        str2double(get(hObject,'String')) returns contents of MuEdit as a double


% --- Executes during object creation, after setting all properties.
function MuEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit42_Callback(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit42 as text
%        str2double(get(hObject,'String')) returns contents of edit42 as a double


% --- Executes during object creation, after setting all properties.
function edit42_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in StartButton.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to StartButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function IterCountEdit_Callback(hObject, eventdata, handles)
% hObject    handle to IterCountEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IterCountEdit as text
%        str2double(get(hObject,'String')) returns contents of IterCountEdit as a double


% --- Executes during object creation, after setting all properties.
function IterCountEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IterCountEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ResetButton.
function ResetButton_Callback(hObject, eventdata, handles)
axes(handles.CAField);
cla reset;
axis image;
set(gca,'xtick',[]);
set(gca,'ytick',[]);

oldIteratedObject = getappdata(handles.output, 'IIteratedObject');
saveRes = getappdata(handles.output, 'SaveResults');
saveRes.ResultsFilename = '';
setappdata(handles.output, 'SaveResults', saveRes);

setappdata(handles.output, 'IIteratedObject', []);
setappdata(handles.output, 'calcParams', []);


% handles.SaveAllModelParamsB.Enable='off';
% handles.VisualIteratedObjectMenu.Visible='off';
% handles.CellInfoLabel.Visible='off';
% handles.LambdaMenu.Enable='on';
% 
% if string(class(oldIteratedObject)) ~= "IteratedMatrix"
%     
%     if str2double(handles.NFieldEdit.String)==1
%         handles.DistributionTypeMenu.Enable='off';
%         handles.DistributStartEdit.Enable='off';
%         handles.DistributStepEdit.Enable='off';
%         handles.DistributEndEdit.Enable='off';
%         handles.Z0SourcePathButton.Enable='off';
%         handles.ReadZ0SourceButton.Enable='off';
% %         handles.LambdaMenu.Enable='off';
%         handles.MaxPeriodEdit.Enable='on';
%     else
%         handles.DistributionTypeMenu.Enable='on';
%         handles.DistributStartEdit.Enable='on';
%         handles.DistributStepEdit.Enable='on';
%         handles.DistributEndEdit.Enable='on';
%         handles.Z0SourcePathButton.Enable='on';
%         handles.ReadZ0SourceButton.Enable='on';
%         handles.MaxPeriodEdit.Enable='off';
%         handles.SquareFieldRB.Enable = 'on';
%         handles.HexFieldRB.Enable = 'on';
%         handles.GorOrientRB.Enable = 'on';
%         handles.VertOrientRB.Enable = 'on';
%         handles.DefaultCACB.Enable = 'on';
%         handles.CompletedBordersRB.Enable = 'on';
%         handles.DeathLineBordersRB.Enable = 'on';
%         handles.ClosedBordersRB.Enable = 'on';
%         handles.NeumannRB.Enable = 'on';
%         handles.MooreRB.Enable = 'on';
%     end
%     
%     handles.CustomIterFuncCB.Enable = 'on';
%     handles.NFieldEdit.Enable = 'on';
%     handles.ParamRePointsEdit.Enable='off';
%     handles.ParamNameMenu.Enable='off';
%     handles.ParamReDeltaEdit.Enable='off';
%     handles.ParamImDeltaEdit.Enable='off';
%     handles.ParamRePointsEdit.Enable='off';
%     handles.ParamImPointsEdit.Enable='off';
%     handles.DefaultMultiParmCB.Enable='off';
%     
% else
%     handles.NFieldEdit.Enable='off';
%     handles.SquareFieldRB.Enable='off';
%     handles.HexFieldRB.Enable='off';
%     handles.GorOrientRB.Enable='off';
%     handles.VertOrientRB.Enable='off';
%     handles.DefaultCACB.Enable='off';
%     handles.CompletedBordersRB.Enable='off';
%     handles.DeathLineBordersRB.Enable='off';
%     handles.ClosedBordersRB.Enable='off';
%     
%     handles.DistributionTypeMenu.Enable='off';
%     handles.DistributStartEdit.Enable='off';
%     handles.DistributStepEdit.Enable='off';
%     handles.DistributEndEdit.Enable='off';
%     
%     handles.Z0SourcePathButton.Enable='off';
%     handles.ReadZ0SourceButton.Enable='off';
%     
%     handles.MaxPeriodEdit.Enable='on';
%     handles.ParamRePointsEdit.Enable='on';
%     handles.ParamNameMenu.Enable='on';
%     handles.ParamReDeltaEdit.Enable='on';
%     handles.ParamImDeltaEdit.Enable='on';
%     handles.ParamRePointsEdit.Enable='on';
%     handles.ParamImPointsEdit.Enable='on';
%     handles.DefaultMultiParmCB.Enable='on';
%     
% end
% 
% handles.CustomIterFuncCB.Enable='on';
% 
% if handles.CustomIterFuncCB.Value ~= 1
%     handles.UsersBaseImagEdit.Enable = 'off';
%     handles.BaseImagMenu.Enable = 'on';
% else
% %     handles.LambdaMenu.Enable = 'off';
%     handles.BaseImagMenu.Enable = 'off';
%     handles.UsersBaseImagEdit.Enable = 'on';
% end
% 
%     handles.ReadModelingParmsFrmFile.Enable='on';
%     handles.DefaultFuncsCB.Enable='on';
%     
%     handles.z0Edit.Enable='on';
%     handles.MiuEdit.Enable='on';
%     handles.Miu0Edit.Enable='on';
%     handles.DefaultCB.Enable='on';
%     
%     
%     handles.SingleCalcRB.Enable='on';
%     handles.MultipleCalcRB.Enable='on';
%     handles.CASettingsMenuItem.Enable='on';
% hObject    handle to ResetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in StopButton.
function StopButton_Callback(hObject, eventdata, handles)
% hObject    handle to StopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ContinueButton.
function ContinueButton_Callback(hObject, eventdata, handles)
% hObject    handle to ContinueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function SaveResPathEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SaveResPathEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SaveResPathEdit as text
%        str2double(get(hObject,'String')) returns contents of SaveResPathEdit as a double


% --- Executes during object creation, after setting all properties.
function SaveResPathEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaveResPathEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveResPathButton.
function SaveResPathButton_Callback(hObject, eventdata, handles)
saveRes=getappdata(handles.output,'SaveResults');

directory = uigetdir;
if(directory)
    saveRes.ResultsPath = directory;
end
setappdata(handles.output, 'SaveResults', saveRes);

handles.SaveResPathEdit.String=saveRes.ResultsPath;

% hObject    handle to SaveResPathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in SaveCellsCB.
function SaveCellsCB_Callback(hObject, eventdata, handles)
saveRes=getappdata(handles.output,'SaveResults');
if hObject.Value == 1
    
    saveRes.IsSaveData=1;
    
    set(handles.FileTypeMenu,'Enable','on');
else
    saveRes.IsSaveData = 0;
    hObject.Value = 0;
    
    set(handles.FileTypeMenu,'Enable','off');
end
setappdata(handles.output, 'SaveResults', saveRes);
% hObject    handle to SaveCellsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveCellsCB


% --- Executes on button press in SaveFigCB.
function SaveFigCB_Callback(hObject, eventdata, handles)
graphics = getappdata(handles.output, 'graphics');
if isempty(graphics)
    return;
end
h = figure;
set(h, 'units', 'normalized', 'outerposition', [0 0 1 1])
colormap(graphics.Clrmp);
if isvalid(graphics.Clrbr)
    h.CurrentAxes = copyobj([graphics.Axs graphics.Clrbr], h);
else
    h.CurrentAxes = copyobj([graphics.Axs], h);
end
h.Visible = 'on';
% hObject    handle to SaveFigCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveFigCB


% --- Executes on selection change in FileTypeMenu.
function FileTypeMenu_Callback(hObject, eventdata, handles)
saveRes=getappdata(handles.output,'SaveResults');

switch hObject.Value
    case 1
        saveRes.DataFileFormat=1;
    case 2
        saveRes.DataFileFormat=0;
end

setappdata(handles.output, 'SaveResults', saveRes);
% hObject    handle to FileTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FileTypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FileTypeMenu


% --- Executes during object creation, after setting all properties.
function FileTypeMenu_CreateFcn(hObject, eventdata, handles)

% hObject    handle to FileTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FigTypeMenu.
function FigTypeMenu_Callback(hObject, eventdata, handles)
saveRes=getappdata(handles.output,'SaveResults');

switch hObject.Value
    case 1
        saveRes.FigureFileFormat=1;
    case 2
        saveRes.FigureFileFormat=2;
    case 3
        saveRes.FigureFileFormat=3;
end

setappdata(handles.output, 'SaveResults', saveRes);
% hObject    handle to FigTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FigTypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FigTypeMenu


% --- Executes during object creation, after setting all properties.
function FigTypeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FigTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton14.
function radiobutton14_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton14


% --- Executes on button press in radiobutton15.
function radiobutton15_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton15



function edit54_Callback(hObject, eventdata, handles)
% hObject    handle to edit54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit54 as text
%        str2double(get(hObject,'String')) returns contents of edit54 as a double


% --- Executes during object creation, after setting all properties.
function edit54_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit57_Callback(hObject, eventdata, handles)
% hObject    handle to edit57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit57 as text
%        str2double(get(hObject,'String')) returns contents of edit57 as a double


% --- Executes during object creation, after setting all properties.
function edit57_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit58_Callback(hObject, eventdata, handles)
% hObject    handle to edit58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit58 as text
%        str2double(get(hObject,'String')) returns contents of edit58 as a double


% --- Executes during object creation, after setting all properties.
function edit58_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit55_Callback(hObject, eventdata, handles)
% hObject    handle to edit55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit55 as text
%        str2double(get(hObject,'String')) returns contents of edit55 as a double


% --- Executes during object creation, after setting all properties.
function edit55_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit56_Callback(hObject, eventdata, handles)
% hObject    handle to edit56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit56 as text
%        str2double(get(hObject,'String')) returns contents of edit56 as a double


% --- Executes during object creation, after setting all properties.
function edit56_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu10.
function popupmenu10_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu10


% --- Executes during object creation, after setting all properties.
function popupmenu10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit52_Callback(hObject, eventdata, handles)
% hObject    handle to edit52 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit52 as text
%        str2double(get(hObject,'String')) returns contents of edit52 as a double


% --- Executes during object creation, after setting all properties.
function edit52_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit52 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit53_Callback(hObject, eventdata, handles)
% hObject    handle to edit53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit53 as text
%        str2double(get(hObject,'String')) returns contents of edit53 as a double


% --- Executes during object creation, after setting all properties.
function edit53_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit50_Callback(hObject, eventdata, handles)
% hObject    handle to edit50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit50 as text
%        str2double(get(hObject,'String')) returns contents of edit50 as a double


% --- Executes during object creation, after setting all properties.
function edit50_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit51_Callback(hObject, eventdata, handles)
% hObject    handle to edit51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit51 as text
%        str2double(get(hObject,'String')) returns contents of edit51 as a double


% --- Executes during object creation, after setting all properties.
function edit51_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in StartDataSourceMenu.
function StartDataSourceMenu_Callback(hObject, eventdata, handles)


switch hObject.Value
    
    case 2
        handles.StartXBordersPanel.Visible='off';
        handles.StartYBordersPanel.Visible='off';
        handles.StartSourcetext.Visible='on';
        handles.OpenStartFileEdit.Visible='on';
        handles.OpenStartFileButton.Visible='on';
    
    case 1
        handles.StartSourcetext.Visible='off';
        handles.OpenStartFileEdit.Visible='off';
        handles.OpenStartFileButton.Visible='off';
        handles.StartXBordersPanel.Visible='on';
        handles.StartYBordersPanel.Visible='on';
        
    case 3
        
end




% hObject    handle to StartDataSourceMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns StartDataSourceMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from StartDataSourceMenu


% --- Executes during object creation, after setting all properties.
function StartDataSourceMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StartDataSourceMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function OpenStartFileEdit_Callback(hObject, eventdata, handles)
% hObject    handle to OpenStartFileEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OpenStartFileEdit as text
%        str2double(get(hObject,'String')) returns contents of OpenStartFileEdit as a double


% --- Executes during object creation, after setting all properties.
function OpenStartFileEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OpenStartFileEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OpenStartFileButton.
function OpenStartFileButton_Callback(hObject, eventdata, handles)
[SaveParams.StartFile,SaveParams.StartFilePath] = uigetfile;
OpenStartFileEdit.String=SaveParams.StartFilePath;
% hObject    handle to OpenStartFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu14.
function popupmenu14_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu14 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu14


% --- Executes during object creation, after setting all properties.
function popupmenu14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit74_Callback(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit74 as text
%        str2double(get(hObject,'String')) returns contents of edit74 as a double


% --- Executes during object creation, after setting all properties.
function edit74_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton25.
function pushbutton25_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in radiobutton24.
function radiobutton24_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton24


% --- Executes on button press in radiobutton25.
function radiobutton25_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton25



function NFieldEdit_Callback(hObject, eventdata, handles)
% hObject    handle to NFieldEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NFieldEdit as text
%        str2double(get(hObject,'String')) returns contents of NFieldEdit as a double


% --- Executes during object creation, after setting all properties.
function NFieldEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NFieldEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit72_Callback(hObject, eventdata, handles)
% hObject    handle to edit72 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit72 as text
%        str2double(get(hObject,'String')) returns contents of edit72 as a double


% --- Executes during object creation, after setting all properties.
function edit72_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit72 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit73_Callback(hObject, eventdata, handles)
% hObject    handle to edit73 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit73 as text
%        str2double(get(hObject,'String')) returns contents of edit73 as a double


% --- Executes during object creation, after setting all properties.
function edit73_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit73 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit70_Callback(hObject, eventdata, handles)
% hObject    handle to edit70 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit70 as text
%        str2double(get(hObject,'String')) returns contents of edit70 as a double


% --- Executes during object creation, after setting all properties.
function edit70_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit70 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit71_Callback(hObject, eventdata, handles)
% hObject    handle to edit71 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit71 as text
%        str2double(get(hObject,'String')) returns contents of edit71 as a double


% --- Executes during object creation, after setting all properties.
function edit71_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit71 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu12.
function popupmenu12_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu12 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu12


% --- Executes during object creation, after setting all properties.
function popupmenu12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit61_Callback(hObject, eventdata, handles)
% hObject    handle to edit61 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit61 as text
%        str2double(get(hObject,'String')) returns contents of edit61 as a double


% --- Executes during object creation, after setting all properties.
function edit61_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit61 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit62_Callback(hObject, eventdata, handles)
% hObject    handle to edit62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit62 as text
%        str2double(get(hObject,'String')) returns contents of edit62 as a double


% --- Executes during object creation, after setting all properties.
function edit62_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit63_Callback(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit63 as text
%        str2double(get(hObject,'String')) returns contents of edit63 as a double


% --- Executes during object creation, after setting all properties.
function edit63_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit64_Callback(hObject, eventdata, handles)
% hObject    handle to edit64 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit64 as text
%        str2double(get(hObject,'String')) returns contents of edit64 as a double


% --- Executes during object creation, after setting all properties.
function edit64_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit64 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit78_Callback(hObject, eventdata, handles)
% hObject    handle to edit78 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit78 as text
%        str2double(get(hObject,'String')) returns contents of edit78 as a double


% --- Executes during object creation, after setting all properties.
function edit78_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit78 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit79_Callback(hObject, eventdata, handles)
% hObject    handle to edit79 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit79 as text
%        str2double(get(hObject,'String')) returns contents of edit79 as a double


% --- Executes during object creation, after setting all properties.
function edit79_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit79 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit76_Callback(hObject, eventdata, handles)
% hObject    handle to edit76 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit76 as text
%        str2double(get(hObject,'String')) returns contents of edit76 as a double


% --- Executes during object creation, after setting all properties.
function edit76_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit76 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit77_Callback(hObject, eventdata, handles)
% hObject    handle to edit77 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit77 as text
%        str2double(get(hObject,'String')) returns contents of edit77 as a double


% --- Executes during object creation, after setting all properties.
function edit77_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit77 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu16.
function popupmenu16_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu16 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu16


% --- Executes during object creation, after setting all properties.
function popupmenu16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit82_Callback(hObject, eventdata, handles)
% hObject    handle to edit82 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit82 as text
%        str2double(get(hObject,'String')) returns contents of edit82 as a double


% --- Executes during object creation, after setting all properties.
function edit82_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit82 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu17.
function popupmenu17_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu17 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu17


% --- Executes during object creation, after setting all properties.
function popupmenu17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit89_Callback(hObject, eventdata, handles)
% hObject    handle to edit89 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit89 as text
%        str2double(get(hObject,'String')) returns contents of edit89 as a double


% --- Executes during object creation, after setting all properties.
function edit89_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit89 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton26.
function pushbutton26_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3



function edit87_Callback(hObject, eventdata, handles)
% hObject    handle to edit87 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit87 as text
%        str2double(get(hObject,'String')) returns contents of edit87 as a double


% --- Executes during object creation, after setting all properties.
function edit87_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit87 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit88_Callback(hObject, eventdata, handles)
% hObject    handle to edit88 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit88 as text
%        str2double(get(hObject,'String')) returns contents of edit88 as a double


% --- Executes during object creation, after setting all properties.
function edit88_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit88 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit83_Callback(hObject, eventdata, handles)
% hObject    handle to edit83 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit83 as text
%        str2double(get(hObject,'String')) returns contents of edit83 as a double


% --- Executes during object creation, after setting all properties.
function edit83_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit83 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit84_Callback(hObject, eventdata, handles)
% hObject    handle to edit84 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit84 as text
%        str2double(get(hObject,'String')) returns contents of edit84 as a double


% --- Executes during object creation, after setting all properties.
function edit84_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit84 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit90_Callback(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit90 as text
%        str2double(get(hObject,'String')) returns contents of edit90 as a double


% --- Executes during object creation, after setting all properties.
function edit90_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton28.
function pushbutton28_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton29.
function pushbutton29_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit93_Callback(hObject, eventdata, handles)
% hObject    handle to edit93 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit93 as text
%        str2double(get(hObject,'String')) returns contents of edit93 as a double


% --- Executes during object creation, after setting all properties.
function edit93_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit93 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit91_Callback(hObject, eventdata, handles)
% hObject    handle to edit91 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit91 as text
%        str2double(get(hObject,'String')) returns contents of edit91 as a double


% --- Executes during object creation, after setting all properties.
function edit91_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit91 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit92_Callback(hObject, eventdata, handles)
% hObject    handle to edit92 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit92 as text
%        str2double(get(hObject,'String')) returns contents of edit92 as a double


% --- Executes during object creation, after setting all properties.
function edit92_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit92 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton31.
function pushbutton31_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function BorderIm0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to BorderIm0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BorderIm0Edit as text
%        str2double(get(hObject,'String')) returns contents of BorderIm0Edit as a double


% --- Executes during object creation, after setting all properties.
function BorderIm0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BorderIm0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BorderIm1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to BorderIm1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BorderIm1Edit as text
%        str2double(get(hObject,'String')) returns contents of BorderIm1Edit as a double


% --- Executes during object creation, after setting all properties.
function BorderIm1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BorderIm1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BorderRe0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to BorderRe0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BorderRe0Edit as text
%        str2double(get(hObject,'String')) returns contents of BorderRe0Edit as a double


% --- Executes during object creation, after setting all properties.
function BorderRe0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BorderRe0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BorderRe1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to BorderRe1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BorderRe1Edit as text
%        str2double(get(hObject,'String')) returns contents of BorderRe1Edit as a double


% --- Executes during object creation, after setting all properties.
function BorderRe1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BorderRe1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu18.
function popupmenu18_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu18 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu18


% --- Executes during object creation, after setting all properties.
function popupmenu18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton32.
function pushbutton32_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in LambdaMenu.
function popupmenu20_Callback(hObject, eventdata, handles)
% hObject    handle to LambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LambdaMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LambdaMenu


% --- Executes during object creation, after setting all properties.
function popupmenu20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Z0SourcePathEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Z0SourcePathEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Z0SourcePathEdit as text
%        str2double(get(hObject,'String')) returns contents of Z0SourcePathEdit as a double


% --- Executes during object creation, after setting all properties.
function Z0SourcePathEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Z0SourcePathEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Z0SourcePathButton.
function Z0SourcePathButton_Callback(hObject, eventdata, handles)
[file,path] = uigetfile('*.txt');
if ~isequal([file,path],[0,0])
    path=strcat(path,file);
    handles.Z0SourcePathEdit.String=path;
    handles.Z0SourcePathEdit.UserData=1;
else
    handles.Z0SourcePathEdit.UserData=0;
end

% hObject    handle to Z0SourcePathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in ReadZ0SourceButton.
function ReadZ0SourceButton_Callback(hObject, eventdata, handles)


% hObject    handle to ReadZ0SourceButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in CountBaseZButton.
function CountBaseZButton_Callback(hObject, eventdata, handles)

Muerror=false;
if(isempty(regexp(handles.MiuEdit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))
    errordlg('Ошибка. Недопустимое значение параметра Мю.','modal');
else
    
    currCA=getappdata(handles.output,'CurrCA');
    currCA.Miu = str2double(handles.MiuEdit.String);
    
    MiuStr=num2str(currCA.Miu);
    MiuStr=strcat('(',MiuStr);
    MiuStr=strcat(MiuStr,')');
    
    FbaseStr=strrep(func2str(currCA.Base),'c',MiuStr);
    FbaseStr=strrep(FbaseStr,'Miu',MiuStr);
    if ~isempty(strfind(FbaseStr,'(exp'))
        MiuStr=strcat(MiuStr,'*(exp');
        FbaseStr=strrep(FbaseStr,'(exp',MiuStr);
    end
    Fbase=str2func(FbaseStr);
    
    mapz_zero=@(z) abs(Fbase(z)-z);
%     mapz_zero=Fbase;
    z0=-3.5+0.5*i;
    mapz_zero_xy=@(z) mapz_zero(z(1)+i*z(2));
    [zeq,zer]=fminsearch(mapz_zero_xy, [real(z0) imag(z0)],optimset('TolX',1e-9));
    
    currCA.Zbase=complex(zeq(1),zeq(2));
    
    setappdata(handles.output,'CurrCA',currCA);
end
% hObject    handle to CountBaseZButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function BaseZEdit_Callback(hObject, eventdata, handles)
% hObject    handle to BaseZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BaseZEdit as text
%        str2double(get(hObject,'String')) returns contents of BaseZEdit as a double


% --- Executes during object creation, after setting all properties.
function BaseZEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BaseZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveParamsButton.
function SaveParamsButton_Callback(hObject, eventdata, handles)

handles.CellInfoLabel.Visible='off';
modelingTypeParams = hObject.UserData;
calcParams = [];
isObjectExist = true;

switch modelingTypeParams
    case 'Point'

        iteratedObject = getappdata(handles.output, 'IIteratedObject');

        if string(class(iteratedObject)) ~= "IteratedPoint"
            isObjectExist = false;
            [obj] = IteratedPoint();
            [obj] = Initialization(obj, handles);

            if isempty(obj)
                return;
            end

            setappdata(handles.output, 'IIteratedObject', obj);
            visualOptions = getappdata(handles.output, 'pointVisOptions');
            setappdata(handles.output, 'VisOptions', visualOptions);
        end
        [calcParams] = ModelingParamsForPath.ModelingParamsInitialization(handles);
        
        if ~isempty(iteratedObject)
            if ~GetModellingStatus(iteratedObject) && isObjectExist
                setappdata(handles.output, 'badObjectStatus', 'Моделирование c заданной точностью и точностью ниже  завершено.');
                return;
            end
        end

    case 'Matrix'
        [obj] = IteratedMatrix();
        [obj] = Initialization(obj, handles);

        if isempty(obj)
            return;
        end

        setappdata(handles.output, 'IIteratedObject', obj);
        visualOptions = MatrixVisualisationOptions('jet');
        setappdata(handles.output, 'VisOptions', visualOptions);
        [calcParams] = ModelingParamsForPath.ModelingParamsInitialization(handles);

    otherwise
        iteratedObject = getappdata(handles.output, 'IIteratedObject');
        handles.CellInfoLabel.Visible='on';

        if string(class(iteratedObject)) ~= "CellularAutomat"
            [obj] = CellularAutomat();
            obj.Weights = CellularAutomat.GetSetWeights;
            if isempty(obj.Weights)
                obj.Weights = [1 1 1 1 1 1 1 1];
            end
            [obj] = Initialization(obj, handles);

            if isempty(obj)
                return;
            end
            setappdata(handles.output, 'IIteratedObject', obj);
            visualOptions = getappdata(handles.output, 'CAVisOptions');

            setappdata(handles.output, 'VisOptions', visualOptions);
        end
        [calcParams] = ModelingParams.ModelingParamsInitialization(handles);

        if ~isempty(iteratedObject)
            if ~GetModellingStatus(iteratedObject) && isObjectExist
                setappdata(handles.output, 'badObjectStatus', 'Моделирование c заданной точностью и точностью ниже  завершено.');
                return;
            end
        end

        if isempty(getappdata(handles.output, 'badObjectStatus'))
            ca = getappdata(handles.output, 'IIteratedObject');
            fig = figure('Visible','off');
            axes(fig);
            cla reset;
            axis image;
            set(gca,'xtick',[]);
            set(gca,'ytick',[]);
            PrepareDataAndAxes(getappdata(handles.output, 'VisOptions'), ca, handles);
            lastTitle = fig.CurrentAxes.Title.String;
            lastTitle = {'Конфигурация КА на предыдущем этапе расчета Tl=', num2str(length(ca.Cells(1).ZPath) - 1),lastTitle};
            title(fig.CurrentAxes,lastTitle);
            fig.Visible = 'on';
            axes(handles.CAField);
        end
end

if isempty(calcParams)
    setappdata(handles.output, 'calcParams', []);
    return;
end

setappdata(handles.output, 'calcParams', calcParams);

return;


contParms = getappdata(handles.output,'ContParms');
error = false;

Nerror=false;
if contParms.SingleOrMultipleCalc
    Nerror=false;
    if(isempty(regexp(handles.NFieldEdit.String,'^\d+$')) )
        Nerror=true;
        error=true;
        errorStr=strcat(errorStr,'N; ');
    end
end

currCA=getappdata(handles.output,'CurrCA');

if handles.CustomIterFuncCB.Value ~= 1

    ControlParams.GetSetCustomImag(false);

    switch handles.BaseImagMenu.Value

        case 1
            currCA.Base = @(z)(exp(i * z));
            handles.UsersBaseImagEdit.String = '';

            if ~contParms.SingleOrMultipleCalc
                ImageFuncStr = strcat(func2str(@(z)(exp(i * z))), contParms.Lambda);
                contParms.ImageFunc = str2func(ImageFuncStr);
            else

                if str2double(handles.NFieldEdit.String) == 1
                    currCA.Lambda = @(b)(Miu + Miu0);
                end

            end

        case 2
            currCA.Base = @(z)(z^2 + Miu);
            handles.UsersBaseImagEdit.String = '';

            if ~contParms.SingleOrMultipleCalc
                ImageFuncStr = strcat(func2str(@(z)(z^2 + Miu)), contParms.Lambda);
                contParms.ImageFunc = str2func(ImageFuncStr);
            else

                if str2double(handles.NFieldEdit.String) == 1
                    currCA.Lambda = @(b)1;
                end

            end

        case 3 
            currCA.Base = @(z)1;
            handles.UsersBaseImagEdit.String = '';

            if ~contParms.SingleOrMultipleCalc
                ImageFuncStr = strcat(func2str(@(z)1), contParms.Lambda);
                contParms.ImageFunc = str2func(ImageFuncStr);
            else

                if str2double(handles.NFieldEdit.String) == 1
                    currCA.Lambda = @(b)(Miu + Miu0);
                end

            end

    end

else
    userFuncStr = handles.UsersBaseImagEdit.String;

    [userFuncStrFormated, foundedNegbourCount, userFuncError] = DataFormatting.PreUserImagFormatting(userFuncStr,contParms);
    if userFuncError
        error=true;
    else
        neighborhood = [currCA.FieldType currCA.NeighborhoodType];
        neighborhoodsMatr = [
                    [0 0];
                    [0 1];
                    [1 0];
                    [1 1];
                    ];
        neighborhoodType = find(ismember(neighborhood == neighborhoodsMatr, [1 1], 'rows'));
        switch neighborhoodType
        case 1

            if foundedNegbourCount > 8
                error=true;
            end

        case 2

            if foundedNegbourCount > 4
                error = true;
            end

        case 3

            if foundedNegbourCount > 6
                error = true;
            end

        case 4

            if foundedNegbourCount > 3
                error = true;
            end

        end
    end
    
    if error
        errorStr = strcat(errorStr, 'Недопустимый формат пользовательской функции; ');
    else
        funcStr = userFuncStrFormated;
        currCA.Base = str2func(funcStr);

        if ~contParms.SingleOrMultipleCalc
            contParms.ImageFunc = str2func(funcStr);
        else

            if str2double(handles.NFieldEdit.String) == 1
                currCA.Lambda = @(b)1;
            end

        end

        ControlParams.GetSetCustomImag(true);
    end

end

numErrors=[0 0 0];
num=0;
if(isempty(regexp(handles.MiuEdit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))
    if (~isempty(regexp(func2str(currCA.Base),'Miu(?!0)')) || ~isempty(regexp(func2str(currCA.Lambda),'Miu(?!0)'))) && contParms.SingleOrMultipleCalc
        error=true;
        errorStr=strcat(errorStr,'Мю; ');
        numErrors(2)=true;
    end
    
    if ~contParms.SingleOrMultipleCalc
        error=true;
        errorStr=strcat(errorStr,'Мю; ');
        numErrors(2)=true;
    end
end

if(isempty(regexp(handles.Miu0Edit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))
    if (contains(func2str(currCA.Base),'Miu0') || contains(func2str(currCA.Lambda),'Miu0')) && contParms.SingleOrMultipleCalc
        error=true;
        errorStr=strcat(errorStr,'Мю0; ');
        numErrors(3)=true;
    end
    
    if ~contParms.SingleOrMultipleCalc
        error=true;
        errorStr=strcat(errorStr,'Мю0; ');
        numErrors(3)=true;
    end
end

if(isempty(regexp(handles.z0Edit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))
    numErrors(1)=true;
else
    if ~Nerror && handles.NFieldEdit.String=='1' && contParms.SingleOrMultipleCalc
        if isempty(currCA.Cells)
            currCA.Cells=CACell(str2double(handles.z0Edit.String), str2double(handles.z0Edit.String), [0 1 1], [0 0 0], 0, 1);
        end
        contParms.IsReady2Start=true;
    end
end

fileWasRead = getappdata(handles.output,'FileWasRead');
if isempty(currCA.Cells) || (~contParms.IsReady2Start && ~fileWasRead)
    
    if contParms.SingleOrMultipleCalc

        aParam = (handles.DistributStartEdit.String);
        bParam = (handles.DistributStepEdit.String);
        cParam = (handles.DistributEndEdit.String);

        if isempty(aParam) || isempty(bParam) || isempty(cParam)
            error = true;
            regexprep(errorStr, ', $', '. ');
            errorStr = strcat(errorStr, ' Не задана начальная конфигурация: неправильный формат параметров диапазона значений Z0 или точки z0; ');
        else

            switch handles.DistributionTypeMenu.Value
                case 1

                    if (isnan(str2num(aParam)) || isinf(str2num(aParam)) || isnan(str2num(bParam)) || isinf(str2num(bParam)) || isnan(str2num(cParam)) || isinf(str2num(cParam)))
                        error = true;
                        regexprep(errorStr, ', $', '. ');
                        errorStr = strcat(errorStr, ' Не задана начальная конфигурация: неправильный формат параметров равномерного случайного диапазона значений Z0 или точки z0; ');
                    end

                case 2

                    if (str2double(aParam) >= str2double(bParam) || isempty(regexp(aParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(bParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(cParam, '^\d+(\.?)(?(1)\d+|)$')))
                        error = true;
                        regexprep(errorStr, ', $', '. ');
                        errorStr = strcat(errorStr, ' Не задана начальная конфигурация: неправильный формат параметров случайного однородного диапазона значений Z0 или точки z0; ');
                    end

                case 3

                    if (str2double(bParam) <= 0 || isempty(regexp(aParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(bParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(cParam, '^\d+(\.?)(?(1)\d+|)$')))
                        error = true;
                        regexprep(errorStr, ', $', '. ');
                        errorStr = strcat(errorStr, ' Не задана начальная конфигурация: неправильный формат параметров случайного нормального диапазона значений Z0 или точки z0; ');
                    end

            end

        end

        if ~error
            rangeError = false;
            rangeErrorStr = '';

            [currCA] = Initializations.Z0RandRangeInit(str2double(aParam), str2double(bParam), str2double(cParam), str2double(handles.z0Edit.String), handles.DistributionTypeMenu.Value, str2double(handles.NFieldEdit.String), currCA);
        end
%{
         switch handles.DistributionTypeMenu.Value

            case 1

            case 2
                DistributStartStr = (handles.DistributStartEdit.String);
                DistributStepReStr = (handles.DistributStepEdit.String);
                DistributStepImStr = (handles.DistributEndEdit.String);
                DistributIncz0Str = (handles.z0Edit.String);

                if isempty(regexp(DistributIncz0Str, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')) || isempty(regexp(DistributStartStr, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')) || isempty(regexp(DistributStepReStr, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')) || isempty(regexp(DistributStepImStr, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$'))
                    error = true;
                    regexprep(errorStr, ', $', '. ');
                    errorStr = strcat(errorStr, ' Не задана начальная конфигурация: неправильный формат диапазона значений для Z0 или точки z0; ');
                else

                    if ~error
                        DistributStart = str2double(DistributStartStr);
                        DistributStepRe = str2double(DistributStepReStr);
                        DistributStepIm = str2double(DistributStepImStr);
                        DistributIncz0 = str2double(DistributIncz0Str);

                        [currCA] = Initializations.Z0IncRangeInit(DistributStart, DistributStepRe, DistributStepIm, DistributIncz0, str2double(handles.NFieldEdit.String), currCA);

                    end

                end

        end 
%}  
    else
        if isempty(regexp(handles.ParamReDeltaEdit.String,'^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamImDeltaEdit.String,'^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamRePointsEdit.String,'^\d+$')) || isempty(regexp(handles.ParamImPointsEdit.String,'^\d+$'))
            error=true;
            regexprep(errorStr,';$','.');
            errorStr=strcat(errorStr,' Неправильный формат диапазона параметра "окна"; ');
        else
            switch handles.ParamNameMenu.Value
                case 1
                    num=1;
                    CenterPointStr=handles.z0Edit.String;
                    param1=str2double(handles.MiuEdit.String);
                    param2=str2double(handles.Miu0Edit.String);
                case 2
                    num=2;
                    CenterPointStr=handles.MiuEdit.String;
                    param1=str2double(handles.z0Edit.String);
                    param2=str2double(handles.Miu0Edit.String);
                case 3
                    num=3;
                    CenterPointStr=handles.Miu0Edit.String;
                    param1=str2double(handles.z0Edit.String);
                    param2=str2double(handles.MiuEdit.String);
            end
            
            if ~(numErrors(num))
                ReDelta=str2double(handles.ParamReDeltaEdit.String);
                ImDelta=str2double(handles.ParamImDeltaEdit.String);
                ReStep=(ReDelta*2)/str2double(handles.ParamRePointsEdit.String);
                ImStep=(ImDelta*2)/str2double(handles.ParamImPointsEdit.String);
                ReCenter=real(str2double(CenterPointStr));
                ImCenter=imag(str2double(CenterPointStr));
                
                ReRange=(ReCenter-ReDelta):ReStep:(ReCenter+ReDelta);
                ImRange=(ImCenter-ImDelta):ImStep:(ImCenter+ImDelta);
                currCA.N=100000;
            else
                errorStr=strcat(errorStr,'Параметр "окна" мультирасчета; ');
                error=true;
            end
            
            if ~error
                contParms.ReRangeWindow=ReRange;
                contParms.ImRangeWindow=ImRange;
                contParms.WindowCenterValue=complex(ReCenter,ImCenter);
                contParms.SingleParams=[param1 param2];
            end
        end
        
    end
    
end


setappdata(handles.output,'error',error);
setappdata(handles.output,'errorStr',errorStr);

if error
    contParms.IsReady2Start=false;
else
    
    if contParms.SingleOrMultipleCalc
        currCA.N=str2double(handles.NFieldEdit.String);
        if handles.SquareFieldRB.Value==1
            currCA.FieldType=0;
            ResultsProcessing.GetSetFieldOrient(0);
        else
            currCA.FieldType=1;
            ResultsProcessing.GetSetFieldOrient(1);
        end
    
        if handles.GorOrientRB.Value==1
            ResultsProcessing.GetSetCellOrient(2);
        end
        
        if handles.VertOrientRB.Value==1
            ResultsProcessing.GetSetCellOrient(1);
        end
    else
        switch handles.ParamNameMenu.Value
            case 1
                contParms.WindowParamName='z0';
            case 2
                contParms.WindowParamName='Miu';
            case 3
                contParms.WindowParamName='Miu0';
        end
    end
    
    if currCA.N==1
        N1Path = getappdata(handles.output,'N1Path');
        if isempty(N1Path)
            N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
        else
            if complex(N1Path(1,1),N1Path(2,1))~=currCA.Cells(1).z0
                N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
            end
        end
        setappdata(handles.output,'N1Path',N1Path);
    end
    
    currCA.Miu=str2double(handles.MiuEdit.String);
    customImagCheck=isempty(ControlParams.GetSetCustomImag);
    
    if ~customImagCheck
        if ControlParams.GetSetCustomImag==0
            Miu0Str=strcat('(',handles.Miu0Edit.String,')');
            MiuStr=strcat('(',handles.MiuEdit.String,')');
        
            FbaseStr=strrep(func2str(currCA.Base),'Miu0',Miu0Str);
            FbaseStr=strrep(FbaseStr,'Miu',MiuStr);
            FbaseStr=strrep(FbaseStr,'c',MiuStr);
        
            if ~isempty(strfind(FbaseStr,'(exp'))
                MiuStr=strcat(MiuStr,'*(exp');
                FbaseStr=strrep(FbaseStr,'(exp',MiuStr);
            end
            Fbase=str2func(FbaseStr);
        
            mapz_zero=@(z) abs(Fbase(z)-z);
%         mapz_zero=Fbase;
            z0=-3.5+0.5*i;
            mapz_zero_xy=@(z) mapz_zero(z(1)+i*z(2));
            [zeq,zer]=fminsearch(mapz_zero_xy, [real(z0) imag(z0)],optimset('TolX',1e-9));
    
            currCA.Zbase=complex(zeq(1),zeq(2));
        end
    end
    
    currCA.Miu0=str2double(handles.Miu0Edit.String);
    
    setappdata(handles.output,'CurrCA',currCA);
    
    contParms.IsReady2Start=true;
    setappdata(handles.output,'ContParms',contParms);
end
% hObject    handle to SaveParamsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in InterKindMenu.
function InterKindMenu_Callback(hObject, eventdata, handles)
% hObject    handle to InterKindMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns InterKindMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from InterKindMenu


% --- Executes during object creation, after setting all properties.
function InterKindMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InterKindMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in InterButton.
function InterButton_Callback(hObject, eventdata, handles)
% hObject    handle to InterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DefaultCB.
function DefaultCB_Callback(hObject, eventdata, handles)


    handles.z0Edit.String='0+0i';
    handles.MiuEdit.String='1+0i';
    handles.Miu0Edit.String='0.25i+0';
% hObject    handle to DefaultCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultCB


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5



function MiuReEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MiuReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MiuReEdit as text
%        str2double(get(hObject,'String')) returns contents of MiuReEdit as a double


% --- Executes during object creation, after setting all properties.
function MiuReEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MiuReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MiuImEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MiuImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MiuImEdit as text
%        str2double(get(hObject,'String')) returns contents of MiuImEdit as a double


% --- Executes during object creation, after setting all properties.
function MiuImEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MiuImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Miu0ReEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Miu0ReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Miu0ReEdit as text
%        str2double(get(hObject,'String')) returns contents of Miu0ReEdit as a double


% --- Executes during object creation, after setting all properties.
function Miu0ReEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Miu0ReEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Miu0ImEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Miu0ImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Miu0ImEdit as text
%        str2double(get(hObject,'String')) returns contents of Miu0ImEdit as a double


% --- Executes during object creation, after setting all properties.
function Miu0ImEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Miu0ImEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in BaseImagMenu.
function BaseImagMenu_Callback(hObject, eventdata, handles)

if str2double(handles.NFieldEdit.String)==1
%     handles.LambdaMenu.Enable='off';
else
    handles.LambdaMenu.Enable='on';
end

% hObject    handle to BaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BaseImagMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BaseImagMenu


% --- Executes during object creation, after setting all properties.
function BaseImagMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function UsersBaseImagEdit_Callback(hObject, eventdata, handles)
% hObject    handle to UsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of UsersBaseImagEdit as text
%        str2double(get(hObject,'String')) returns contents of UsersBaseImagEdit as a double


% --- Executes during object creation, after setting all properties.
function UsersBaseImagEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in checkbox7.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7


% --- Executes on button press in radiobutton26.
function radiobutton26_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton26


% --- Executes on button press in radiobutton27.
function radiobutton27_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton27


% --- Executes on selection change in InitZ0Menu.
function InitZ0Menu_Callback(hObject, eventdata, handles)
% hObject    handle to InitZ0Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns InitZ0Menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from InitZ0Menu


% --- Executes during object creation, after setting all properties.
function InitZ0Menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InitZ0Menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Z0Edit1_Callback(hObject, eventdata, handles)
% hObject    handle to Z0Edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Z0Edit1 as text
%        str2double(get(hObject,'String')) returns contents of Z0Edit1 as a double


% --- Executes during object creation, after setting all properties.
function Z0Edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Z0Edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Z0Edit2_Callback(hObject, eventdata, handles)
% hObject    handle to Z0Edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Z0Edit2 as text
%        str2double(get(hObject,'String')) returns contents of Z0Edit2 as a double


% --- Executes during object creation, after setting all properties.
function Z0Edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Z0Edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Z0Edit3_Callback(hObject, eventdata, handles)
% hObject    handle to Z0Edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Z0Edit3 as text
%        str2double(get(hObject,'String')) returns contents of Z0Edit3 as a double


% --- Executes during object creation, after setting all properties.
function Z0Edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Z0Edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in BordersTypePanel.
function BordersTypePanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in BordersTypePanel 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch string(get(hObject,'Tag'))
    
    case "DeathLineBordersRB"
        handles.BordersTypePanel.UserData=1;
    
    case "CompletedBordersRB"
        handles.BordersTypePanel.UserData=2;
        
    case "ClosedBordersRB"
        handles.BordersTypePanel.UserData=3;  
end
fakeObject = struct;
fakeObject.Tag = handles.NeighborhoodTemp.UserData;
NeighborhoodTemp_SelectionChangedFcn(fakeObject, eventdata, handles)


% --- Executes when selected object is changed in HexOrientationPanel.
function HexOrientationPanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in HexOrientationPanel 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch string(get(hObject,'Tag'))
    case "VertOrientRB"
        handles.HexOrientationPanel.UserData = [{@HexagonCACell} 1];
    case "GorOrientRB"
        handles.HexOrientationPanel.UserData = [{@HexagonCACell} 0];
    otherwise
        handles.HexOrientationPanel.UserData = [{@SquareCACell} -1];
end


% --- Executes when selected object is changed in FieldTypeGroup.
function FieldTypeGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in FieldTypeGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject,'Tag'),'HexFieldRB')
    handles.VertOrientRB.Value=1;
    handles.FieldTypeGroup.UserData = 1;
    handles.HexOrientationPanel.UserData = [{@HexagonCACell} 1];
else
    handles.GorOrientRB.Value=0;
    handles.VertOrientRB.Value=0;
    handles.FieldTypeGroup.UserData = 0;
    handles.HexOrientationPanel.UserData = [{@SquareCACell} -1];
end


% --- Executes when selected object is changed in CalcGroup.
function CalcGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in CalcGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in DistributionTypeMenu.
function DistributionTypeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to DistributionTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DistributionTypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DistributionTypeMenu


% --- Executes during object creation, after setting all properties.
function DistributionTypeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistributionTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DistributStartEdit_Callback(hObject, eventdata, handles)
% hObject    handle to DistributStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistributStartEdit as text
%        str2double(get(hObject,'String')) returns contents of DistributStartEdit as a double


% --- Executes during object creation, after setting all properties.
function DistributStartEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistributStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DistributStepEdit_Callback(hObject, eventdata, handles)
% hObject    handle to DistributStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistributStepEdit as text
%        str2double(get(hObject,'String')) returns contents of DistributStepEdit as a double


% --- Executes during object creation, after setting all properties.
function DistributStepEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistributStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DistributEndEdit_Callback(hObject, eventdata, handles)
% hObject    handle to DistributEndEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistributEndEdit as text
%        str2double(get(hObject,'String')) returns contents of DistributEndEdit as a double


% --- Executes during object creation, after setting all properties.
function DistributEndEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistributEndEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamStartEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamStartEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamStartEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamStartEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamStepEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamStepEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamStepEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamStepEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamRePointsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamRePointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamRePointsEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamRePointsEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamRePointsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamRePointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in InterKindMenu.
function popupmenu25_Callback(hObject, eventdata, handles)
% hObject    handle to InterKindMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns InterKindMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from InterKindMenu


% --- Executes during object creation, after setting all properties.
function popupmenu25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InterKindMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in InterButton.
function pushbutton39_Callback(hObject, eventdata, handles)
% hObject    handle to InterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function ParamNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamNameEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamNameEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamNameEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit129_Callback(hObject, eventdata, handles)
% hObject    handle to ParamStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamStartEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamStartEdit as a double


% --- Executes during object creation, after setting all properties.
function edit129_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamStartEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit137_Callback(hObject, eventdata, handles)
% hObject    handle to edit137 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit137 as text
%        str2double(get(hObject,'String')) returns contents of edit137 as a double


% --- Executes during object creation, after setting all properties.
function edit137_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit137 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit138_Callback(hObject, eventdata, handles)
% hObject    handle to edit138 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit138 as text
%        str2double(get(hObject,'String')) returns contents of edit138 as a double


% --- Executes during object creation, after setting all properties.
function edit138_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit138 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function FileMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function ConvergValueEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ConvergValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ConvergValueEdit as text
%        str2double(get(hObject,'String')) returns contents of ConvergValueEdit as a double


% --- Executes during object creation, after setting all properties.
function ConvergValueEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ConvergValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function InfValueEdit_Callback(hObject, eventdata, handles)
% hObject    handle to InfValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of InfValueEdit as text
%        str2double(get(hObject,'String')) returns contents of InfValueEdit as a double


% --- Executes during object creation, after setting all properties.
function InfValueEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InfValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MiuEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MiuEdit as text
%        str2double(get(hObject,'String')) returns contents of MiuEdit as a double


% --- Executes during object creation, after setting all properties.
function MiuEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Miu0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Miu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Miu0Edit as text
%        str2double(get(hObject,'String')) returns contents of Miu0Edit as a double


% --- Executes during object creation, after setting all properties.
function Miu0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Miu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SingleParamNameMenu.
function SingleParamNameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SingleParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SingleParamNameMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SingleParamNameMenu


% --- Executes during object creation, after setting all properties.
function SingleParamNameMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SingleParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SingleParamValueEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SingleParamValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SingleParamValueEdit as text
%        str2double(get(hObject,'String')) returns contents of SingleParamValueEdit as a double


% --- Executes during object creation, after setting all properties.
function SingleParamValueEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SingleParamValueEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ParamNameMenu.
function ParamNameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ParamNameMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ParamNameMenu


% --- Executes during object creation, after setting all properties.
function ParamNameMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MaxPeriodEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MaxPeriodEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxPeriodEdit as text
%        str2double(get(hObject,'String')) returns contents of MaxPeriodEdit as a double


% --- Executes during object creation, after setting all properties.
function MaxPeriodEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxPeriodEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function z0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to z0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of z0Edit as text
%        str2double(get(hObject,'String')) returns contents of z0Edit as a double


% --- Executes during object creation, after setting all properties.
function z0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamReDeltaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamReDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamReDeltaEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamReDeltaEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamReDeltaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamReDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamImDeltaEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamImDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamImDeltaEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamImDeltaEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamImDeltaEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamImDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ParamImPointsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ParamImPointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamImPointsEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamImPointsEdit as a double


% --- Executes during object creation, after setting all properties.
function ParamImPointsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamImPointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in DefaultCACB.
function DefaultCACB_Callback(hObject, eventdata, handles)

    handles.SquareFieldRB.Value = 1;
    handles.FieldTypeGroup.UserData = 0;
    handles.NFieldEdit.String = '5';

    handles.GorOrientRB.Value = 0;
    handles.VertOrientRB.Value = 0;
    handles.HexOrientationPanel.UserData = [{@SquareCACell} -1];

    handles.CompletedBordersRB.Value = 1;
    handles.BordersTypePanel.UserData=2;

    handles.NeumannRB.Value = 1;
    newNeighborhood = NeumannNeighbourHood(handles.BordersTypePanel.UserData);
    handles.NeighborhoodTemp.UserData = 'NeumannRB';

    

% hObject    handle to DefaultCACB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultCACB


% --- Executes on button press in DefaultMultiParmCB.
function DefaultMultiParmCB_Callback(hObject, eventdata, handles)
handles.ParamReDeltaEdit.String='5';
handles.ParamRePointsEdit.String='100';
handles.ParamImDeltaEdit.String='5';
handles.ParamImPointsEdit.String='100';
handles.ParamNameMenu.Value=1;
% hObject    handle to DefaultMultiParmCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultMultiParmCB


% --- Executes on button press in DefaultFuncsCB.
function DefaultFuncsCB_Callback(hObject, eventdata, handles)

handles.BaseImagMenu.Value=1;
handles.LambdaMenu.Value=5;
handles.BaseImagMenu.Enable='on';
handles.LambdaMenu.Enable='on';

handles.CustomIterFuncCB.Value = 0;
handles.UsersBaseImagEdit.Enable='off';
handles.UsersBaseImagEdit.String='';

% hObject    handle to DefaultFuncsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultFuncsCB


% --- Executes on button press in DefaultModelParmCB.
function DefaultModelParmCB_Callback(hObject, eventdata, handles)
handles.InfValueEdit.String='15';
handles.ConvergValueEdit.String='5';

if string(handles.SaveParamsButton.UserData) ~= "CA"
    handles.IterCountEdit.String='100';
    handles.MaxPeriodEdit.String='100';
else
    handles.IterCountEdit.String='5';
    handles.MaxPeriodEdit.String='';
end

% hObject    handle to DefaultModelParmCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultModelParmCB


% --- Executes on button press in DefaultSaveParmCB.
function DefaultSaveParmCB_Callback(hObject, eventdata, handles)
ResProc=getappdata(handles.output,'ResProc');
ResProc.IsSaveData=1;
ResProc.isSaveCA=1;
ResProc.isDuplicateFig=1;
ResProc.CellsValuesFileFormat=1;
ResProc.FigureFileFormat=1;

handles.SaveCellsCB.Value=1;
handles.SaveFigCB.Value=1;
handles.FigTypeMenu.Value=1;
handles.FileTypeMenu.Value=1;
handles.FigTypeMenu.Enable='on';
handles.FileTypeMenu.Enable='on';

setappdata(handles.output,'ResProc',ResProc);
% hObject    handle to DefaultSaveParmCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultSaveParmCB


% --- Executes when selected object is changed in NeighborhoodTemp.
function NeighborhoodTemp_SelectionChangedFcn(hObject, eventdata, handles)
switch hObject.Tag
    
    case 'NeumannRB'
        newNeighborhood = NeumannNeighbourHood(handles.BordersTypePanel.UserData);
        handles.NeighborhoodTemp.UserData = 'NeumannRB';
    case 'MooreRB'
        newNeighborhood = MooreNeighbourHood(handles.BordersTypePanel.UserData);
        handles.NeighborhoodTemp.UserData = 'MooreRB';
        
end
setappdata(handles.output,'Neighborhood',newNeighborhood);
% hObject    handle to the selected object in NeighborhoodTemp 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in CustomIterFuncCB.
function CustomIterFuncCB_Callback(hObject, eventdata, handles)

if hObject.Value==1
    handles.BaseImagMenu.Enable='off';
    handles.LambdaMenu.Enable='off';
    
    handles.UsersBaseImagEdit.Enable='on';
else
    handles.BaseImagMenu.Enable='on';
    handles.LambdaMenu.Enable='on';
    
    handles.UsersBaseImagEdit.Enable='off';
    handles.UsersBaseImagEdit.String='';
end
% hObject    handle to CustomIterFuncCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CustomIterFuncCB


% --------------------------------------------------------------------
function CASettingsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CASettingsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SetNeighborWeightMenuItem_Callback(hObject, eventdata, handles)
cellWeightsSettings = CellWeightsSettings([string(handles.FieldTypeGroup.UserData), string(handles.NeighborhoodTemp.UserData)]);

setappdata(cellWeightsSettings, 'Neighborhood', [string(handles.FieldTypeGroup.UserData), string(handles.NeighborhoodTemp.UserData)]);
setappdata(handles.output, 'CellWeightsSettings', cellWeightsSettings);

% hObject    handle to SetNeighborWeightMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function VisualizationSettingsMenuItem_Callback(hObject, eventdata, handles)
visualizationSettings = CAVisualizationSettings;
setappdata(visualizationSettings, 'MainWindowHandles',handles);
% hObject    handle to VisualizationSettingsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function PointPathSettingsMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PointPathSettingsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function PointVisualizationSettingsMenuItem_Callback(hObject, eventdata, handles)
pointPathVisualSettings = PointPathVisualSettings;
setappdata(pointPathVisualSettings, 'MainWindowHandles',handles);
% hObject    handle to PointVisualizationSettingsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function MainWindow_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to MainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%delete(gcp('nocreate'))


% --------------------------------------------------------------------
function HelpMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to HelpMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ShowDistributionBtn.
function ShowDistributionBtn_Callback(hObject, eventdata, handles)

fig = getappdata(handles.output, 'DistributionFig');
if ~isempty(fig)
    if isvalid(fig)
        close(fig);
        setappdata(handles.output, 'DistributionFig',[]);
        return;
    end
end

switch handles.DistributionTypeMenu.Value
 case 1
    setappdata(handles.output, 'DistributionFig',pretty_equation({'$$z(x,y)=z_{0}+a+bx+cy$$'}));
 case 2
    formulaStr = {'$$z(x,y)=z_{0}+a+b \mid x-\frac{N-1}{2} \mid + c \mid y-\frac{N-1}{2} \mid$$'};
    if string(handles.FieldTypeGroup.UserData) == "HexFieldRB"
        formulaStr = {'$$z(x,y)=z_{0}+a+b \mid x-N-1 \mid + c \mid y-N-1 \mid$$'};
    end
    setappdata(handles.output, 'DistributionFig',pretty_equation(formulaStr));
 case 3
    setappdata(handles.output, 'DistributionFig',pretty_equation({'$$z(x,y)=z_{0}+a+(b-a)p_{1}+ic[a+(b-a)p_{2}],$$','$$b>a, Im(a)=Im(b)=Im(c)=0,$$','$$p_{1,2} \in [0;1]$$'}));
 case 4
    setappdata(handles.output, 'DistributionFig',pretty_equation({'$$z(x,y)=z_{0}+c(p_{1}(a,b) + ip_{2}(a,b))$$','$$Re(b)>0, Im(a) = Im(b)= Im(c) = 0,$$','$$p_{1,2}=\frac{1}{b\cdot\sqrt{2\cdot\pi}} \cdot exp(-\frac{(x - a)^{2}}{2\cdot b^{2}})$$'}));
     
end
% hObject    handle to ShowDistributionBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function help_Callback(hObject, eventdata, handles)
winopen('help.pdf');
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function aboutProg_Callback(hObject, eventdata, handles)
about


% --- Executes on button press in pushbutton50.
function pushbutton50_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit156_Callback(hObject, eventdata, handles)
% hObject    handle to edit156 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit156 as text
%        str2double(get(hObject,'String')) returns contents of edit156 as a double


% --- Executes during object creation, after setting all properties.
function edit156_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit156 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox16.
function checkbox16_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox16


% --- Executes on button press in pushbutton46.
function pushbutton46_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton47.
function pushbutton47_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit152_Callback(hObject, eventdata, handles)
% hObject    handle to edit152 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit152 as text
%        str2double(get(hObject,'String')) returns contents of edit152 as a double


% --- Executes during object creation, after setting all properties.
function edit152_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit152 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit153_Callback(hObject, eventdata, handles)
% hObject    handle to edit153 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit153 as text
%        str2double(get(hObject,'String')) returns contents of edit153 as a double


% --- Executes during object creation, after setting all properties.
function edit153_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit153 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit154_Callback(hObject, eventdata, handles)
% hObject    handle to edit154 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit154 as text
%        str2double(get(hObject,'String')) returns contents of edit154 as a double


% --- Executes during object creation, after setting all properties.
function edit154_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit154 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu32.
function popupmenu32_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu32 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu32


% --- Executes during object creation, after setting all properties.
function popupmenu32_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu33.
function popupmenu33_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu33 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu33


% --- Executes during object creation, after setting all properties.
function popupmenu33_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RangeInitStateRB.
function RangeInitStateRB_Callback(hObject, eventdata, handles)
% hObject    handle to RangeInitStateRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RangeInitStateRB


% --- Executes on button press in FileInitStateRB.
function FileInitStateRB_Callback(hObject, eventdata, handles)
% hObject    handle to FileInitStateRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FileInitStateRB


% --- Executes on button press in pushbutton62.
function pushbutton62_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in PointDefaultCB.
function PointDefaultCB_Callback(hObject, eventdata, handles)
handles.Pointz0Edit.String='0+0i';
handles.PointMiuEdit.String='1+0i';
handles.PointMiu0Edit.String='0.25i+0';
% hObject    handle to PointDefaultCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function PointMiuEdit_Callback(hObject, eventdata, handles)
% hObject    handle to PointMiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PointMiuEdit as text
%        str2double(get(hObject,'String')) returns contents of PointMiuEdit as a double


% --- Executes during object creation, after setting all properties.
function PointMiuEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PointMiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PointMiu0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to PointMiu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PointMiu0Edit as text
%        str2double(get(hObject,'String')) returns contents of PointMiu0Edit as a double


% --- Executes during object creation, after setting all properties.
function PointMiu0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PointMiu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Pointz0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Pointz0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Pointz0Edit as text
%        str2double(get(hObject,'String')) returns contents of Pointz0Edit as a double


% --- Executes during object creation, after setting all properties.
function Pointz0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Pointz0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PointDefaultFuncsCB.
function PointDefaultFuncsCB_Callback(hObject, eventdata, handles)
handles.PointBaseImagMenu.Value=1;
handles.PointLambdaMenu.Value=5;
handles.PointBaseImagMenu.Enable='on';
handles.PointLambdaMenu.Enable='on';

handles.PointCustomIterFuncCB.Value = 0;
handles.PointUsersBaseImagEdit.Enable='off';
handles.PointUsersBaseImagEdit.String='';
% hObject    handle to PointDefaultFuncsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function PointUsersBaseImagEdit_Callback(hObject, eventdata, handles)
% hObject    handle to PointUsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PointUsersBaseImagEdit as text
%        str2double(get(hObject,'String')) returns contents of PointUsersBaseImagEdit as a double


% --- Executes during object creation, after setting all properties.
function PointUsersBaseImagEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PointUsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PointCustomIterFuncCB.
function PointCustomIterFuncCB_Callback(hObject, eventdata, handles)

if hObject.Value==1
    handles.PointBaseImagMenu.Enable='off';
    handles.PointLambdaMenu.Enable='off';
    
    handles.PointUsersBaseImagEdit.Enable='on';
else
    handles.PointBaseImagMenu.Enable='on';
    handles.PointLambdaMenu.Enable='on';
    
    handles.PointUsersBaseImagEdit.Enable='off';
    handles.PointUsersBaseImagEdit.String='';
end
% hObject    handle to PointCustomIterFuncCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PointCustomIterFuncCB


% --- Executes on selection change in PointBaseImagMenu.
function PointBaseImagMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PointBaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PointBaseImagMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PointBaseImagMenu


% --- Executes during object creation, after setting all properties.
function PointBaseImagMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PointBaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PointLambdaMenu.
function PointLambdaMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PointLambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PointLambdaMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PointLambdaMenu


% --- Executes during object creation, after setting all properties.
function PointLambdaMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PointLambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MultiDefaultFuncsCB.
function MultiDefaultFuncsCB_Callback(hObject, eventdata, handles)
handles.MultiBaseImagMenu.Value=1;
handles.MultiLambdaMenu.Value=5;
handles.MultiBaseImagMenu.Enable='on';
handles.MultiLambdaMenu.Enable='on';

handles.MultiCustomIterFuncCB.Value = 0;
handles.MultiUsersBaseImagEdit.Enable='off';
handles.MultiUsersBaseImagEdit.String='';
% hObject    handle to MultiDefaultFuncsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function MultiUsersBaseImagEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MultiUsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MultiUsersBaseImagEdit as text
%        str2double(get(hObject,'String')) returns contents of MultiUsersBaseImagEdit as a double


% --- Executes during object creation, after setting all properties.
function MultiUsersBaseImagEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiUsersBaseImagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MultiCustomIterFuncCB.
function MultiCustomIterFuncCB_Callback(hObject, eventdata, handles)

if hObject.Value==1
    handles.MultiBaseImagMenu.Enable='off';
    handles.MultiLambdaMenu.Enable='off';
    
    handles.MultiUsersBaseImagEdit.Enable='on';
else
    handles.MultiBaseImagMenu.Enable='on';
    handles.MultiLambdaMenu.Enable='on';
    
    handles.MultiUsersBaseImagEdit.Enable='off';
    handles.MultiUsersBaseImagEdit.String='';
end
% hObject    handle to MultiCustomIterFuncCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MultiCustomIterFuncCB


% --- Executes on button press in WindowParamDefaultB.
function WindowParamDefaultB_Callback(hObject, eventdata, handles)
handles.ParamNameMenu.Value = 1;
handles.ParamReDeltaEdit.String = '5';
handles.ParamImDeltaEdit.String = '5';
handles.ParamRePointsEdit.String = '100';
handles.ParamImPointsEdit.String = '100';
% hObject    handle to WindowParamDefaultB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in ParamNameMenu.
function popupmenu35_Callback(hObject, eventdata, handles)
% hObject    handle to ParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ParamNameMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ParamNameMenu


% --- Executes during object creation, after setting all properties.
function popupmenu35_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamNameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton58.
function pushbutton58_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in MultiDefaultCB.
function MultiDefaultCB_Callback(hObject, eventdata, handles)

handles.Multiz0Edit.String='0+0i';
handles.MultiMiuEdit.String='1+0i';
handles.MultiMiu0Edit.String='0.25i+0';
% hObject    handle to MultiDefaultCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function MultiMiuEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MultiMiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MultiMiuEdit as text
%        str2double(get(hObject,'String')) returns contents of MultiMiuEdit as a double


% --- Executes during object creation, after setting all properties.
function MultiMiuEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiMiuEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MultiMiu0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to MultiMiu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MultiMiu0Edit as text
%        str2double(get(hObject,'String')) returns contents of MultiMiu0Edit as a double


% --- Executes during object creation, after setting all properties.
function MultiMiu0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiMiu0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Multiz0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Multiz0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Multiz0Edit as text
%        str2double(get(hObject,'String')) returns contents of Multiz0Edit as a double


% --- Executes during object creation, after setting all properties.
function Multiz0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Multiz0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit173_Callback(hObject, eventdata, handles)
% hObject    handle to ParamRePointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamRePointsEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamRePointsEdit as a double


% --- Executes during object creation, after setting all properties.
function edit173_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamRePointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit174_Callback(hObject, eventdata, handles)
% hObject    handle to ParamReDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamReDeltaEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamReDeltaEdit as a double


% --- Executes during object creation, after setting all properties.
function edit174_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamReDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit175_Callback(hObject, eventdata, handles)
% hObject    handle to ParamImDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamImDeltaEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamImDeltaEdit as a double


% --- Executes during object creation, after setting all properties.
function edit175_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamImDeltaEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit176_Callback(hObject, eventdata, handles)
% hObject    handle to ParamImPointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParamImPointsEdit as text
%        str2double(get(hObject,'String')) returns contents of ParamImPointsEdit as a double


% --- Executes during object creation, after setting all properties.
function edit176_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParamImPointsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in MultiBaseImagMenu.
function MultiBaseImagMenu_Callback(hObject, eventdata, handles)
% hObject    handle to MultiBaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MultiBaseImagMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MultiBaseImagMenu


% --- Executes during object creation, after setting all properties.
function MultiBaseImagMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiBaseImagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in MultiLambdaMenu.
function MultiLambdaMenu_Callback(hObject, eventdata, handles)
% hObject    handle to MultiLambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MultiLambdaMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MultiLambdaMenu


% --- Executes during object creation, after setting all properties.
function MultiLambdaMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiLambdaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function CalcObjMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CalcObjMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function PointObjMenuItem_Callback(hObject, eventdata, handles)
handles.CAPanel.Visible = 'off';
handles.MatrixPanel.Visible = 'off';
handles.PointPanel.Visible = 'on';
handles.SaveParamsButton.UserData = 'Point';
handles.MaxPeriodEdit.Enable = 'on';

% hObject    handle to PointObjMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MatrixObjMenuItem_Callback(hObject, eventdata, handles)
handles.CAPanel.Visible = 'off';
handles.PointPanel.Visible = 'off';
handles.MatrixPanel.Visible = 'on';
handles.SaveParamsButton.UserData = 'Matrix';
handles.MaxPeriodEdit.Enable = 'on';
% hObject    handle to MatrixObjMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function CAObjMenuItem_Callback(hObject, eventdata, handles)
handles.PointPanel.Visible = 'off';
handles.MatrixPanel.Visible = 'off';
handles.CAPanel.Visible = 'on';
handles.SaveParamsButton.UserData = 'CA';
handles.MaxPeriodEdit.Enable = 'off';
handles.MaxPeriodEdit.String='';
% hObject    handle to CAObjMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in InitCAStateBG.
function InitCAStateBG_SelectionChangedFcn(hObject, eventdata, handles)
switch hObject.Tag
    case 'RangeInitStateRB'
        handles.FileInitStatePanel.Visible = 'off';
        handles.RangeInitStatePanel.Visible = 'on';
        handles.Z0SourcePathEdit.UserData = 0;
    case 'FileInitStateRB'
        handles.RangeInitStatePanel.Visible = 'off';
        handles.FileInitStatePanel.Visible = 'on';
        handles.Z0SourcePathEdit.UserData = 1;
end
% hObject    handle to the selected object in InitCAStateBG 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DefaultCAInitStateCB.
function DefaultCAInitStateCB_Callback(hObject, eventdata, handles)
handles.RangeInitStateRB.Value = 1;
InitCAStateBG_SelectionChangedFcn(handles.RangeInitStateRB, [], handles);
handles.DistributionTypeMenu.Value = 1;
handles.DistributStartEdit.String = '1';
handles.DistributStepEdit.String = '1';
handles.DistributEndEdit.String = '0';
% hObject    handle to DefaultCAInitStateCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
