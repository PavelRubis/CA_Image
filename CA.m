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

% Last Modified by GUIDE v2.5 16-Feb-2021 01:42:39

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

xLabel = 'Re(z)';
xFunc = @(z)z(1, :);
yLabel = 'Im(z)';
yFunc = @(z)z(2, :);

VisOptions = PointPathVisualisationOptions('jet', xFunc, yFunc, xLabel, yLabel, []);
PointPathVisualisationOptions.GetSetPointPathVisualisationOptions('jet', xFunc, yFunc, xLabel, yLabel, []);
setappdata(hObject, 'VisOptions', VisOptions);

saveRes = SaveResults();
setappdata(hObject, 'SaveResults', saveRes);

CurrCA = CellularAutomat(0, 1, 2, 1, @(z)(exp(i * z)), @(z_k)Miu0 + sum(z_k), 0, 0, 0, [1 1 1 1 1 1 1 1]);
ContParms = ControlParams(1,1,0,0,' ',@(z)exp(i*z),'*(Miu+z)');
ControlParams.GetSetCustomImag(0);

ResProc = ResultsProcessing(' ',1,1);
ResultsProcessing.GetSetCellOrient(0);
ResultsProcessing.GetSetFieldOrient(0);
ResultsProcessing.GetSetVisualizationSettings({2, 'jet'});
ResultsProcessing.GetSetPointsVisualizationSettings({1, 'jet'});

FileWasRead=false;

handles.LambdaMenu.Value=5;

setappdata(hObject,'CurrCA',CurrCA);
setappdata(hObject,'ContParms',ContParms);
setappdata(hObject,'ResProc',ResProc);
setappdata(hObject,'FileWasRead',FileWasRead);
axis image;

% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CA (see VARARGIN)

% Choose default command line output for CA
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
%parpool;

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

IteratedObject = getappdata(handles.output, 'IIteratedObject');
calcParams = getappdata(handles.output, 'calcParams');
saveRes = getappdata(handles.output, 'SaveResults');
[saveRes] = SaveResults.IsReady2Start(saveRes);

visualOptions = getappdata(handles.output, 'VisOptions');

if any([isempty(IteratedObject) isempty(calcParams) isempty(saveRes)])
    return;
end
wb = waitbar(0, 'Выполняется расчет...', 'WindowStyle', 'modal');
switch class(IteratedObject)
    case 'IteratedPoint'

        for iter = 1:calcParams.IterCount
            waitbar(iter / calcParams.IterCount, wb, 'Выполняется расчет...', 'WindowStyle', 'modal');
            IteratedObject = Iteration(IteratedObject, calcParams);

            if ~IsContinue(IteratedObject)
                break;
            end

        end

    case 'IteratedMatrix'
        IteratedObject = Iteration(IteratedObject, calcParams);

end

waitbar(1, wb, 'Отрисовка...', 'WindowStyle', 'modal');
[res visualOptions graphics] = PrepareDataAndAxes(visualOptions, IteratedObject, handles);


if saveRes.IsSave
    waitbar(1, wb, 'Сохранение выходных данных...', 'WindowStyle', 'modal');
    saveRes = SaveModelingResults(saveRes, res, IteratedObject, calcParams, graphics);
end

setappdata(handles.output, 'IIteratedObject', IteratedObject);
setappdata(handles.output, 'VisOptions', visualOptions);
if string(class(visualOptions)) ==  "PointPathVisualisationOptions"
    PointPathVisualisationOptions.GetSetPointPathVisualisationOptions(visualOptions.ColorMap, visualOptions.XAxesdataProcessingFunc, visualOptions.YAxesdataProcessingFunc, visualOptions.XAxescolorMapLabel, visualOptions.YAxescolorMapLabel, visualOptions.VisualPath);
end
setappdata(handles.output, 'SaveResults',saveRes);
handles.ResetButton.Enable='on';

delete(wb);
return;
%%
%legacy

contParms = getappdata(handles.output,'ContParms');
resProc = getappdata(handles.output,'ResProc');
ca = getappdata(handles.output,'CurrCA');

error = getappdata(handles.output,'error');
errorStr = getappdata(handles.output,'errorStr');

if (length(resProc.ResPath)==1 || ~ischar(resProc.ResPath)) &&  resProc.isSave
    error=true;
    errorStr=strcat(errorStr,'Не задана директория сохранения результатов; ');
end

if isempty(regexp(handles.IterCountEdit.String,'^\d+$'))
    error=true;
    errorStr=strcat(errorStr,'Ошибка в поле числа итераций; ');
end

if isempty(regexp(handles.InfValueEdit.String,'^\d+$')) || isempty(regexp(handles.ConvergValueEdit.String,'^\d+$'))
    error=true;
    errorStr=strcat(errorStr,'Ошибка в полях точности вычислений; ');
end

if  (isempty(regexp(handles.MaxPeriodEdit.String,'^\d+$')) || str2double(handles.MaxPeriodEdit.String)>str2double(handles.IterCountEdit.String)) && (~contParms.SingleOrMultipleCalc || length(ca.Cells)==1)
    error=true;
    errorStr=strcat(errorStr,'Ошибка в поле максимального периода; ');
end

if error
    handles.ResetButton.Enable='on';
    errorStr=regexprep(errorStr,';$','.');
    errordlg(errorStr,'Ошибки ввода:');
    return;
end

handles.ParamRePointsEdit.Enable='off';
handles.ParamNameMenu.Enable='off';
handles.ParamReDeltaEdit.Enable='off';
handles.ParamImDeltaEdit.Enable='off';
handles.ParamRePointsEdit.Enable='off';
handles.ParamImPointsEdit.Enable='off';
handles.DefaultMultiParmCB.Enable='off';
    
handles.NFieldEdit.Enable='off';
handles.SquareFieldRB.Enable='off';
handles.HexFieldRB.Enable='off';
handles.GorOrientRB.Enable='off';
handles.VertOrientRB.Enable='off';
handles.DefaultCACB.Enable='off';
handles.CompletedBordersRB.Enable='off';
handles.DeathLineBordersRB.Enable='off';
handles.ClosedBordersRB.Enable='off';
handles.NeumannRB.Enable ='off';
handles.MooreRB.Enable ='off';
handles.CustomIterFuncCB.Enable  ='off';
    
handles.BaseImagMenu.Enable='off';
handles.UsersBaseImagEdit.Enable='off';
handles.LambdaMenu.Enable='off';
handles.DefaultFuncsCB.Enable='off';
    
handles.z0Edit.Enable='off';
handles.MiuEdit.Enable='off';
handles.Miu0Edit.Enable='off';
handles.DefaultCB.Enable='off';
handles.CountBaseZButton.Enable='off';
    
handles.DistributionTypeMenu.Enable='off';
handles.DistributStartEdit.Enable='off';
handles.DistributStepEdit.Enable='off';
handles.DistributEndEdit.Enable='off';
    
handles.Z0SourcePathButton.Enable='off';
handles.ReadZ0SourceButton.Enable='off';
    
handles.SingleCalcRB.Enable='off';
handles.MultipleCalcRB.Enable='off';
handles.ReadModelingParmsFrmFile.Enable='off';
handles.CASettingsMenuItem.Enable='off';

visualizationSettings = ResultsProcessing.GetSetVisualizationSettings;

switch visualizationSettings(1)

    case 1
        ControlParams.GetSetPrecisionParms([str2double(strcat('1e', handles.InfValueEdit.String)) str2double(strcat('1e-', handles.ConvergValueEdit.String))]);
    case 2
        ControlParams.GetSetPrecisionParms([str2double(handles.InfValueEdit.String) str2double(strcat('1e-', handles.ConvergValueEdit.String))]);
end

handles.CancelParamsButton.Enable = 'off';
itersCount = str2double(handles.IterCountEdit.String); %число итераций
contParms.IterCount = contParms.IterCount + itersCount;

ControlParams.GetSetMaxPeriod(str2double(handles.MaxPeriodEdit.String));

