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

% Last Modified by GUIDE v2.5 27-May-2020 12:09:22

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

CurrCA = CellularAutomat(0, 2, 1,@(z)(exp(i*z)),@(z_k)Miu0 + sum(z_k), 0, 0, 0);
ContParms = ControlParams(1,1,0,0,' ',@(z)(Miu+z)*exp(i*z));
ResProc = ResultsProcessing(' ',1,1);
ResultsProcessing.GetSetCellOrient(0);
ResultsProcessing.GetSetFieldOrient(0);
FileWasRead=false;

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

SaveParamsButton_Callback(handles.SaveParamsButton, eventdata, handles)

contParms = getappdata(handles.output,'ContParms');
resProc = getappdata(handles.output,'ResProc');

if (~contParms.IsReady2Start) || (((strcmp(resProc.ResPath,' ')) || ~ischar(resProc.ResPath)) && resProc.isSave) %проверка задан ли КА и директория сохранения резов
    errorStr='Ошибка. ';
    
    if(~contParms.IsReady2Start) 
        errorStr='Ошибка. Конфигурация КА не задана полностью или не сохранена. ';
    end
    
    if strcmp(resProc.ResPath,' ') || ~ischar(resProc.ResPath)
        errorStr=strcat(errorStr,'Не задана директория сохранения результатов.');
    end
    setappdata(handles.output,'ResProc',resProc);
    
    errordlg(errorStr,'modal');
else
    if isempty(regexp(handles.IterCountEdit.String,'^\d+$')) || str2double(handles.IterCountEdit.String)<1 || isempty(regexp(handles.InfValueEdit.String,'^\d+$')) || str2double(handles.InfValueEdit.String)<1 || isempty(regexp(handles.ConvergValueEdit.String,'^\d+$')) || str2double(handles.ConvergValueEdit.String)<1 %проверка задано ли число итераций и точность
        errordlg('Ошибка в поле числа итераций и(или) в полях точности вычислений и максимального периода.','modal');
    else
       ControlParams.GetSetPrecisionParms([str2double(handles.InfValueEdit.String) str2double(strcat('1e-',handles.ConvergValueEdit.String))]);
        
       ca = getappdata(handles.output,'CurrCA');
       
       handles.CancelParamsButton.Enable='off';
       if ~contParms.SingleOrMultipleCalc% в случае мультирассчета
           
           if  isempty(regexp(handles.MaxPeriodEdit.String,'^\d+$'))
               errordlg('Ошибка в поле максимального периода.','modal');
               return;
           end
           
           itersCount=str2double(handles.IterCountEdit.String); %число итераций
           contParms.IterCount=itersCount;
           ControlParams.GetSetMaxPeriod(str2double(handles.MaxPeriodEdit.String));
           
           %создание окна и матрицы функций базы
           [WindowParam contParms z_eqArr] = ControlParams.MakeFuncsWithNumsForMultipleCalc(ca,contParms);

           len=size(WindowParam);
           zParam=false;
           Z_Old=[];
           if any(strcmp(contParms.WindowParamName,{'Z0' 'Z' 'z0' 'z'}))
               z_New=WindowParam;
               Z_Old=z_New;
               zParam=true;
           else
               z_New=zeros(len);
               z_New(:)=str2double(handles.z0Edit.String);
               Z_Old=z_New;
           end
           fStepNew=zeros(len);
           Delta=zeros(len);
           
           ZParam=zeros(len);
           ZParam(:)=zParam;
           Z_Old_1=Inf(len);
           if isempty(Z_Old)
               Z_Old=zeros(len);
           end
           FStep=zeros(len);
           ItersCount=zeros(len);
           ItersCount(:)=itersCount;
           Pathes=cell(len);
           
%            profile on;
           %мультирассчет через arrayfun
           [z_New fStepNew Pathes] = arrayfun(@ControlParams.MakeMultipleCalcIter,WindowParam,Z_Old,Z_Old_1,ItersCount,ZParam,z_eqArr);
%            profile viewer;
           
           zRes=z_New;
           PrecisionParms = ControlParams.GetSetPrecisionParms;
           fcodeIndicate=zeros(len);
           Fcode=zeros(len);
           Periods=zeros(len);
           Iters=zeros(len);
           
           [Fcode,Iters,Periods]=arrayfun(@ControlParams.CheckConvergence,Pathes);
           contParms.Periods=Periods;
           contParms.LastIters=Iters;
           fcodeIndicate=find(Fcode==1);