if ~contParms.SingleOrMultipleCalc% в случае мультирассчета

    %создание окна и матрицы функций базы
    [WindowParam contParms z_eqArr] = DataFormatting.MakeFuncsWithNumsForMultipleCalc(ca, contParms);

    len = size(WindowParam);
    zParam = false;
    Z_Old = [];

    switch contParms.WindowParamName
        case 'z0'
            z_New = WindowParam;
            Z_Old = z_New;
            zParam = true;
        case {'Miu', 'Miu0'}
            z_New = zeros(len);
            z_New(:) = str2double(handles.z0Edit.String);
            Z_Old = z_New;
    end

    fStepNew = zeros(len);
    Delta = zeros(len);

    ZParam = zeros(len);
    ZParam(:) = zParam;
    Z_Old_1 = Inf(len);

    FStep = zeros(len);
    ItersCount = zeros(len);
    ItersCount(:) =  itersCount;
    Pathes = cell(len);

    wb = waitbar(0,'Выполняется расчет...','WindowStyle','modal');
%     profile on;
    [z_New fStepNew Fcode Iters Periods] = arrayfun(@ControlParams.MakeMultipleCalcIter, WindowParam, Z_Old, Z_Old_1, ItersCount, ZParam, z_eqArr);
%     profile viewer;
    waitbar(1,wb,'Отрисовка...');
    axes(handles.CAField);

    zRes = z_New;
    PrecisionParms = ControlParams.GetSetPrecisionParms;

    contParms.Periods = Periods;
    contParms.LastIters = Iters;
    fcodeIndicate = find(Fcode == 1);
    
    posSteps = unique(fStepNew(fcodeIndicate));
    fcodeIndicate = find(Fcode == -1);
    negSteps = unique(fStepNew(fcodeIndicate));

    chaosCodeIndicate = find(Fcode == 2);
    fStepNew(chaosCodeIndicate) = -1;

    periodCodeIndicate = find(Fcode == 3);
    fStepNew(periodCodeIndicate) = Periods(periodCodeIndicate);

    maxPosSteps = zeros(len);
    minNegStep = min(negSteps);
    clmp = [];

    if ~isempty(posSteps)
        maxPosSteps(:) = max(posSteps); %+(10-mod(max(posSteps),10));

        periodCodeIndicate = find(Fcode == 3);
        fStepNew(periodCodeIndicate) = maxPosSteps(periodCodeIndicate) + Periods(periodCodeIndicate);

        if ~isempty(negSteps)
            chaosCodeIndicate = find(Fcode == 2);
            fStepNew(chaosCodeIndicate) = max(negSteps) + 1;
            clmp = [flipud(gray(max(negSteps))); flipud(winter(floor((max(negSteps) * ((max(posSteps) + 2) / max(negSteps))))))]; %(max(posSteps)-mod(max(posSteps),10))
        else
            clmp = flipud(winter(floor((max(posSteps) - mod(max(posSteps), 10)))));
        end

    else

        if ~isempty(negSteps)
            clmp = flipud(gray(max(negSteps)));
        end

    end

    if ~isempty(chaosCodeIndicate)
        clmp = [spring(1); clmp];
        Fcode(chaosCodeIndicate) = -1;
    end

    if ~isempty(periodCodeIndicate)
        clmp = [clmp; autumn(max(Periods(periodCodeIndicate)))];
        Fcode(periodCodeIndicate) = 1;
    end

    clrmp = colormap(clmp);

    [Re, Im] = meshgrid(contParms.ReRangeWindow, contParms.ImRangeWindow);
    pcolor(Re, Im, (fStepNew .* Fcode));

    shading flat;
    clrbr = colorbar;

    if ~isempty(periodCodeIndicate)
        lim = clrbr.Limits;
        ticks = clrbr.Ticks;
        ticksDelta = ticks(2) - ticks(1);

        if lim(2) > max(posSteps) + ticksDelta / 5
            ticks = ticks(find(ticks <= max(posSteps)));
            ticks = [ticks max(posSteps) + ticksDelta / 5:ticksDelta / 5:lim(2)];
            clrbr.Ticks = ticks;

            lables = clrbr.TickLabels';
            lables = arrayfun(@(num)str2double(cell2mat(num)), lables);
            newLables = [lables(find(lables <= max(posSteps))) (lables(find(lables > max(posSteps))) - max(posSteps))];
            clrbr.TickLabels = {newLables};
        end

    end

    zoom on;

    DataFormatting.PlotFormatting(contParms, ca, handles);

    graphics.Axs = handles.CAField;
    graphics.Clrbr = clrbr;
    graphics.Clrmp = clrmp;

    if resProc.isSave
        waitbar(1,wb,'Сохранение выходных данных...');
        resProc = SaveRes(resProc, ca, graphics, contParms, zRes);
    end

    handles.ResetButton.Enable = 'on';
    setappdata(handles.output, 'CurrCA', ca);
    setappdata(handles.output, 'ContParms', contParms);
    setappdata(handles.output, 'ResProc', resProc);
    handles.SaveAllModelParamsB.Enable = 'on';
    delete(wb);
    return;
end


ca.Weights = CellularAutomat.GetSetWeights;

if isempty(ca.Weights)
    ca.Weights = [1 1 1 1 1 1 1 1];
end

%подготовка обоих функций
DataFormatting.MakeCAFuncsWithNums(ca);

if length(ca.Cells) == 1%случай когда рассматривается одна ячейка/точка

    N1Path = getappdata(handles.output, 'N1Path');
    msg = [];

    N1PathOld = complex(N1Path(1, :), N1Path(2, :));
    len = length(N1Path(1, :));
    N1Path = [N1Path nan(2, itersCount)];

    for i = 1:itersCount
        ca.Cells(1) = CellularAutomat.MakeIter(ca.Cells(1));
        N1Path(1, i + len) = real(ca.Cells(1).zPath(end));
        N1Path(2, i + len) = imag(ca.Cells(1).zPath(end));

        pointPath = complex(N1Path(1, :), N1Path(2, :));
        [fCode iter period] = ControlParams.CheckConvergence(pointPath);

        if fCode ~= 2
            str = strcat('Точка ', num2str(ca.Cells(1).z0));

            switch fCode
                case - 1
                    ca.Cells(1).zPath = ca.Cells(1).zPath(:, 1:iter - 1);
                    str = strcat(str, ' уходит в бесконечность на итерации:');
                    str = strcat(str, '  ');
                    msg = strcat(str, num2str(iter - 1));
                case 1
                    str = strcat(str, ' сходится к аттрактору на итерации:');
                    str = strcat(str, '  ');
                    msg = strcat(str, num2str(iter - 1));
                otherwise
                    str = strcat(str, ' имеет период: ');
                    str = strcat(str, num2str(period));
                    str = strcat(str, ', найденный на итерации:');
                    str = strcat(str, '  ');
                    msg = strcat(str, num2str(iter - 1));
            end

            break;
        end

    end

    if fCode == -1
        N1Path = N1Path(:, 1:iter - 1);
    else
        N1Path = N1Path(:, 1:iter);
    end

    N1PathNew = complex(N1Path(1, :), N1Path(2, :));
    N1PathOldVisual = [real(N1PathOld);imag(N1PathOld)];
    N1PathOld = [N1PathOld nan(1, length(N1PathNew) - length(N1PathOld))];
    ind = length(find(N1PathOld == N1PathNew));

    if ind < length(N1PathNew)
        temp = N1PathNew(ind:length(N1PathNew));
        tempNew = zeros(2, length(temp));
        tempNew(1, :) = real(temp);
        tempNew(2, :) = imag(temp);
        N1PathNew = tempNew;
    else
        N1PathNew = [];
    end
    
    if ~isempty(N1PathNew)
        axes(handles.CAField);
        cla reset;

        N1PathOld(end) = [];
        newPartPathLength = length(N1PathNew);

        [vSettings1 vSettings2]  = ResultsProcessing.GetSetPointsVisualizationSettings;
        N1PathNewVisual = N1PathNew;

        switch vSettings1
            case 1
                xlabel('Re(z)');
                ylabel('Im(z)');
            case 2
                xlabel('\midz\mid');
                N1PathNewVisual(1, :) = abs(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));
                ylabel('\phi(z)');
                N1PathNewVisual(2, :) = angle(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));

                N1PathOldVisual(1, :) = abs(complex(N1PathOldVisual(1, :), N1PathOldVisual(2, :)));
                N1PathOldVisual(2, :) = angle(complex(N1PathOldVisual(1, :), N1PathOldVisual(2, :)));
            case 3
                xlabel('lg\midz+1\mid');
                N1PathNewVisual(1, :) = log(abs(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)) + 1))/log(10);
                ylabel('\phi(z)');
                N1PathNewVisual(2, :) = angle(complex(N1PathNewVisual(1, :), N1PathNewVisual(2, :)));

                N1PathOldVisual(1, :) = log(abs(complex(N1PathOldVisual(1, :), N1PathOldVisual(2, :)) + 1)) / log(10);
                N1PathOldVisual(2, :) = angle(complex(N1PathOldVisual(1, :), N1PathOldVisual(2, :)));
            case 4
                xlabel('lg\midRe+1\mid');
                N1PathNewVisual(1, :) = log(abs(N1PathNewVisual(1, :) + 1)) / log(10);
                xlabel('lg\midIm+1\mid');
                N1PathNewVisual(2, :) = log(abs(N1PathNewVisual(2, :) + 1)) / log(10);

                N1PathOldVisual(1, :) = log(abs(N1PathOldVisual(1, :) + 1)) / log(10);
                N1PathOldVisual(2, :) = log(abs(N1PathOldVisual(2, :) + 1)) / log(10);
                

        end
        N1PathOldVisual=complex(N1PathOldVisual(1,:),N1PathOldVisual(1,:));
        eval(strcat('clrmp = colormap(', vSettings2, '(newPartPathLength));'));
        ms = 20;


        %%
        hold on;
        for i = 1:length(N1PathNewVisual)
            plot(N1PathNewVisual(1, i), N1PathNewVisual(2, i), 'o', 'MarkerSize', ms, 'Color', clrmp(i, :));

            if ms ~= 2
                ms = ms - 2;
            end

        end

        imStep = (abs(max(N1PathNewVisual(2, :)) - min(N1PathNewVisual(2, :))) / length(N1PathNewVisual(2, :))) * 0.2 * length(N1PathNewVisual(2, :));
        reStep = (abs(max(N1PathNewVisual(1, :)) - min(N1PathNewVisual(1, :))) / length(N1PathNewVisual(1, :))) * 0.2 * length(N1PathNewVisual(1, :));

        if (any(N1PathNewVisual(1, :) < min(real(N1PathOldVisual))) || any(N1PathNewVisual(1, :) > max(real(N1PathOldVisual))))
            handles.CAField.XLim = [min(N1PathNewVisual(1, :)) max(N1PathNewVisual(1, :))];
        end

        if (any(N1PathNewVisual(2, :) < min(imag(N1PathOldVisual))) || any(N1PathNewVisual(2, :) > max(imag(N1PathOldVisual))))
            handles.CAField.YLim = [min(N1PathNewVisual(2, :)) max(N1PathNewVisual(2, :))];
        end

        handles.CAField.YTick = [min(N1PathNewVisual(2, :)):imStep:max(N1PathNewVisual(2, :))];
        handles.CAField.XTick = [min(N1PathNewVisual(1, :)):reStep:max(N1PathNewVisual(1, :))];

        ImLength = max(N1PathNewVisual(2, :)) - min(N1PathNewVisual(2, :));
        ReLength = max(N1PathNewVisual(1, :)) - min(N1PathNewVisual(1, :));

        Coeff = ReLength - ImLength;

        if Coeff ~= 0

            if Coeff < 0
                Coeff = abs(Coeff);

                handles.CAField.XLim = [min(N1PathNewVisual(1, :)) - Coeff / 2 max(N1PathNewVisual(1, :)) + Coeff / 2];

            else
                
                handles.CAField.YLim = [min(N1PathNewVisual(2, :)) - Coeff / 2 max(N1PathNewVisual(2, :)) + Coeff / 2];

            end

        end

        xticks('auto');
        yticks('auto');

        handles.CAField.XGrid = 'on';
        handles.CAField.YGrid = 'on';

        if newPartPathLength < 15
            clrbr = colorbar('Ticks', [1:newPartPathLength] / newPartPathLength, 'TickLabels', {1:newPartPathLength});
        else
            clrbr = colorbar('Ticks', [0, 0.2, 0.4, 0.6, 0.8, 1], ...
                'TickLabels', {0, floor(newPartPathLength * 0.2), floor(newPartPathLength * 0.4), floor(newPartPathLength * 0.6), floor(newPartPathLength * 0.8), newPartPathLength - 1});
            clrbr.Label.String = 'Число итераций';
        end

        zoom on;
        graphics.Axs = handles.CAField;
        graphics.Clrbr = clrbr;
        graphics.Clrmp = clrmp;

        DataFormatting.PlotFormatting(contParms, ca, handles);

        contParms.LastIters = length(N1Path);
        contParms.Periods = period;

        N1PathNew(1,1) = [];
        N1PathNew(2,1) = [];
        if resProc.isSave
            resProc = SaveRes(resProc, ca, graphics, contParms, N1PathNew);
        end
    end

    handles.ResetButton.Enable = 'on';
    setappdata(handles.output, 'CurrCA', ca);
    setappdata(handles.output, 'ContParms', contParms);
    setappdata(handles.output, 'N1Path', N1Path);
    setappdata(handles.output, 'ResProc', resProc);
    handles.SaveAllModelParamsB.Enable = 'on';

    if ~isempty(msg)
        msgbox(msg, 'modal');
    end

    return;

end

%        profile on;
%нахождение соседей каждой ячейки
for i = 1:length(ca.Cells)
    ca.Cells(i) = FindCellsNeighbors(ca, ca.Cells(i));
end

cellArr = ca.Cells;
ca_L = length(ca.Cells);

%блок тестирования правильности нахождения элементов и работы всех типов границ
bordersType = zeros(1, ca_L);
bordersType(:) = ca.BordersType;
fieldType = bordersType;
fieldType(:) = ca.FieldType;
nArr = fieldType;
nArr(:) = ca.N;

[isIntrnl, isIntrnlPlus, isCorner, isCornerAx, isEdg, isZero, isTrueCell, errorCellsInfo] = arrayfun(@TestingScripts.CheckNeighborsAndBorderType, ca.Cells, nArr, fieldType, bordersType);

switch ca.BordersType

    case 1

        if ca.FieldType == 1
            %внутренние ячейки:
            Intrnl = length(find(isIntrnl)) == ((3 * ca.N^2) - (15 * ca.N) + 18);

            %внутренние ячейки с соседями из другой фигуры:
            IntrnlPlus = length(find(isIntrnlPlus)) == 6 * ca.N - 12;

            %мертвые ячейки:
            Edg = length(find(isEdg)) == 6 * ca.N - 12 + 6;

            %нулевая ячейка:
            Zero = length(find(isZero)) == 1;

            all([Intrnl IntrnlPlus Edg Zero])
        else
            Intrnl = length(find(isIntrnl)) == (ca.N - 2)^2;
            Edg = length(find(isEdg)) == (ca.N)^2 - (ca.N - 2)^2;

            all([Intrnl Edg])
        end

    case 2

        if ca.FieldType == 1
            %внутренние ячейки:
            Intrnl = length(find(isIntrnl)) == ((3 * ca.N^2) - (15 * ca.N) + 18);

            %внутренние ячейки с соседями из другой фигуры:
            IntrnlPlus = length(find(isIntrnlPlus)) == 6 * ca.N - 12;

            %ячейки на ребре:
            Edg = length(find(isEdg)) == 6 * ca.N - 12;

            %угловые ячейки:
            Corner = length(find(isCorner)) == 3;

            %осевые  угловые ячейки:
            CornerAx = length(find(isCornerAx)) == 3;

            %нулевая ячейка:
            Zero = length(find(isZero)) == 1;

            all([Intrnl IntrnlPlus Edg Corner CornerAx Zero])
        else
            TrueCell = all(isTrueCell);

            Intrnl = length(find(isIntrnl)) == (ca.N - 2)^2;

            Edg = length(find(isEdg)) == (ca.N)^2 - (ca.N - 2)^2 - 4;

            Corner = length(find(isCorner)) == 4;

            all([TrueCell Intrnl Edg Corner])
        end

    case 3

        if ca.FieldType == 1
            %внутренние ячейки:
            Intrnl = length(find(isIntrnl)) == ((3 * ca.N^2) - (15 * ca.N) + 18);

            %внутренние ячейки с соседями из другой фигуры:
            IntrnlPlus = length(find(isIntrnlPlus)) == 6 * ca.N - 12;

            %ячейки на ребре c четырьмя соседями:
            Edg = length(find(isEdg)) == 6 * ca.N - 12;

            %ячейки c тремя соседями:
            Corner = length(find(isCorner)) == 6;

            %нулевая ячейка:
            Zero = length(find(isZero)) == 1;

            all([Intrnl IntrnlPlus Edg Corner Zero])
        else
            Intrnl = length(find(isIntrnl)) == (ca.N - 2)^2;

            Edg = length(find(isEdg)) == (ca.N)^2 - (ca.N - 2)^2 - 4;

            Corner = length(find(isCorner)) == 4;

            all([Intrnl Edg Corner])
        end