%            if isempty(fcodeIndicate)
%                fcodeIndicate=find(Fcode>=1);
%            end
           posSteps=unique(fStepNew(fcodeIndicate));
           fcodeIndicate=find(Fcode==-1);
           negSteps=unique(fStepNew(fcodeIndicate));
           
           
           chaosCodeIndicate=find(Fcode==2);
           fStepNew(chaosCodeIndicate)=-1;
               
           periodCodeIndicate=find(Fcode==3);
           fStepNew(periodCodeIndicate)=Periods(periodCodeIndicate);
           
           maxPosSteps=zeros(len);
           minNegStep=min(negSteps);
           if ~isempty(posSteps)
               maxPosSteps(:)=max(posSteps);%+(10-mod(max(posSteps),10));
               
               chaosCodeIndicate=find(Fcode==2);
               fStepNew(chaosCodeIndicate)=max(negSteps)+1;
               
               periodCodeIndicate=find(Fcode==3);
               fStepNew(periodCodeIndicate)=maxPosSteps(periodCodeIndicate)+Periods(periodCodeIndicate);
               
               if~isempty(negSteps)
                   clmp = [flipud(gray(max(negSteps)));flipud(winter(floor((max(negSteps)*((max(posSteps)+2)/max(negSteps))))))];%(max(posSteps)-mod(max(posSteps),10))
               else
                   clmp = flipud(winter(floor((max(posSteps)-mod(max(posSteps),10)))));
               end
               
           else
               if~isempty(negSteps)
                   clmp = flipud(gray(max(negSteps)));
               end
           end
           
           if ~isempty(chaosCodeIndicate)
               clmp=[spring(1); clmp];
               Fcode(chaosCodeIndicate)=-1;
           end
           
           if ~isempty(periodCodeIndicate)
               clmp=[clmp; autumn(max(Periods(periodCodeIndicate)))];
               Fcode(periodCodeIndicate)=1;
           end
           
           clrmp = colormap(clmp);
               
           [Re,Im]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           pcolor(Re, Im, (fStepNew.*Fcode));
           
           shading flat;
           clrbr = colorbar;
           if ~isempty(periodCodeIndicate)
               lim = clrbr.Limits;
               ticks=clrbr.Ticks;
               ticksDelta=ticks(2)-ticks(1);
               
               if lim(2)>max(posSteps)+ticksDelta/5
                   ticks=ticks(find(ticks<=max(posSteps)));
                   ticks=[ticks max(posSteps)+ticksDelta/5:ticksDelta/5:lim(2)];
                   clrbr.Ticks=ticks;
                   
                   lables=clrbr.TickLabels';
                   lables=arrayfun(@(num)str2double(cell2mat(num)),lables);
                   newLables=[lables(find(lables<=max(posSteps))) (lables(find(lables>max(posSteps)))-max(posSteps))];
                   clrbr.TickLabels={newLables};
               end
               
           end
           zoom on;
           
           string_title= func2str(contParms.ImageFunc);
           string_title=strrep(string_title,'z','z_{t}');
           string_title=strrep(string_title,'*','\cdot');
           if any(strcmp(contParms.WindowParamName,{'Z0' 'Z' 'z0' 'z'}))
               string_title=strrep(string_title,'@(z_{t})','z_{t+1}=');
               string_title=strrep(string_title,'Miu0','\mu_{0}');
               string_title=strrep(string_title,'Miu','\mu');
               xlabel('Re(z(t))');
               ylabel('Im(z(t))');
               string_title=strcat(string_title,'  \mu=');
               string_title=strcat(string_title,num2str(contParms.SingleParams(1)));
               string_title=strcat(string_title,'  \mu_{0}=');
               string_title=strcat(string_title,num2str(contParms.SingleParams(2)));
           else
               string_title=strrep(string_title,'@(Miu,z_{t},eq)','z_{t+1}=');
               string_title=strrep(string_title,'Miu0','\mu_{0}');
               string_title=strrep(string_title,'Miu','\mu');
               string_title=strcat(string_title,'  z_{0}=');
               string_title=strcat(string_title,num2str(contParms.SingleParams(1)));
               string_title=strcat(string_title,'  \mu_{0}=');
               string_title=strcat(string_title,num2str(contParms.SingleParams(2)));
               xlabelStr='Re(\mu';
               xlabelStr=strcat(xlabelStr,')');
                
               ylabelStr='Im(\mu';
               ylabelStr=strcat(ylabelStr,')');
               
               xlabel(xlabelStr);
               ylabel(ylabelStr);
           end
           string_title=strrep(string_title,'eq','z^{*}');
           
           if any(strcmp(contParms.WindowParamName,{'Z0' 'Z' 'z0' 'z'}))
               string_title=strcat(string_title,'  z^{*}=');
               string_title=strcat(string_title,num2str(ca.Zbase));
           end
           
           title(handles.CAField,strcat('\fontsize{16}',string_title));