end

%блок тестирования правильности нахождения элементов и всех типов границ
%рассчет поля КА

wb = waitbar(0,'Выполняется расчет...','WindowStyle','modal');
for i = 1:itersCount

    try
        cellArr = arrayfun(@(cell)CellularAutomat.MakeIter(cell), cellArr);
    catch ex
        errordlg(getReport(ex), 'Ошибка:');
        return;
    end

    ca.Cells = cellArr;

    for j = 1:ca_L
        cellArr(j) = UpdateNeighborsValues(ca, ca.Cells(j));
    end
    waitbar(i/itersCount,wb,'Выполняется расчет...','WindowStyle','modal');

end

waitbar(1,wb,'Отрисовка...','WindowStyle','modal');
axes(handles.CAField);

modulesArr = zeros(1, ca_L);
zbase = zeros(1, ca_L);
zbase(:) = ca.Zbase;
PrecisionParms = ControlParams.GetSetPrecisionParms;

cellsValsArr = arrayfun(@(cell) cell.zPath(end), ca.Cells);
cellsValsArr = round(cellsValsArr * (1 / PrecisionParms(2))) / (1 / PrecisionParms(2));

[visualiseData, clrMap] = ResultsProcessing.GetSetVisualizationSettings;
switch visualiseData
    case 1
        modulesArr = arrayfun(@(val) abs(val), cellsValsArr);
        colorBarTitle = '\fontsize{16}\midz\mid';
    case 2
        modulesArr = arrayfun(@(val, zbase) log(abs(val - zbase)) / log(10), cellsValsArr, zbase);
        colorBarTitle = '\fontsize{16}log_{10}(\midz-z^{*}\mid)';
end

[modulesArrSrt indxes] = sort(modulesArr);

infValCACellsIndxes = find(modulesArr > PrecisionParms(1) | isnan(modulesArr));

for ind = 1:length(infValCACellsIndxes)
    ca.Cells(infValCACellsIndxes(ind)).Color = [0 0 0];
end

minusinfValCACellsIndxes = find(modulesArr < -PrecisionParms(1));

for ind = 1:length(minusinfValCACellsIndxes)
    ca.Cells(minusinfValCACellsIndxes(ind)).Color = [1 1 1];
end

modulesArrNanInfFiltered = modulesArr;
modulesArrNanInfFiltered(infValCACellsIndxes) = [];
modulesArrNanInfFiltered(minusinfValCACellsIndxes) = [];
modulesArrNanInfFiltered = sort(modulesArrNanInfFiltered);

%создание палитры
eval(strcat('colors=colormap(', clrMap, '(', num2str(length(modulesArrNanInfFiltered)), '));'));

for index = 1:length(modulesArrNanInfFiltered)
    sameValCACellsindxes = find(modulesArr == modulesArrNanInfFiltered(index));
    for ind = 1:length(sameValCACellsindxes)
        ca.Cells(sameValCACellsindxes(ind)).Color = colors(index, :);
    end
end

%отрисовка поля
arrayfun(@(cell) ResultsProcessing.DrawCell(cell), ca.Cells);
colors = arrayfun(@(cell) {cell.Color}, ca.Cells(indxes));
colors = cell2mat(colors');

if ~isempty(infValCACellsIndxes)
    colors = [colors; [0 0 0]];
end

if ~isempty(minusinfValCACellsIndxes)
    colors = [[1 1 1]; colors];
end

visualValsArr = modulesArr;
visualValsArr(infValCACellsIndxes) = inf;
visualValsArr(minusinfValCACellsIndxes) = -inf;
visualValsArr = sort(visualValsArr);

[unqVisualValsArr unqVisualValsArrIndxs] = unique(visualValsArr);
unqColors = colors(unqVisualValsArrIndxs', :);

clrbr = colorbar;
clrmp = colormap(unqColors);
clrbr.Ticks = [0:1 / length(unqVisualValsArr):1 - (1 / length(unqVisualValsArr))];
clrbr.TickLabels = unqVisualValsArr;

clrbr.Label.String = colorBarTitle;

DataFormatting.PlotFormatting(contParms, ca, handles);

graphics.Axs = handles.CAField;
graphics.Clrbr = clrbr;
graphics.Clrmp = clrmp;

if resProc.isSave
    waitbar(1,wb,'Сохранение выходных данных...','WindowStyle','modal');
    resProc = SaveRes(resProc, ca, graphics, contParms, []);
end

setappdata(handles.output, 'CurrCA', ca);
setappdata(handles.output, 'ContParms', contParms);
setappdata(handles.output, 'ResProc', resProc);
handles.ResetButton.Enable = 'on';
handles.SaveAllModelParamsB.Enable = 'on';
delete(wb);

      


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
currCA=getappdata(handles.output,'CurrCA');
contParms = getappdata(handles.output,'ContParms');
switch hObject.Value
    
    case 1
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)Miu0 + sum(z_k);
        else
            contParms.Lambda='*(Miu+z)';
        end
    case 2
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)Miu + Miu0*(abs(sum(z_k-Zbase)/(length(z_k))));
        else
            contParms.Lambda='*(Miu+(Miu0*abs(z-(eq))))';
        end
    case 3
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k,n)Miu + Miu0*abs(sum(arrayfun(@(z_n,o)o*z_n ,z_k,n)));
        else
            contParms.Lambda='*(Miu+(Miu0*abs(z)))';
        end
    case 4
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)Miu + Miu0*(sum(z_k-Zbase)/(length(z_k)));
        else
            contParms.Lambda='*(Miu+(Miu0*(z-(eq))))';
        end
    case 5
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)(Miu + Miu0);
        else
            contParms.Lambda='*(Miu+Miu0)';
        end
end

setappdata(handles.output,'CurrCA',currCA);
setappdata(handles.output,'ContParms',contParms);
        
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

%%
saveRes = getappdata(handles.output, 'SaveResults');
saveRes.ResultsFilename = '';
setappdata(handles.output, 'SaveResults', saveRes);

setappdata(handles.output, 'IIteratedObject', []);
setappdata(handles.output, 'calcParams', []);
%%

ca = getappdata(handles.output,'CurrCA');
contParms = getappdata(handles.output,'ContParms');
ResProc = getappdata(handles.output,'ResProc');
FileWasRead=getappdata(handles.output,'FileWasRead');
N1Path = getappdata(handles.output,'N1Path');

ca = CellularAutomat(ca.FieldType, ca.NeighborhoodType, ca.BordersType, ca.N, ca.Base, ca.Lambda, ca.Zbase, ca.Miu0, ca.Miu, [1 1 1 1 1 1 1 1]);

contParms.IsReady2Start=false;
contParms.IterCount=1;
ResProc.Filename=[];

N1Path=[];

FileWasRead=false;

setappdata(handles.output,'CurrCA',ca);
setappdata(handles.output,'ContParms',contParms);
setappdata(handles.output,'ResProc',ResProc);
setappdata(handles.output,'FileWasRead',FileWasRead);
setappdata(handles.output,'N1Path',N1Path);


handles.SaveAllModelParamsB.Enable='off';
handles.VisualIteratedObjectMenu.Visible='off';
handles.LambdaMenu.Enable='on';

if contParms.SingleOrMultipleCalc
    
    if str2double(handles.NFieldEdit.String)==1
        handles.DistributionTypeMenu.Enable='off';
        handles.DistributStartEdit.Enable='off';
        handles.DistributStepEdit.Enable='off';
        handles.DistributEndEdit.Enable='off';
        handles.Z0SourcePathButton.Enable='off';
        handles.ReadZ0SourceButton.Enable='off';
%         handles.LambdaMenu.Enable='off';
        handles.MaxPeriodEdit.Enable='on';
    else
        handles.DistributionTypeMenu.Enable='on';
        handles.DistributStartEdit.Enable='on';
        handles.DistributStepEdit.Enable='on';
        handles.DistributEndEdit.Enable='on';
        handles.Z0SourcePathButton.Enable='on';
        handles.ReadZ0SourceButton.Enable='on';
        handles.MaxPeriodEdit.Enable='off';
        handles.SquareFieldRB.Enable = 'on';
        handles.HexFieldRB.Enable = 'on';
        handles.GorOrientRB.Enable = 'on';
        handles.VertOrientRB.Enable = 'on';
        handles.DefaultCACB.Enable = 'on';
        handles.CompletedBordersRB.Enable = 'on';
        handles.DeathLineBordersRB.Enable = 'on';
        handles.ClosedBordersRB.Enable = 'on';
        handles.NeumannRB.Enable = 'on';
        handles.MooreRB.Enable = 'on';
    end
    
    handles.CustomIterFuncCB.Enable = 'on';
    handles.NFieldEdit.Enable = 'on';
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamNameMenu.Enable='off';
    handles.ParamReDeltaEdit.Enable='off';
    handles.ParamImDeltaEdit.Enable='off';
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamImPointsEdit.Enable='off';
    handles.DefaultMultiParmCB.Enable='off';
    
else
    handles.NFieldEdit.Enable='off';
    handles.SquareFieldRB.Enable='off';
    handles.HexFieldRB.Enable='off';
    handles.GorOrientRB.Enable='off';
    handles.VertOrientRB.Enable='off';
    handles.DefaultCACB.Enable='off';
    handles.CompletedBordersRB.Enable='off';
    handles.DeathLineBordersRB.Enable='off';
    handles.ClosedBordersRB.Enable='off';
    
    handles.DistributionTypeMenu.Enable='off';
    handles.DistributStartEdit.Enable='off';
    handles.DistributStepEdit.Enable='off';
    handles.DistributEndEdit.Enable='off';
    
    handles.Z0SourcePathButton.Enable='off';
    handles.ReadZ0SourceButton.Enable='off';
    
    handles.MaxPeriodEdit.Enable='on';
    handles.ParamRePointsEdit.Enable='on';
    handles.ParamNameMenu.Enable='on';
    handles.ParamReDeltaEdit.Enable='on';
    handles.ParamImDeltaEdit.Enable='on';
    handles.ParamRePointsEdit.Enable='on';
    handles.ParamImPointsEdit.Enable='on';
    handles.DefaultMultiParmCB.Enable='on';
    
end

handles.CustomIterFuncCB.Enable='on';

if handles.CustomIterFuncCB.Value ~= 1
    handles.UsersBaseImagEdit.Enable = 'off';
    handles.BaseImagMenu.Enable = 'on';
else
%     handles.LambdaMenu.Enable = 'off';
    handles.BaseImagMenu.Enable = 'off';
    handles.UsersBaseImagEdit.Enable = 'on';
end

    handles.ReadModelingParmsFrmFile.Enable='on';
    handles.DefaultFuncsCB.Enable='on';
    
    handles.z0Edit.Enable='on';
    handles.MiuEdit.Enable='on';
    handles.Miu0Edit.Enable='on';
    handles.DefaultCB.Enable='on';
    
    
    handles.SingleCalcRB.Enable='on';
    handles.MultipleCalcRB.Enable='on';
    handles.CASettingsMenuItem.Enable='on';
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

directory = uigetdir('C:\');
if(directory)
    saveRes.ResultsPath = directory;
    saveRes.IsSave = true;
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
saveRes=getappdata(handles.output,'SaveResults');
if hObject.Value == 1

    saveRes.IsSaveFig=1;
    
    set(handles.FigTypeMenu,'Enable','on');
else
    saveRes.IsSaveFig=0;
    hObject.Value = 0;
    
    set(handles.FigTypeMenu,'Enable','off');
end
setappdata(handles.output, 'SaveResults', saveRes);
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
contParms = getappdata(handles.output,'ContParms');
if(~isempty(regexp(handles.NFieldEdit.String,'^\d+$')))
    if str2double(handles.NFieldEdit.String)==1
        handles.DistributionTypeMenu.Enable='off';
        handles.DistributStartEdit.Enable='off';
        handles.DistributStepEdit.Enable='off';
        handles.DistributEndEdit.Enable='off';
        handles.Z0SourcePathButton.Enable='off';
        handles.ReadZ0SourceButton.Enable='off';
        handles.SquareFieldRB.Enable ='off';
        handles.HexFieldRB.Enable='off';
        handles.GorOrientRB.Enable ='off';
        handles.VertOrientRB.Enable ='off';
        handles.DefaultCACB.Enable ='off';
        handles.CompletedBordersRB.Enable ='off';
        handles.DeathLineBordersRB.Enable ='off';
        handles.ClosedBordersRB.Enable ='off';
        handles.NeumannRB.Enable ='off';
        handles.MooreRB.Enable ='off';
%         handles.LambdaMenu.Enable='off';
        handles.LambdaMenu.Value=5;
        
        handles.DistributStartEdit.String='';
        handles.DistributStepEdit.String='';
        handles.DistributEndEdit.String='';
        handles.Z0SourcePathEdit.String='';
        
        handles.MaxPeriodEdit.Enable='on';
        
    else
        handles.DistributionTypeMenu.Enable='on';
        handles.DistributStartEdit.Enable='on';
        handles.DistributStepEdit.Enable='on';
        handles.DistributEndEdit.Enable='on';
        handles.Z0SourcePathButton.Enable='on';
        handles.ReadZ0SourceButton.Enable='on';
        handles.MaxPeriodEdit.Enable='off';
        handles.SquareFieldRB.Enable = 'on';
        handles.HexFieldRB.Enable = 'on';
        handles.GorOrientRB.Enable = 'on';
        handles.VertOrientRB.Enable = 'on';
        handles.DefaultCACB.Enable = 'on';
        handles.CompletedBordersRB.Enable = 'on';
        handles.DeathLineBordersRB.Enable = 'on';
        handles.ClosedBordersRB.Enable = 'on';
        handles.NeumannRB.Enable = 'on';
        handles.MooreRB.Enable = 'on';
        if handles.CustomIterFuncCB.Value==0
            handles.LambdaMenu.Enable='on';
        end
    end
end
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
path=strcat(path,file);
handles.Z0SourcePathEdit.String=path;

% hObject    handle to Z0SourcePathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in ReadZ0SourceButton.
function ReadZ0SourceButton_Callback(hObject, eventdata, handles)
if(isempty(regexp(handles.NFieldEdit.String,'^\d+(\.?)(?(1)\d+|)$')) || isempty(handles.Z0SourcePathEdit.String) || ~ischar(handles.Z0SourcePathEdit.String))
    errordlg('Ошибка. Недопустимое для задания начальной конфигурации значение ребра поля N, или неверный путь к файлу','modal');
else
    path=handles.Z0SourcePathEdit.String;
    N=str2double(handles.NFieldEdit.String);
    
    currCA=getappdata(handles.output,'CurrCA');
    fileWasRead = getappdata(handles.output,'FileWasRead');
    
    [ca,FileWasRead] = Initializations.Z0FileInit(currCA,N,path,fileWasRead);
    
    setappdata(handles.output,'CurrCA',ca);
    setappdata(handles.output,'FileWasRead',FileWasRead);
    
%     cellCount=0;
%     fieldType= currCA.FieldType;
%     z0Arr=[];
% 
%     
%     if(regexp(path,'\.txt$'))
%         if fieldType
%             if N~=1
%                 cellCount=N*(N-1)*3+1;
%             else
%                 cellCount=1;
%             end
%             z0Size=[5 cellCount];
%             formatSpec = '%d %d %d %f %f\n';
%         else
%             cellCount=N*N;
%             z0Size=[4 cellCount];
%             formatSpec = '%d %d %f %f\n';
%         end
%         file = fopen(path, 'r');
%         z0Arr = fscanf(file, formatSpec,z0Size);
%         fclose(file);
% 
%     else
%         if fieldType
%             cellCount=N*(N-1)*3+1;
%         else
%             cellCount=N*N;
%         end
%         z0Arr=xlsread(path,1);
%         z0Arr=z0Arr';
%     end
%     
%     if length(z0Arr(1,:))~=cellCount || (fieldType && length(z0Arr(:,1))==4)|| (~fieldType && length(z0Arr(:,1))==5)
%         errordlg('Ошибка. Количество начальных состояний в файле не соответствует заданному числу ячеек, или данные в файле не подходят для инициализации Z0.','modal');
%         setappdata(handles.output,'CurrCA',currCA);
%     else
%         valuesArr=[];
%         idxes=[];
%         colors=[];
%         z0Arr=z0Arr';
%         
%         if fieldType
%             
%             if N==1
%                 value=complex(z0Arr(1,4),z0Arr(1,5));
%                 currCA.Cells=CACell(value, value, [0 1 1], [0 0 0], fieldType, 1);
%                 
%                 N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
%                 setappdata(handles.output,'N1Path',N1Path);
%                 
%                 msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
%                 currCA.N=N;
%                 setappdata(handles.output,'CurrCA',currCA);
%                 fileWasRead = getappdata(handles.output,'FileWasRead');
%                 fileWasRead=true;
%                 setappdata(handles.output,'FileWasRead',fileWasRead);
%                 return;
%             end
%             
%             valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,4),z0Arr(:,5));
%             for i=1:cellCount
%                 idxes=[idxes {z0Arr(i,1:3)}];
%             end
%         else
%             
%             if N==1
%                 value=complex(z0Arr(1,3),z0Arr(1,4));
%                 currCA.Cells=CACell(value, value, [0 1 1], [0 0 0], fieldType, 1);
%                 
%                 N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
%                 setappdata(handles.output,'N1Path',N1Path);
%                 
%                 msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
%                 currCA.N=N;
%                 setappdata(handles.output,'CurrCA',currCA);
%                 fileWasRead = getappdata(handles.output,'FileWasRead');
%                 fileWasRead=true;
%                 setappdata(handles.output,'FileWasRead',fileWasRead);
%                 return;
%             end
%             
%             valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,3),z0Arr(:,4));
%             for i=1:cellCount
%                 idxes=[idxes {[z0Arr(i,1:2) 0]}];
%             end
%         end
%         fileWasRead = getappdata(handles.output,'FileWasRead');
%         fileWasRead=true;
%         setappdata(handles.output,'FileWasRead',fileWasRead);
%         valuesArr=valuesArr';
%         
%         colors=cell(1,cellCount);
%         colors(:)=num2cell([0 0 0],[1 2]);
%         
%         fieldTypeArr=zeros(1,cellCount);
%         fieldTypeArr(:)=fieldType;
%         
%         NArr=zeros(1,cellCount);
%         NArr(:)=N;
%         
%         currCA.Cells=arrayfun(@(value, path, indexes, color, FieldType, N) CACell(value, path, indexes, color, FieldType, N) ,valuesArr,valuesArr,idxes,colors,fieldTypeArr,NArr);
%         
%         msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
%         currCA.N=N;
%         setappdata(handles.output,'CurrCA',currCA);
%     end
    