%          legend(string_legend);
%          legend('show');
           handles.CAField.FontSize=11;
           
           graphics.Axs=handles.CAField;
           graphics.Clrbr=clrbr;
           graphics.Clrmp=clrmp;
           
           if resProc.isSave
               resProc=SaveRes(resProc,ca,graphics,contParms,zRes);
           end
           handles.ResetButton.Enable='on';
           setappdata(handles.output,'CurrCA',ca);
           setappdata(handles.output,'ContParms',contParms);
           setappdata(handles.output,'ResProc',resProc);
           handles.SaveAllModelParamsB.Enable='on';
           return;
       end
       %подготовка обоих функций
       MakeFuncsWithNums(ca)
       itersCount=str2double(handles.IterCountEdit.String); %число итераций
       
       if length(ca.Cells)==1 %случай когда рассматривается одна ячейка/точка
           hold on;
           N1Path = getappdata(handles.output,'N1Path');
           
           persistent msg;
           persistent fCode;
           if isempty(fCode)
               fCode=2;
           end
           if length(N1Path)==1 && fCode~=2
               msgbox(msg,'modal');
               return;
           else
               msg='';
           end

           len=length(N1Path(1,:));
           N1Path=[N1Path zeros(2,itersCount)];
           for i=1:itersCount
               ca.Cells(1)=CellularAutomat.MakeIter(ca.Cells(1));
               N1Path(1,i+len)=real(ca.Cells(1).zPath(end));
               N1Path(2,i+len)=imag(ca.Cells(1).zPath(end));
               path=complex(N1Path(1,:),N1Path(2,:));
               [fCode iter period] = ControlParams.CheckConvergence(path);
               if fCode~=2
                   str=strcat('Точка ',num2str(ca.Cells(1).z0));
                   switch fCode
                       case -1
                           str=strcat(str,' уходит в бесконечность на итерации:');
                           str=strcat(str,'  ');
                           msg=strcat(str,num2str(iter));
                       case 1
                           str=strcat(str,' сходится к аттрактору на итерации:');
                           str=strcat(str,'  ');
                           msg=strcat(str,num2str(iter));
                       otherwise
                           str=strcat(str,' имеет период: ');
                           strcat(str,period)
                           str=strcat(str,', найденный на итерации:');
                           str=strcat(str,'  ');
                           msg=strcat(str,num2str(iter));
                   end
                   break;
               end
           end
               
           N1Path=N1Path(:,1:iter);
           ms=20;
           clrmp=colormap(jet(length(N1Path)));
           for i=1:length(N1Path)
               plot(N1Path(1,i),N1Path(2,i),'o','MarkerSize', ms,'Color',clrmp(i,:));
               if ms~=2
                   ms=ms-2;
               end
           end
           
           xlabel('Re');
           ylabel('Im');
           
           handles.CAField.YTick=[min(N1Path(2,:)):(abs(max(N1Path(2,:))-min(N1Path(2,:)))/length(N1Path))*0.2*length(N1Path):max(N1Path(2,:))];
           handles.CAField.XTick=[min(N1Path(1,:)):(abs(max(N1Path(1,:))-min(N1Path(1,:)))/length(N1Path))*0.2*length(N1Path):max(N1Path(1,:))];
           
           handles.CAField.XGrid='on';
           handles.CAField.YGrid='on';
           
           clrbr = colorbar('Ticks',[0,0.2,0.4,0.6,0.8,1],...
           'TickLabels',{0,floor(length(N1Path)*0.2),floor(length(N1Path)*0.4),floor(length(N1Path)*0.6),floor(length(N1Path)*0.8),length(N1Path)-1});
           clrbr.Label.String = 'Число итераций';
         
           titleStr='';
           switch func2str(ca.Base)
               case '@(z)(exp(i*z))'
                   titleStr='z_{t+1}=exp(i\cdotz_{t})';
               case '@(z)(z^2+c)'
                   titleStr='z_{t+1}=z^{2}+c';
               otherwise
                   titleStr=func2str(ca.Base);
           end
           
           switch handles.LambdaMenu.Value
               case 1
                   titleStr=strcat(titleStr,' ; \lambda(t)=\mu_{0}');
               case 2
                   titleStr=strcat(titleStr,' ; \lambda(t)=\mu');
               case 3
                   titleStr=strcat(titleStr,' ; \lambda(t)=\mu');
               case 4
                   titleStr=strcat(titleStr,' ; \lambda(t)=\mu');
               case 5
                   titleStr=strcat(titleStr,' ; \lambda=\mu_{0}+\mu');
           end
       
           titleStr=strcat(titleStr,' ; z_{0}=',num2str(ca.Cells(1).z0),' ; \mu=',num2str(ca.Miu),' ; \mu_{0}=',num2str(ca.Miu0));
           
           title(handles.CAField,strcat('\fontsize{16}',titleStr));
           
           handles.CAField.FontSize=10;
           zoom on;
           contParms.IterCount=contParms.IterCount+1;
           contParms.LastIters=length(N1Path);
           contParms.Periods=period;
           
           graphics.Axs=handles.CAField;
           graphics.Clrbr=clrbr;
           graphics.Clrmp=clrmp;
           
           if resProc.isSave
               resProc=SaveRes(resProc,ca,graphics,contParms,N1Path);
           end
           
           handles.ResetButton.Enable='on';
           setappdata(handles.output,'CurrCA',ca);
           setappdata(handles.output,'ContParms',contParms);
           setappdata(handles.output,'N1Path',N1Path);
           setappdata(handles.output,'ResProc',resProc);
           handles.SaveAllModelParamsB.Enable='on';
           if ~isempty(msg)
               msgbox(msg,'modal');
           end
           return;
           
       end
       
       %нахождение соседей каждой ячейки
       for i=1:length(ca.Cells)
           ca.Cells(i)=FindCellsNeighbors(ca, ca.Cells(i));
       end
       
       cellArr=ca.Cells;
       ca_L=length(ca.Cells);
       
       %рассчет поля КА
       for i=1:itersCount
           cellArr=arrayfun(@(cell)CellularAutomat.MakeIter(cell),cellArr);
           
           ca.Cells=cellArr;
           for j=1:ca_L
               cellArr(j)=FindCellsNeighbors(ca, ca.Cells(j));
           end
       end
       
       
       %создание палитры
       colors=colormap([[1 1 1];jet(256);[0 0 0]]);
       
       modulesArr=zeros(1,ca_L);
       zbase=zeros(1,ca_L);
       zbase(:)=ca.Zbase;
       
       PrecisionParms = ControlParams.GetSetPrecisionParms;
       
       modulesArr=arrayfun(@(cell,zbase) log(CellularAutomat.ComplexModule(cell.zPath(end)-zbase))/log(10),ca.Cells,zbase);
       compareArr=-PrecisionParms(1):(2*PrecisionParms(1)+1)/255:PrecisionParms(1);
       
       [modulesArrSrt indxes]=sort(modulesArr);
       
       %присваивание цветов ячейкам в соответсвии с рассчитанной выше величиной
       for i=1:ca_L
           
           ind=find(compareArr>modulesArr(i),1,'first');
           
           if isempty(ind)
               ca.Cells(i).Color=[0 0 0];
           else
               if ind==1 || isnan(modulesArr(i))
                   ca.Cells(i).Color=[1 1 1];
               else
                   ca.Cells(i).Color=colors(ind-1,:);
               end
           end
       end
       
       %отрисовка поля
       arrayfun(@(cell) ResultsProcessing.DrawCell(cell),ca.Cells);
       
       colors=arrayfun(@(cell) {cell.Color},ca.Cells(indxes));
       colors=cell2mat(colors');
       
       if any(modulesArr>PrecisionParms(1)) || any(isinf(modulesArr))|| any(isnan(modulesArr))
           colors=[[1 1 1];colors];
       end
       
       if any(modulesArr<-PrecisionParms(1))
           colors=[colors;[0 0 0]];
       end
       
       clrmp = colormap(colors);
       
       modulesArr=sort(modulesArr);
       clrbr = colorbar;
       
       indx=modulesArr<PrecisionParms(1);
       finitModulesArr=modulesArr(find(indx));
       
       indx=~isnan(finitModulesArr);
       finitModulesArr=finitModulesArr(find(indx));
       
       if length(finitModulesArr) >= 2
           minMod=min(finitModulesArr);
           maxMod=max(finitModulesArr);
           NotInfModArrLen=length(finitModulesArr);
           InfModArrLen=length(modulesArr)-NotInfModArrLen;
           
           k=abs(1-InfModArrLen/NotInfModArrLen);
           if InfModArrLen>NotInfModArrLen
               k=NotInfModArrLen/length(modulesArr);
           end
           
           newLables=minMod:((maxMod-minMod)/(11*k)):maxMod;
           l = length(newLables);
           if InfModArrLen~=0
               infLablesPart=zeros(1,11-length(newLables));
               infLablesPart(:)=PrecisionParms(1);
               newLables=[newLables infLablesPart];
           end
           
           clrbr.TickLabels={newLables};
       else
           clrbr.TickLabels={''};
       end
       clrbr.Label.String='\fontsize{16}log_{10}(\midz_{t+1}\mid-\midz^{*}\mid)';
       
       titleStr='';
       switch func2str(ca.Base)
           case '@(z)(exp(i*z))'
               titleStr='z_{t+1}=exp(i\cdotz_{t})';
           case '@(z)(z^2+c)'
               titleStr='z_{t+1}=z^{2}+c';
           otherwise
               titleStr=func2str(ca.Base);
       end
       
       switch handles.LambdaMenu.Value
           case 1
               titleStr=strcat(titleStr,' ; \lambda(t)=\mu_{0}+\Sigma_{k=1}^{n}\mu_{k}\cdotz_{k}^{t}');
           case 2
               titleStr=strcat(titleStr,' ; \lambda(t)=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu)\mid');
           case 3
               titleStr=strcat(titleStr,' ; \lambda(t)=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}(-1^{k})\cdotz_{k}^{t}\mid');
           case 4
               titleStr=strcat(titleStr,' ; \lambda(t)=\mu+\mu_{0}\cdot( (1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu) )');
           case 5
               titleStr=strcat(titleStr,' ; \lambda=\mu_{0}+\mu');
               
       end
       
       titleStr=strcat(titleStr,' ; \mu_{0}=',num2str(ca.Miu0),' ; \mu=',num2str(ca.Miu));
       
       title(handles.CAField,strcat('\fontsize{16}',titleStr));
       
       graphics.Axs=handles.CAField;
       graphics.Clrbr=clrbr;
       graphics.Clrmp=clrmp;
       
       if resProc.isSave
           resProc=SaveRes(resProc,ca,graphics,contParms,[]);
       end
      
       setappdata(handles.output,'CurrCA',ca);
       contParms.IterCount=contParms.IterCount+1;
       setappdata(handles.output,'ContParms',contParms);
       setappdata(handles.output,'ResProc',resProc);
       handles.ResetButton.Enable='on';
       handles.SaveAllModelParamsB.Enable='on';
    end
end


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
            contParms.ImageFunc=@(z)(Miu+z)*exp(i*z);
        end
    case 2
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)Miu + Miu0*(abs(sum(z_k-Zbase)/(length(z_k))));
        else
            contParms.ImageFunc=@(z)(Miu+(Miu0*abs(z-(eq))))*exp(i*z);
        end
    case 3
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k,n)Miu + Miu0*abs(sum(arrayfun(@(z_n,o)o*z_n ,z_k,n)));
        else
            contParms.ImageFunc=@(z)(Miu+(Miu0*abs(z)))*exp(i*z);
        end
    case 4
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)Miu + Miu0*(sum(z_k-Zbase)/(length(z_k)));
        else
            contParms.ImageFunc=@(z)(Miu+(Miu0*(z-(eq))))*exp(i*z);
        end
    case 5
        if contParms.SingleOrMultipleCalc
            currCA.Lambda = @(z_k)(Miu + Miu0);
        else
            contParms.ImageFunc=@(z)(Miu+Miu0)*exp(i*z);
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
axis image
set(gca,'xtick',[])
set(gca,'ytick',[])