end

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

modelingTypeParams = strcat(handles.NFieldEdit.String, handles.CalcGroup.SelectedObject.Tag);

switch modelingTypeParams
    case '1SingleCalcRB'

        if isempty(getappdata(handles.output, 'IIteratedObject'))
            [obj] = IteratedPoint();
            [obj] = Initialization(obj, handles);

            if isempty(obj)
                return;
            end

            setappdata(handles.output, 'IIteratedObject', obj);
            visualOptions = PointPathVisualisationOptions.GetSetPointPathVisualisationOptions;
            setappdata(handles.output, 'VisOptions', visualOptions);
        end

    case 'MultipleCalcRB'
        [obj] = IteratedMatrix();
        [obj] = Initialization(obj, handles);

        if isempty(obj)
            return;
        end

        setappdata(handles.output, 'IIteratedObject', obj);
        visualOptions = MatrixVisualisationOptions('jet');
        setappdata(handles.output, 'VisOptions', visualOptions);

    otherwise

end

[calcParams] = ModelingParamsForPath.ModelingParamsInitialization(handles);

if isempty(calcParams)
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
contParms=getappdata(handles.output,'ContParms');
if(contParms.SingleOrMultipleCalc)
    handles.z0Edit.String='0+0i';
    handles.MiuEdit.String='1+0i';
    handles.Miu0Edit.String='0.25i+0';
    if str2double(handles.NFieldEdit.String)~=1
        handles.DistributionTypeMenu.Value=1;
        handles.DistributStartEdit.String='0';
        handles.DistributStepEdit.String='1';
        handles.DistributEndEdit.String='1';
    end
else
    handles.z0Edit.String='0+0i';
    handles.MiuEdit.String='1+0i';
    handles.Miu0Edit.String='0.25i+0';
    handles.DistributionTypeMenu.Value=1;
    handles.DistributStartEdit.String='';
    handles.DistributStepEdit.String='';
    handles.DistributEndEdit.String='';
end
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
currCA=getappdata(handles.output,'CurrCA');
switch get(hObject,'Tag')
    
    case 'DeathLineBordersRB'
        currCA.BordersType=1;
    
    case 'CompletedBordersRB'
        currCA.BordersType=2;
        
    case 'ClosedBordersRB'
        currCA.BordersType=3;
    
end
setappdata(handles.output,'CurrCA',currCA);


% --- Executes when selected object is changed in HexOrientationPanel.
function HexOrientationPanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in HexOrientationPanel 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject,'Tag'),'VertOrientRB')
    ResultsProcessing.GetSetCellOrient(1);
else
    ResultsProcessing.GetSetCellOrient(2);
end


% --- Executes when selected object is changed in FieldTypeGroup.
function FieldTypeGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in FieldTypeGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

currCA=getappdata(handles.output,'CurrCA');
if strcmp(get(hObject,'Tag'),'HexFieldRB')
    currCA.FieldType=1;
    ResultsProcessing.GetSetFieldOrient(1);
    handles.GorOrientRB.Value=1;
    ResultsProcessing.GetSetCellOrient(2);
else
    currCA.FieldType=0;
    ResultsProcessing.GetSetFieldOrient(0);
    handles.GorOrientRB.Value=0;
    handles.VertOrientRB.Value=0;
    ResultsProcessing.GetSetCellOrient(0);
end
setappdata(handles.output,'CurrCA',currCA);


% --- Executes when selected object is changed in CalcGroup.
function CalcGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in CalcGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contParms=getappdata(handles.output,'ContParms');
resProc=getappdata(handles.output,'ResProc');
if strcmp(get(hObject,'Tag'),'SingleCalcRB')
    contParms.SingleOrMultipleCalc=1;
    
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamNameMenu.Enable='off';
    handles.ParamReDeltaEdit.Enable='off';
    handles.ParamImDeltaEdit.Enable='off';
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamImPointsEdit.Enable='off';
    handles.DefaultMultiParmCB.Enable='off';
    
    handles.MaxPeriodEdit.String='';
    handles.ParamReDeltaEdit.String='';
    handles.ParamImDeltaEdit.String='';
    handles.ParamRePointsEdit.String='';
    handles.ParamImPointsEdit.String='';
    
    handles.NFieldEdit.Enable='on';
    handles.SquareFieldRB.Enable='on';
    handles.HexFieldRB.Enable='on';
    handles.GorOrientRB.Enable='on';
    handles.VertOrientRB.Enable='on';
    handles.DefaultCACB.Enable='on';
    handles.CompletedBordersRB.Enable='on';
    handles.DeathLineBordersRB.Enable='on';
    handles.ClosedBordersRB.Enable='on';
    
    handles.DistributionTypeMenu.Enable='on';
    handles.DistributStartEdit.Enable='on';
    handles.DistributStepEdit.Enable='on';
    handles.DistributEndEdit.Enable='on';
    
    handles.Z0SourcePathButton.Enable='on';
    handles.ReadZ0SourceButton.Enable='on';
    
    handles.NeumannRB.Enable = 'on';
    handles.MooreRB.Enable = 'on';
    
else
    contParms.SingleOrMultipleCalc=0;
    
    
    handles.MaxPeriodEdit.Enable='on';
    handles.ParamRePointsEdit.Enable='on';
    handles.ParamNameMenu.Enable='on';
    handles.ParamReDeltaEdit.Enable='on';
    handles.ParamImDeltaEdit.Enable='on';
    handles.ParamRePointsEdit.Enable='on';
    handles.ParamImPointsEdit.Enable='on';
    handles.DefaultMultiParmCB.Enable='on';
    
    handles.NFieldEdit.String='';
    handles.NFieldEdit.Enable='off';
    NFieldEdit_Callback(handles.NFieldEdit, [], handles);
    handles.SquareFieldRB.Enable='off';
    handles.HexFieldRB.Enable='off';
    handles.GorOrientRB.Enable='off';
    handles.VertOrientRB.Enable='off';
    handles.DefaultCACB.Enable='off';
    handles.CompletedBordersRB.Enable='off';
    handles.DeathLineBordersRB.Enable='off';
    handles.ClosedBordersRB.Enable='off';
    
    handles.DistributStartEdit.String='';
    handles.DistributStepEdit.String='';
    handles.DistributEndEdit.String='';
    handles.DistributStartEdit.Enable='off';
    handles.DistributStepEdit.Enable='off';
    handles.DistributEndEdit.Enable='off';
    handles.DistributionTypeMenu.Enable='off';
    
    handles.Z0SourcePathButton.Enable='off';
    handles.ReadZ0SourceButton.Enable='off';
    
    handles.NeumannRB.Enable='off';
    handles.MooreRB.Enable='off';
    
end

if handles.CustomIterFuncCB.Value==1
    handles.BaseImagMenu.Enable='off';
%     handles.LambdaMenu.Enable='off';
    
    handles.UsersBaseImagEdit.Enable='on';
else
    handles.BaseImagMenu.Enable='on';
    handles.LambdaMenu.Enable='on';
    
    handles.UsersBaseImagEdit.Enable='off';
    handles.UsersBaseImagEdit.String='';
end

handles.DefaultCB.Value=0;
setappdata(handles.output,'ContParms',contParms);
setappdata(handles.output,'ResProc',resProc);


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
       


% --- Executes on button press in SaveAllModelParamsB.
function SaveAllModelParamsB_Callback(hObject, eventdata, handles)

if isempty(handles.SaveResPathEdit.String) || ~ischar(handles.SaveResPathEdit.String) || length(handles.SaveResPathEdit.String)==1
     errordlg('Ошибка. Не задана директория сохранения результатов.');
    return;
end
ResProc=getappdata(handles.output,'ResProc');
ResProc.ResPath=handles.SaveResPathEdit.String;
CurrCA=getappdata(handles.output,'CurrCA');
ContParms=getappdata(handles.output,'ContParms');
FileWasRead=getappdata(handles.output,'FileWasRead');
param=[];
if ContParms.SingleOrMultipleCalc
    if FileWasRead
        param=handles.Z0SourcePathEdit.String;
    else
        if CurrCA.N~=1
            distrStart=str2double(handles.DistributStartEdit.String);
            distrStep=str2double(handles.DistributStepEdit.String);
            distrEnd=str2double(handles.DistributEndEdit.String);
            ContParms.ReRangeWindow=real(distrStart):distrStep:real(distrEnd);
            ContParms.ImRangeWindow=imag(distrStart):distrStep:imag(distrEnd);
            param=handles.DistributionTypeMenu.Value;
        else
            param=0;
        end
    end
end

fn = SaveParms(ResProc, CurrCA, ContParms,param);
msgbox(strcat('Параметры моделирования были успешно сохранены в файл ',fn),'modal');

% hObject    handle to SaveAllModelParamsB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function FileMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ReadModelingParmsFrmFile_Callback(hObject, eventdata, handles)
[file,path] = uigetfile('*.txt');
path=strcat(path,file);
if file==0
    return;
end

fileID = fopen(path, 'r');
data = textscan(fileID,'%s');
data=data{1,1};
if cell2mat(data(1))=='1'
    if length(data)~=16 && length(data)~=13
        fclose(fileID);
        errordlg('Ошибка. Неправильный формат данных в файле.','modal');
        return;
    end
    ResProc=getappdata(handles.output,'ResProc');
    CurrCA=getappdata(handles.output,'CurrCA');
    ContParms=getappdata(handles.output,'ContParms');
    ContParms.SingleOrMultipleCalc=1;
    
    handles.SingleCalcRB.Value=1;
    CalcGroup_SelectionChangedFcn(handles.SingleCalcRB, [], handles)
    
    CurrCA.FieldType=str2double(cell2mat(data(2)));
    ResultsProcessing.GetSetFieldOrient(CurrCA.FieldType);
    if CurrCA.FieldType
        handles.HexFieldRB.Value=1;
    else
        handles.SquareFieldRB.Value=1;
    end
    
    CurrCA.BordersType=str2double(cell2mat(data(3)));
    switch  CurrCA.BordersType
        case 1
            handles.DeathLineBordersRB.Value=1;
        case 2
            handles.CompletedBordersRB.Value=1;
        case 3
            handles.ClosedBordersRB.Value=1;
    end
    
    ResultsProcessing.GetSetCellOrient(str2double(cell2mat(data(4))));
    switch ResultsProcessing.GetSetCellOrient
        case 0
            handles.InvisibleRB.Value=1;
        case 1
            handles.VertOrientRB.Value=1;
        case 2
            handles.GorOrientRB.Value=1;
    end
    CurrCA.N=str2double(cell2mat(data(5)));
    handles.NFieldEdit.String=num2str(CurrCA.N);
    
    CurrCA.Base=str2func(cell2mat(data(6)));
    switch func2str(CurrCA.Base)
        case '@(z)(exp(i*z))'
            handles.BaseImagMenu.Value=1;
        case '@(z)(z^2+Miu)'
            handles.BaseImagMenu.Value=2;
        otherwise
            handles.BaseImagMenu.Value=3;
            handles.UsersBaseImagEdit.String=strrep(func2str(CurrCA.Base),'@(z)','');
    end
    BaseImagMenu_Callback(handles.BaseImagMenu, [], handles)
    
    CurrCA.Lambda=str2func(cell2mat(data(7)));
    switch func2str(CurrCA.Lambda)
        case '@(z_k)Miu0+sum(z_k)'
            handles.LambdaMenu.Value=1;
        case '@(z_k)Miu+Miu0*(abs(sum(z_k-Zbase)/(length(z_k))))'
            handles.LambdaMenu.Value=2;
        case '@(z_k,n)Miu+Miu0*abs(sum(arrayfun(@(z_n,o)o*z_n ,z_k,n)))'
            handles.LambdaMenu.Value=3;
        case '@(z_k)Miu+Miu0*(sum(z_k-Zbase)/(length(z_k)))'
            handles.LambdaMenu.Value=4;
    end
    
    CurrCA.Zbase=str2double(cell2mat(data(8)));
    
    CurrCA.Miu0=str2double(cell2mat(data(9)));
    handles.Miu0Edit.String=num2str(CurrCA.Miu0);
    
    CurrCA.Miu=str2double(cell2mat(data(10)));
    handles.MiuEdit.String=num2str(CurrCA.Miu);
    if CurrCA.N~=1
        if length(cell2mat(data(11)))>1
            handles.Z0SourcePathEdit.String=cell2mat(data(11));
            handles.InfValueEdit.String=cell2mat(data(12));
            handles.ConvergValueEdit.String=strrep(cell2mat(data(13)),'1e-','');
        else
            handles.DistributionTypeMenu.Value=str2double(cell2mat(data(11)));
            handles.DistributStartEdit.String=strrep(cell2mat(data(12)),':','');
            handles.DistributStepEdit.String=strrep(cell2mat(data(13)),':','');
            handles.DistributEndEdit.String=strrep(cell2mat(data(14)),':','');
            handles.InfValueEdit.String=cell2mat(data(15));
            handles.ConvergValueEdit.String=strrep(cell2mat(data(16)),'1e-','');
        end
    else
        NFieldEdit_Callback(handles.NFieldEdit, [], handles);
        handles.InfValueEdit.String=cell2mat(data(11));
        handles.ConvergValueEdit.String=strrep(cell2mat(data(12)),'1e-','');
        handles.MaxPeriodEdit.String=cell2mat(data(13));
    end