ca = getappdata(handles.output,'CurrCA');
contParms = getappdata(handles.output,'ContParms');
FileWasRead=getappdata(handles.output,'FileWasRead');
N1Path = getappdata(handles.output,'N1Path');

ca = CellularAutomat(ca.FieldType,ca.BordersType, ca.N ,ca.Base,ca.Lambda, ca.Zbase, ca.Miu0, ca.Miu);

contParms.IsReady2Start=false;

N1Path=[];

FileWasRead=false;

setappdata(handles.output,'CurrCA',ca);
setappdata(handles.output,'ContParms',contParms);
setappdata(handles.output,'FileWasRead',FileWasRead);
setappdata(handles.output,'N1Path',N1Path);


handles.SaveAllModelParamsB.Enable='off';
if contParms.SingleOrMultipleCalc
    
    
    handles.MaxPeriodEdit.Enable='off';
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamNameMenu.Enable='off';
    handles.ParamReDeltaEdit.Enable='off';
    handles.ParamImDeltaEdit.Enable='off';
    handles.ParamRePointsEdit.Enable='off';
    handles.ParamImPointsEdit.Enable='off';
    handles.DefaultMultiParmCB.Enable='off';
    
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
    
    handles.BaseImagMenu.Enable='on';
    handles.UsersBaseImagEdit.Enable='on';
    handles.LambdaMenu.Enable='on';
    handles.DefaultFuncsCB.Enable='on';
    
    handles.z0Edit.Enable='on';
    handles.MiuEdit.Enable='on';
    handles.Miu0Edit.Enable='on';
    handles.DefaultCB.Enable='on';
    handles.CountBaseZButton.Enable='on';
    
    
    handles.SingleCalcRB.Enable='on';
    handles.MultipleCalcRB.Enable='on';
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
resProc=getappdata(handles.output,'ResProc');
resProc.ResPath = uigetdir('C:\');
setappdata(handles.output,'ResProc',resProc);
handles.SaveResPathEdit.String=resProc.ResPath;

% hObject    handle to SaveResPathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in SaveCellsCB.
function SaveCellsCB_Callback(hObject, eventdata, handles)
resProc=getappdata(handles.output,'ResProc');
if hObject.Value==1
    
    resProc.isSave=1;
    resProc.isSaveCA=1;
    
    set(handles.FileTypeMenu,'Enable','on');
else
    if ~resProc.isSaveFig
        resProc.isSave=0;
    end
    resProc.isSaveCA=0;
    
    set(handles.FileTypeMenu,'Enable','off');
end
setappdata(handles.output,'ResProc',resProc);
% hObject    handle to SaveCellsCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveCellsCB


% --- Executes on button press in SaveFigCB.
function SaveFigCB_Callback(hObject, eventdata, handles)
resProc=getappdata(handles.output,'ResProc');
if hObject.Value==1
    resProc.isSave=1;
    resProc.isSaveFig=1;
    
    set(handles.FigTypeMenu,'Enable','on');
else
    if ~resProc.isSaveCA
        resProc.isSave=0;
    end
    resProc.isSaveFig=0;
    
    set(handles.FigTypeMenu,'Enable','off');
end
setappdata(handles.output,'ResProc',resProc);
% hObject    handle to SaveFigCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SaveFigCB


% --- Executes on selection change in FileTypeMenu.
function FileTypeMenu_Callback(hObject, eventdata, handles)
resProc=getappdata(handles.output,'ResProc');

switch hObject.Value
    case 1
        resProc.CellsValuesFileFormat=1;
    case 2
        resProc.CellsValuesFileFormat=0;
end

setappdata(handles.output,'ResProc',resProc);
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
resProc=getappdata(handles.output,'ResProc');

switch hObject.Value
    case 1
        resProc.FigureFileFormat=1;
    case 2
        resProc.FigureFileFormat=2;
    case 3
        resProc.FigureFileFormat=3;
end

setappdata(handles.output,'ResProc',resProc);
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
    cellCount=0;
    fieldType= currCA.FieldType;
    z0Arr=[];

    
    if(regexp(path,'\.txt$'))
        if fieldType
            if N~=1
                cellCount=N*(N-1)*3+1;
            else
                cellCount=1;
            end
            z0Size=[5 cellCount];
            formatSpec = '%d %d %d %f %f\n';
        else
            cellCount=N*N;
            z0Size=[4 cellCount];
            formatSpec = '%d %d %f %f\n';
        end
        file = fopen(path, 'r');
        z0Arr = fscanf(file, formatSpec,z0Size);
        fclose(file);

    else
        if fieldType
            cellCount=N*(N-1)*3+1;
        else
            cellCount=N*N;
        end
        z0Arr=xlsread(path,1);
        z0Arr=z0Arr';
    end
    
    if length(z0Arr(1,:))~=cellCount || (fieldType && length(z0Arr(:,1))==4)|| (~fieldType && length(z0Arr(:,1))==5)
        errordlg('Ошибка. Количество начальных состояний в файле не соответствует заданному числу ячеек, или данные в файле не подходят для инициализации Z0.','modal');
        setappdata(handles.output,'CurrCA',currCA);
    else
        valuesArr=[];
        idxes=[];
        colors=[];
        z0Arr=z0Arr';
        
        if fieldType
            
            if N==1
                value=complex(z0Arr(1,4),z0Arr(1,5));
                currCA.Cells=CACell(value, value, [0 1 1], [0 0 0], fieldType, 1);
                
                N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
                setappdata(handles.output,'N1Path',N1Path);
                
                msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
                currCA.N=N;
                setappdata(handles.output,'CurrCA',currCA);
                fileWasRead = getappdata(handles.output,'FileWasRead');
                fileWasRead=true;
                setappdata(handles.output,'FileWasRead',fileWasRead);
                return;
            end
            
            valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,4),z0Arr(:,5));
            for i=1:cellCount
                idxes=[idxes {z0Arr(i,1:3)}];
            end
        else
            
            if N==1
                value=complex(z0Arr(1,3),z0Arr(1,4));
                currCA.Cells=CACell(value, value, [0 1 1], [0 0 0], fieldType, 1);
                
                N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
                setappdata(handles.output,'N1Path',N1Path);
                
                msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
                currCA.N=N;
                setappdata(handles.output,'CurrCA',currCA);
                fileWasRead = getappdata(handles.output,'FileWasRead');
                fileWasRead=true;
                setappdata(handles.output,'FileWasRead',fileWasRead);
                return;
            end
            
            valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,3),z0Arr(:,4));
            for i=1:cellCount
                idxes=[idxes {[z0Arr(i,1:2) 0]}];
            end
        end
        fileWasRead = getappdata(handles.output,'FileWasRead');
        fileWasRead=true;
        setappdata(handles.output,'FileWasRead',fileWasRead);
        valuesArr=valuesArr';
        
        colors=cell(1,cellCount);
        colors(:)=num2cell([0 0 0],[1 2]);
        
        fieldTypeArr=zeros(1,cellCount);
        fieldTypeArr(:)=fieldType;
        
        NArr=zeros(1,cellCount);
        NArr(:)=N;
        
        currCA.Cells=arrayfun(@(value, path, indexes, color, FieldType, N) CACell(value, path, indexes, color, FieldType, N) ,valuesArr,valuesArr,idxes,colors,fieldTypeArr,NArr);
        
        msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
        currCA.N=N;
        setappdata(handles.output,'CurrCA',currCA);
    end
    