else
    if cell2mat(data(1))=='0'
        if  length(data)~=12
            fclose(fileID);
            errordlg('Ошибка. Неправильный формат данных в файле.','modal');
            return;
        end
        ResProc=getappdata(handles.output,'ResProc');
        CurrCA=getappdata(handles.output,'CurrCA');
        ContParms=getappdata(handles.output,'ContParms');
        ContParms.SingleOrMultipleCalc=0;
        
        handles.MultipleCalcRB.Value=1;
        CalcGroup_SelectionChangedFcn(handles.MultipleCalcRB, [], handles)
        
        CurrCA.Zbase=str2double(cell2mat(data(2)));
        
        ContParms.ImageFunc=str2func(cell2mat(data(3)));
        
        ContParms.SingleParams=[str2double(cell2mat(data(4))) str2double(cell2mat(data(5)))];
        
        ContParms.WindowParamName=cell2mat(data(6));
        
        WindowStartNum=str2double(strrep(cell2mat(data(7)),':',''));
        WindowStepNum=str2double(strrep(cell2mat(data(8)),':',''));
        WindowEndNum=str2double(strrep(cell2mat(data(9)),':',''));
        
        RealWindow=real(WindowStartNum):real(WindowStepNum):real(WindowEndNum);
        ImagWindow=imag(WindowStartNum):imag(WindowStepNum):imag(WindowEndNum);
        
        DeltaRe=real(WindowEndNum-WindowStartNum);
        DeltaIm=imag(WindowEndNum-WindowStartNum);
        PointsReCount=DeltaRe/real(WindowStepNum);
        PointsImCount=DeltaIm/imag(WindowStepNum);
        
        handles.ParamReDeltaEdit.String=num2str(DeltaRe/2);
        handles.ParamRePointsEdit.String=num2str(PointsReCount);
        
        handles.ParamImDeltaEdit.String=num2str(DeltaIm/2);
        handles.ParamImPointsEdit.String=num2str(PointsImCount);
        
        switch ContParms.WindowParamName
            case 'z0'
                handles.SingleParamNameMenu.Value=1;
                handles.z0Edit.String=num2str(complex(mean(RealWindow),mean(ImagWindow)));
                handles.MiuEdit.String=num2str(ContParms.SingleParams(1));
                handles.Miu0Edit.String=num2str(ContParms.SingleParams(2));
            case 'Miu'
                handles.SingleParamNameMenu.Value=2;
                handles.MiuEdit.String=num2str(complex(mean(RealWindow),mean(ImagWindow)));
                handles.z0Edit.String=num2str(ContParms.SingleParams(1));
                handles.Miu0Edit.String=num2str(ContParms.SingleParams(2));
        end
        
        handles.InfValueEdit.String=cell2mat(data(10));
        handles.ConvergValueEdit.String=strrep(cell2mat(data(11)),'1e-','');
        handles.MaxPeriodEdit.String=cell2mat(data(12));
    else
        errordlg('Ошибка. Неправильный формат данных в файле.','modal');
        return;
    end
end

setappdata(handles.output,'CurrCA',CurrCA);
setappdata(handles.output,'ContParms',ContParms);
setappdata(handles.output,'ResProc',ResProc);
fclose(fileID);

% hObject    handle to ReadModelingParmsFrmFile (see GCBO)
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
CurrCA=getappdata(handles.output,'CurrCA');
ResultsProcessing.GetSetFieldOrient(0);
ResultsProcessing.GetSetCellOrient(0);
CurrCA.FieldType=0;
CurrCA.BordersType=2;
CurrCA.N=5;
handles.NFieldEdit.String='5';
handles.SquareFieldRB.Value=1;
handles.InvisibleRB.Value=1;
handles.CompletedBordersRB.Value=1;
NFieldEdit_Callback(handles.NFieldEdit, eventdata, handles);
setappdata(handles.output,'CurrCA',CurrCA);
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
CurrCA=getappdata(handles.output,'CurrCA');
ContParms=getappdata(handles.output,'ContParms');
if ContParms.SingleOrMultipleCalc
    CurrCA.Base=@(z)(exp(i*z));
    CurrCA.Lambda = @(z_k)Miu0 + sum(z_k);
    if strcmp(handles.LambdaMenu.Enable,'off')
        handles.LambdaMenu.Value=5;
    else
        handles.LambdaMenu.Value=1;
    end
else
    handles.LambdaMenu.Value=5;
    ContParms.ImageFunc=@(z)exp(i*z)*(Miu+Miu0);
end
handles.BaseImagMenu.Value=1;
handles.UsersBaseImagEdit.Enable='off';
handles.UsersBaseImagEdit.String='';

setappdata(handles.output,'CurrCA',CurrCA);
setappdata(handles.output,'ContParms',ContParms);
% hObject    handle to DefaultFuncsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultFuncsCB


% --- Executes on button press in DefaultModelParmCB.
function DefaultModelParmCB_Callback(hObject, eventdata, handles)
ContParms=getappdata(handles.output,'ContParms');
if ContParms.SingleOrMultipleCalc
    handles.IterCountEdit.String='1';
else
    handles.IterCountEdit.String='1000';
    handles.MaxPeriodEdit.String='100';
end
handles.InfValueEdit.String='15';
handles.ConvergValueEdit.String='5';

% hObject    handle to DefaultModelParmCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DefaultModelParmCB


% --- Executes on button press in DefaultSaveParmCB.
function DefaultSaveParmCB_Callback(hObject, eventdata, handles)
ResProc=getappdata(handles.output,'ResProc');
ResProc.isSave=1;
ResProc.isSaveCA=1;
ResProc.isSaveFig=1;
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
currCA=getappdata(handles.output,'CurrCA');
switch get(hObject,'Tag')
    
    case 'NeumannRB'
        currCA.NeighborhoodType=1;
    
    case 'MooreRB'
        currCA.NeighborhoodType=0;
        
end
setappdata(handles.output,'CurrCA',currCA);
% hObject    handle to the selected object in NeighborhoodTemp 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in CustomIterFuncCB.
function CustomIterFuncCB_Callback(hObject, eventdata, handles)

if hObject.Value==1
    handles.BaseImagMenu.Enable='off';
%     handles.LambdaMenu.Enable='off';
    
    handles.UsersBaseImagEdit.Enable='on';
else
    handles.BaseImagMenu.Enable='on';
    
    handles.LambdaMenu.Enable='on';
    if handles.NFieldEdit.String=='1'
%         handles.LambdaMenu.Enable='off';
    end
    
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
currCA=getappdata(handles.output,'CurrCA');
cellWeightsSettings = CellWeightsSettings('UserData', [currCA.FieldType currCA.NeighborhoodType]);

setappdata(cellWeightsSettings, 'NeighborHood', [currCA.FieldType currCA.NeighborhoodType]);
setappdata(handles.output, 'CellWeightsSettings', cellWeightsSettings);

% hObject    handle to SetNeighborWeightMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function VisualizationSettingsMenuItem_Callback(hObject, eventdata, handles)
visualizationSettings = VisualizationSettings;
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
pointPathVisualSettings = PointPathVisualSettings('UserData',handles);
% hObject    handle to PointVisualizationSettingsMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