%     if length(z0Arr)<cellCount
%         errordlg('Ошибка. Количество начальных состояний в файле меньше количества ячеек.','modal');
%         setappdata(handles.output,'CurrCA',currCA);
%     else
%         z0Arr=z0Arr(1,1:cellCount);
%         g=1;
%         if fieldType
%             for k=1:3
%                 for j = 0:N-1
%                     for i = 1:N-1
%                         cell=CACell(z0Arr(g),z0Arr(g),[i,j,k],[0 0 0],fieldType,N);
%                         currCA.Cells=[currCA.Cells cell];
%                         g=g+1;
%                     end
%                 end
%             end
%         else
%             for x=0:N-1
%                 for y=0:N-1     
%                     cell=CACell(z0Arr(g),z0Arr(g),[x,y,0],[0 0 0],fieldType,N);
%                     currCA.Cells=[currCA.Cells cell];
%                     g=g+1;
%                 end
%             end
%         end
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
if(isempty(regexp(handles.MiuEdit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
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
    
    handles.BaseZEdit.String=num2str(currCA.Zbase);
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
error=false;
errorStr='Ошибки в текстовых полях: ';
contParms = getappdata(handles.output,'ContParms');

if contParms.SingleOrMultipleCalc
    Nerror=false;
    if(isempty(regexp(handles.NFieldEdit.String,'^\d+$')))
        Nerror=true;
        error=true;
        errorStr=strcat(errorStr,'N, ');
    end
else
%     ParamNameerror=false;
%     if handles.ParamNameMenu.Value == handles.SingleParamNameMenu.Value
%         error=true;
%         ParamNameerror=true;
%         errorStr=strcat(errorStr,'совпадение одиночного и мульти-параметров, ');
%     end
%     newN=0;
%     ParamCellCount=0;
%     
%     if(isempty(regexp(handles.SingleParamValueEdit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
%         error=true;
%         errorStr=strcat(errorStr,'Одиночный параметр, ');
%     end
end

%regexp('-0.58755665+5.45i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]?\d+(?<dot>\.)?(?(dot)\d+|)(?(3)|i))?$')
numErrors=[0 0 0];
num=0;
if(isempty(regexp(handles.MiuEdit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
    error=true;
    errorStr=strcat(errorStr,'Мю, ');
    numErrors(2)=true;
end

if(isempty(regexp(handles.Miu0Edit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
    error=true;
    errorStr=strcat(errorStr,'Мю0, ');
    numErrors(3)=true;
end

if(isempty(regexp(handles.z0Edit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
    numErrors(1)=true;
end



currCA=getappdata(handles.output,'CurrCA');
fileWasRead = getappdata(handles.output,'FileWasRead');
if isempty(currCA.Cells) || (~contParms.IsReady2Start && ~fileWasRead)
    
    if contParms.SingleOrMultipleCalc
        DistributStart=str2double(handles.DistributStartEdit.String);
        DistributStep=str2double(handles.DistributStepEdit.String);
        DistributEnd=str2double(handles.DistributEndEdit.String);
    
        if (isnan(DistributStart) || isreal(DistributStart) || isempty(regexp(handles.DistributStepEdit.String,'^\d+(\.?)(?(1)\d+|)$')) || isnan(DistributEnd) || isreal(DistributEnd)) && str2double(handles.NFieldEdit.String)~=1
            error=true;
            regexprep(errorStr,', $','. ');
            errorStr=strcat(errorStr,' Не задана начальная конфигурация КА. Неправильный формат диапазона значений Z0. Задайте диапазон Z0 или загрузите данные из файла. ');
        else
            if ~Nerror
                ReRange=real(DistributStart):DistributStep:real(DistributEnd);
                ImRange=imag(DistributStart):DistributStep:imag(DistributEnd);
                rangeError=false;
                rangeErrorStr='';
                
                if str2double(handles.NFieldEdit.String)==1 && ~isempty(handles.z0Edit.String)
                    if(isempty(regexp(handles.z0Edit.String,'^[-\+]?\d+(\.)?(?(1)\d+|)(i)?[-\+]?\d+(\.)?(?(4)\d+|)(?(3)|i)$')))
                        error=true;
                        rangeError=true;
                        errorStr=strcat(errorStr,'z0, ');
                    else
                        ReRange=real(str2double(handles.z0Edit.String));
                        ImRange=imag(str2double(handles.z0Edit.String));
                    end
                end
                
                if ~rangeError
                    [currCA,rangeError,rangeErrorStr] = Initializations.Z0RangeInit(ReRange, ImRange,str2double(handles.NFieldEdit.String),currCA,handles.DistributionTypeMenu.Value);
                end
                
                if rangeError
                    error=true;
                    regexprep(errorStr,', $','. ');
                    errorStr=strcat(errorStr,rangeErrorStr);
                else
                    if ~error
                        paramStart=complex(ReRange(1),ImRange(1));
                        if str2double(handles.NFieldEdit.String)~=1
                            paramStep=complex(ReRange(2)-ReRange(1),ImRange(2)-ImRange(1));
                        else
                            paramStep=1;
                        end
                        paramEnd=complex(ReRange(end),ImRange(end));
                        paramStartSrt=strcat(num2str(paramStart),' :');
                        paramEndSrt=strcat(' :',num2str(paramEnd));
                        paramSrt=strcat(paramStartSrt,num2str(paramStep));
                        paramSrt=strcat(paramSrt,paramEndSrt);
                        paramSrt=strcat('  ',paramSrt);
%                         msgbox(strcat('Начальная конфигурация КА была успешно задана диапазоном',paramSrt),'modal');
                    end
                    
                end
                
            end
            
        end
        
    else
        if isempty(regexp(handles.ParamReDeltaEdit.String,'^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamImDeltaEdit.String,'^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamRePointsEdit.String,'^\d+$')) || isempty(regexp(handles.ParamImPointsEdit.String,'^\d+$'))
            error=true;
            regexprep(errorStr,', $','. ');
            errorStr=strcat(errorStr,' Неправильный формат диапазона параметра "окна". ');
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
                currCA.N=2;
            else
                errorStr=strcat(errorStr,'одиночный параметр мультирасчета, ');
                error=true;
            end
            
            if ~error
                contParms.ReRangeWindow=ReRange;
                contParms.ImRangeWindow=ImRange;
                contParms.WindowCenterValue=complex(ReCenter,ImCenter);
                contParms.SingleParams=[param1 param2];
%                 msgbox('Начальная конфигурация КА была успешно задана диапазоном параметра "окна".','modal');
            end
        end
        
    end
    
end

if error
    contParms.IsReady2Start=false;
    regexprep(errorStr,', $','.');
    errordlg(errorStr,'modal');
else
    
    if contParms.SingleOrMultipleCalc
        currCA.N=str2double(handles.NFieldEdit.String);
    else
        switch handles.ParamNameMenu.Value
            case 1
                contParms.WindowParamName='z0';
            case 2
                contParms.WindowParamName='Miu';
        end
    end
    
    if currCA.N==1
        N1Path=[real(currCA.Cells(1).z0);imag(currCA.Cells(1).z0)];
        setappdata(handles.output,'N1Path',N1Path);
    end
    
    currCA.Miu=str2double(handles.MiuEdit.String);
    
    if num~=2
        MiuStr=handles.MiuEdit.String;
        MiuStr=strcat('(',MiuStr);
        MiuStr=strcat(MiuStr,')');
        FbaseStr=strrep(func2str(currCA.Base),'Miu',MiuStr);
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
        handles.BaseZEdit.String=num2str(currCA.Zbase);
    end
    
    currCA.Miu0=str2double(handles.Miu0Edit.String);
    
    setappdata(handles.output,'CurrCA',currCA);
    
    contParms.IsReady2Start=true;
    setappdata(handles.output,'ContParms',contParms);
    

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
    
end
% hObject    handle to SaveParamsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% % --- Executes on button press in CancelParamsButton.
% function CancelParamsButton_Callback(hObject, eventdata, handles)
% % handles.MiuReEdit.Enable='on';
% % handles.MiuImEdit.Enable='on';
% % handles.Miu0ReEdit.Enable='on';
% % handles.Miu0ImEdit.Enable='on';
% handles.NFieldEdit.Enable='on';
% handles.BaseZEdit.Enable='on';
% handles.BaseImagMenu.Enable='on';
% handles.UsersBaseImagEdit.Enable='on';
% handles.DefaultCB.Enable='on';
% handles.SquareFieldRB.Enable='on';
% handles.HexFieldRB.Enable='on';
% handles.GorOrientRB.Enable='on';
% handles.VertOrientRB.Enable='on';
% handles.CompletedBordersRB.Enable='on';
% handles.DeathLineBordersRB.Enable='on';
% handles.ClosedBordersRB.Enable='on';
% handles.BaseImagMenu.Enable='on';
% handles.UsersBaseImagEdit.Enable='on';
% handles.LambdaMenu.Enable='on';
% handles.Z0SourcePathButton='on';
% handles.ReadZ0SourceButton='on';
% handles.SaveParamsButton.Enable='on';
% handles.SingleCalcRB.Enable='on';
% handles.MultipleCalcRB.Enable='on';
% 
% contParms = getappdata(handles.output,'ContParms');
% contParms.IsReady2Start=false;
% setappdata(handles.output,'ContParms',contParms);
% hObject    handle to CancelParamsButton (see GCBO)
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
    handles.DistributionTypeMenu.Value=1;
    handles.DistributStartEdit.String='-3-0.465i';
    handles.DistributStepEdit.String='0.001';
    handles.DistributEndEdit.String='-2.7-0.165i';
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

currCA=getappdata(handles.output,'CurrCA');
switch hObject.Value
    
    case 1
        currCA.Base=@(z)(exp(i*z));
        handles.UsersBaseImagEdit.String='';
        
    case 2
        currCA.Base=@(z)(z^2+c);
        handles.UsersBaseImagEdit.String='';
        
    case 3
        userFuncStr=handles.UsersBaseImagEdit.String;
        if ~isempty(regexp(userFuncStr,'[^\*\^\+-\/\.\(\)\dczie(exp)(pi)]','ONCE')) || isempty(userFuncStr)
            
            errordlg('Ошибка. Недопустимый формат пользовательской функции.','modal');
            hObject.Value=1;
            currCA.Base=@(z)(exp(i*z));
            handles.UsersBaseImagEdit.String='';
        else
            funcStr=strcat('@(z)',userFuncStr);
            currCA.Base=str2func(funcStr);
        end
end
setappdata(handles.output,'CurrCA',currCA);
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
    
    handles.MaxPeriodEdit.Enable='off';
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
        distrStart=str2double(handles.DistributStartEdit.String);
        distrStep=str2double(handles.DistributStepEdit.String);
        distrEnd=str2double(handles.DistributEndEdit.String);
        ContParms.ReRangeWindow=real(distrStart):distrStep:real(distrEnd);
        ContParms.ImRangeWindow=imag(distrStart):distrStep:imag(distrEnd);
        param=handles.DistributionTypeMenu.Value;
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
        case '@(z)Miu*(exp(i*z))'
            handles.BaseImagMenu.Value=1;
        case '@(z)(z^2+c)'
            handles.BaseImagMenu.Value=2;
        otherwise
            handles.UsersBaseImagEdit.String=strrep(func2str(CurrCA.Base),'@(z)','');
    end
    
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
    handles.BaseZEdit.String=num2str(CurrCA.Zbase);
    
    CurrCA.Miu0=str2double(cell2mat(data(9)));
    handles.Miu0Edit.String=num2str(CurrCA.Miu0);
    
    CurrCA.Miu=str2double(cell2mat(data(10)));
    handles.MiuEdit.String=num2str(CurrCA.Miu);
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
        handles.BaseZEdit.String=num2str(CurrCA.Zbase);
        
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
else
    ContParms.ImageFunc=@(z)(Miu+z)*exp(i*z);
end
handles.BaseImagMenu.Value=1;
handles.UsersBaseImagEdit.String='';
handles.LambdaMenu.Value=1;
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
