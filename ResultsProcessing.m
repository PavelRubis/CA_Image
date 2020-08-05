classdef ResultsProcessing
   %класс обработки результатов моделирования
   properties
       isSave logical =0% сохраняем ли результаты
       isSaveCA logical =0% сохраняем ли КА
       isSaveFig logical =0% сохраняем ли фигуру
       ResPath (1,:) char %путь к сохраняемым результатам
       CellsValuesFileFormat logical % формат файла для записи значений ячеек (1-txt,0-xls)
       FigureFileFormat {mustBeInteger, mustBeInRange(FigureFileFormat,[1,3])}% формат картинки поля
   end
   
   methods
       %конструктор
       function obj = ResultsProcessing(resPath, cellsValuesFileFormat, figureFileFormat)
           if nargin
               obj.ResPath=resPath;
               obj.CellsValuesFileFormat=cellsValuesFileFormat;
               obj.FigureFileFormat=figureFileFormat;
           end
       end
       
       %метод сохранения результатов
       function resproc = SaveRes(obj, ca, graphics,contParms,Res)
           
           if contParms.SingleOrMultipleCalc 
               if obj.isSaveCA
                   if length(ca.Cells)==1
                       ConfFileName=strcat('\Modeling-',datestr(clock));
                       ConfFileName=strcat(ConfFileName,'-N-1-Path.txt');
                       ConfFileName=strrep(ConfFileName,':','-');
                       ConfFileName=strcat(obj.ResPath,ConfFileName);
                   
                       fileID = fopen(ConfFileName, 'w');
                       fprintf(fileID, strcat('Одиночное Моделирование от-',datestr(clock)));
                       fprintf(fileID, '\n\nРебро N=1');
                       fprintf(fileID, strcat('\nБазовое отображение: ',func2str(ca.Base)));
                       
                       customImagCheck=isempty(ControlParams.GetSetCustomImag);
                       if customImagCheck
                           fprintf(fileID, strcat('\nФактор лямбда: ',func2str(ca.Lambda)));
                       else
                           if ControlParams.GetSetCustomImag
                               fprintf(fileID, '\nФактор лямбда: 1');
                           else
                               fprintf(fileID, strcat('\nФактор лямбда: ',func2str(ca.Lambda)));
                           end
                       end
                       
                       PrecisionParms = ControlParams.GetSetPrecisionParms;
                       
                       fprintf(fileID, strcat('\n\n\nМаксимальный период=',num2str(ControlParams.GetSetMaxPeriod),';Порог бесконечности=',num2str(10^PrecisionParms(1)),';Порог сходимости=',num2str(PrecisionParms(2))));
                       fprintf(fileID, strcat('\nz0=',num2str(ca.Cells(1).z0),'\nmu=',num2str(ca.Miu),'\nmu0=',num2str(ca.Miu0)));
                       
                       fprintf(fileID, '\nКоличество итераций T=%f\n',length(Res)-1);
                       
                       switch contParms.Periods
                           case 0
                               fprintf(fileID, '\n\nИтог: уходящая в бесконечность траектория\n');
                           case 1
                               fprintf(fileID, '\n\nИтог: сходящаяся к аттрактору траектория\n');
                           case inf
                               fprintf(fileID, '\n\nИтог: хаотичная траектория\n');
                           otherwise
                               fprintf(fileID, strcat('\n\nИтог: траектория с периодом: ',num2str(contParms.Periods),'\n'));
                       end
                       
                       fprintf(fileID,'Re	Im	Fate	length\n');
                       fclose(fileID);
                       dlmwrite(ConfFileName,[real(ca.Cells(1).zPath(1)) imag(ca.Cells(1).zPath(end)) contParms.Periods contParms.LastIters],'-append','delimiter','\t');
                       
                       fileID = fopen(ConfFileName, 'a');
                       fprintf(fileID, '\n\nТраектория:\n');
                       fclose(fileID);
                       iters=1:length(Res(1,:));
                       iters=iters';
                       Res=Res';
                       Res=[iters Res];
                       dlmwrite(ConfFileName,'iter	Re	Im','-append','delimiter','');
                       dlmwrite(ConfFileName,Res,'-append','delimiter','\t','precision',7);
                   else
                       ConfFileName=strcat('\Modeling-',datestr(clock));
                       ConfFileName=strcat(ConfFileName,'-CA.txt');
                       ConfFileName=strrep(ConfFileName,':','-');
                       ConfFileName=strcat(obj.ResPath,ConfFileName);
                   
                       fileID = fopen(ConfFileName, 'w');
                       fprintf(fileID, strcat('Одиночное Моделирование от-',datestr(clock)));
                       fprintf(fileID, '\n\nКонфигурация КА:\n\n');
               
                       if ca.FieldType
                           fprintf(fileID, 'Тип решетки поля: гексагональное\n');
                       else
                           fprintf(fileID, 'Тип решетки поля: квадратное\n');
                       end
                       
                       switch ca.BordersType
                           case 1
                               fprintf(fileID, 'Тип границ поля: "линия смерти"\n');
                           case 2
                               fprintf(fileID, 'Тип границ поля: замыкание границ\n');
                           case 3
                               fprintf(fileID, 'Тип границ поля: закрытые границы\n');
                       end
                       
                       fprintf(fileID, 'Ребро N=%d\n',ca.N);
               
                       fprintf(fileID, strcat('Базовое отображение: ',func2str(ca.Base)));
                       fprintf(fileID, strcat('\nЗависимость параметра лямбда: ',func2str(ca.Lambda)));
                       fprintf(fileID, '\nПараметр Мю=%f %fi\n',real(ca.Miu),imag(ca.Miu));
                       fprintf(fileID, 'Параметр Мю0=%f %fi\n',real(ca.Miu0),imag(ca.Miu0));
                       fprintf(fileID, 'Итерация Iter=%f\n\n\n',contParms.IterCount-1);
                       fprintf(fileID, 'Значения ячеек:\n\n');
                       fclose(fileID);
               
                       Z=[];
                       for j=1:length(ca.Cells)
                           idx=cast(ca.Cells(j).Indexes,'double');
                           Z=[Z ; [idx real(ca.Cells(j).zPath(end)) imag(ca.Cells(j).zPath(end))]];
                       end
                       dlmwrite(ConfFileName,'x	y	k	Re	Im','-append','delimiter','');
                       dlmwrite(ConfFileName,Z,'-append','delimiter','\t','precision',7);
                   end
               end
               
           else
               if obj.isSaveCA
                   ConfFileName=strcat('\MultiCalc-',datestr(clock));
                   ConfFileName=strcat(ConfFileName,'.txt');
                   ConfFileName=strrep(ConfFileName,':','-');
                   ConfFileName=strcat(obj.ResPath,ConfFileName);
                   
                   fileID = fopen(ConfFileName, 'w');
                   fprintf(fileID, strcat('Множественное Моделирование от- ',datestr(clock)));
                   
                   fprintf(fileID, strcat('\n\nОтображение: ',func2str(contParms.ImageFunc)));
                       
%                    customImagCheck=isempty(ControlParams.GetSetCustomImag);
%                    if customImagCheck
%                        fprintf(fileID, strcat('\nФактор лямбда: ',func2str(ca.Lambda)));
%                    else
%                        if ControlParams.GetSetCustomImag
%                            fprintf(fileID, '\nФактор лямбда: 1');
%                        else
%                            fprintf(fileID, strcat('\nФактор лямбда: ',func2str(ca.Lambda)));
%                        end
%                    end
                   
                   PrecisionParms = ControlParams.GetSetPrecisionParms;
                       
                   fprintf(fileID, strcat('\n\n\nМаксимальный период=',num2str(ControlParams.GetSetMaxPeriod),'\nПорог бесконечности=',num2str(10^PrecisionParms(1)),'\nПорог сходимости=',num2str(PrecisionParms(2))));
                   
                   switch contParms.WindowParamName
                       case 'z0'
                           fprintf(fileID, strcat('\nz0=',num2str(complex(mean(contParms.ReRangeWindow),mean(contParms.ImRangeWindow))),'\nmu=',num2str(ca.Miu),'\nmu0=',num2str(ca.Miu0)));
                       otherwise
                           fprintf(fileID, strcat('\nz0=',num2str(contParms.SingleParams(1)),'\nmu=',num2str(ca.Miu),'\nmu0=',num2str(ca.Miu0)));
                   end    
                   
                   fprintf(fileID, '\nКоличество итераций T=%f\n',length(Res)-1);
                       
                   fprintf(fileID, strcat('\nПараметр окна: ',contParms.WindowParamName));
                   fprintf(fileID, '\nДиапазон параметра окна: ');
                   
                   paramStart=complex(contParms.ReRangeWindow(1),contParms.ImRangeWindow(1));
                   paramStep=complex(contParms.ReRangeWindow(2)-contParms.ReRangeWindow(1),contParms.ImRangeWindow(2)-contParms.ImRangeWindow(1));
                   paramEnd=complex(contParms.ReRangeWindow(end),contParms.ImRangeWindow(end));
                       
                   paramStartSrt=strcat(num2str(paramStart),' : ');
                   paramEndSrt=strcat(' : ',num2str(paramEnd));
                   paramSrt=strcat(paramStartSrt,num2str(paramStep));
                   paramSrt=strcat(paramSrt,paramEndSrt);
                   fprintf(fileID,strcat(paramSrt,'\n\n'));
                   fclose(fileID);
                   dlmwrite(ConfFileName,'Re	Im	Fate	length','-append','delimiter','');
                  
                   [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
                   WindowParam=X+i*Y;
                   len = size(WindowParam);
                   resArr=cell(len);
                   resArr=arrayfun(@(re,im,p,n){[re im p n]},real(WindowParam),imag(WindowParam),contParms.Periods,contParms.LastIters);

                   resArr = cell2mat(resArr);
                   resLen=size(resArr);
                   
                   resArrNew=zeros(len(1)*len(2),4);
                   c=0;
                   for j=1:4:resLen(2)
                       resArrNew(c*resLen(1)+1:resLen(1)*(c+1),:)=resArr(:,j:j+3);
                       c=c+1;
                   end
                   dlmwrite(ConfFileName,resArrNew,'-append','delimiter','\t');
                   
               end

           end
           if obj.isSaveFig
                   
               fig=graphics.Axs;
               if obj.FigureFileFormat==1
                       h = figure;
                       set(h,'units','normalized','outerposition',[0 0 1 1])
                       colormap(graphics.Clrmp);
                       h.CurrentAxes = copyobj([fig graphics.Clrbr],h);
                       h.Visible='on';
               else
                   set(fig,'Units','pixel');
                   pos=fig.Position;
                   marg = 40;
                   if contParms.SingleOrMultipleCalc
                       rect = [-2*marg, -marg, pos(3)+2.5*marg, pos(4)+2*marg];
                   else
                       rect = [-2*marg, -1.5*marg, pos(3)+4.5*marg, pos(4)+2.5*marg];
                   end
                   photo=getframe(fig,rect);
                   [photo,cmp]=frame2im(photo);
                   photoName=strcat(obj.ResPath,'\CAField');
                   switch obj.FigureFileFormat
                       case 2
                           imwrite(photo,jet(256),strcat(photoName,'.png'));
                       case 3
                           imwrite(photo,strcat(photoName,'.jpg'),'jpg','Quality',100);
                   end
                   set(fig,'Units','normalized');
               end
           end
           resproc=obj;
       end
       
       function [filename] = SaveParms(obj, ca, contParms,param)
           ConfFileName=strcat('\Modeling-Params-',datestr(clock));
           ConfFileName=strcat(ConfFileName,'.txt');
           ConfFileName=strrep(ConfFileName,':','-');
           ConfFileName=strcat(obj.ResPath,ConfFileName);
           if contParms.SingleOrMultipleCalc
                   fileID = fopen(ConfFileName, 'w');
                   fprintf(fileID, '1\n');
                   fprintf(fileID, strcat(num2str(ca.FieldType),'\n'));
                   fprintf(fileID, strcat(num2str(ca.BordersType),'\n'));
                   fprintf(fileID, strcat(num2str(ResultsProcessing.GetSetCellOrient),'\n'));
                   fprintf(fileID, strcat(num2str(ca.N),'\n'));
                   fprintf(fileID, strcat(func2str(ca.Base),'\n'));
                   fprintf(fileID, strcat(func2str(ca.Lambda),'\n'));
                   
                   fprintf(fileID, strcat(num2str(ca.Zbase),'\n'));
                   fprintf(fileID, strcat(num2str(ca.Miu0),'\n'));
                   fprintf(fileID, strcat(num2str(ca.Miu),'\n'));
                   
                   if ~ischar(param) && param~=0
                       fprintf(fileID, strcat(num2str(param),'\n'));
                       paramStart=complex(contParms.ReRangeWindow(1),contParms.ImRangeWindow(1));
                       paramStep=(contParms.ReRangeWindow(2)-contParms.ReRangeWindow(1));
                       paramEnd=complex(contParms.ReRangeWindow(end),contParms.ImRangeWindow(end));
                       
                       paramStartSrt=strcat(num2str(paramStart),' :');
                       paramEndSrt=strcat(' :',num2str(paramEnd));
                       paramSrt=strcat(paramStartSrt,num2str(paramStep));
                       paramSrt=strcat(paramSrt,paramEndSrt);
                       
                       fprintf(fileID, strcat(paramSrt,'\n'));
                       fclose(fileID);
                   else
                       if ca.N~=1
                           fclose(fileID);
                           dlmwrite(ConfFileName,param,'-append','delimiter','');
                       else
                           fprintf(fileID, strcat(num2str(ControlParams.GetSetMaxPeriod),'\n'));
                           fclose(fileID);
                       end
                   end
                   fileID = fopen(ConfFileName, 'a');
                   PrecisionParms = ControlParams.GetSetPrecisionParms;
                   fprintf(fileID, strcat(num2str(PrecisionParms(1)),'\n'));
                   fprintf(fileID, strcat(num2str(PrecisionParms(2)),'\n'));
                   fclose(fileID);
               
           else
               fileID = fopen(ConfFileName, 'w');
               fprintf(fileID, '0\n');
               fprintf(fileID, strcat(num2str(ca.Zbase),'\n'));
               fprintf(fileID, strcat(func2str(contParms.ImageFunc),'\n'));
               fprintf(fileID, strcat(num2str(contParms.SingleParams(1)),'\n'));
               fprintf(fileID, strcat(num2str(contParms.SingleParams(2)),'\n'));
               fprintf(fileID, strcat(num2str(contParms.WindowParamName),'\n'));
               
               paramStart=complex(contParms.ReRangeWindow(1),contParms.ImRangeWindow(1));
               paramStep=complex(contParms.ReRangeWindow(2)-contParms.ReRangeWindow(1),contParms.ImRangeWindow(2)-contParms.ImRangeWindow(1));
               paramEnd=complex(contParms.ReRangeWindow(end),contParms.ImRangeWindow(end));
                    
               paramStartSrt=strcat(num2str(paramStart),' :');
               paramEndSrt=strcat(' :',num2str(paramEnd));
               paramSrt=strcat(paramStartSrt,num2str(paramStep));
               paramSrt=strcat(paramSrt,paramEndSrt);
               fprintf(fileID,strcat(paramSrt,'\n'));
               PrecisionParms = ControlParams.GetSetPrecisionParms;
               mp=ControlParams.GetSetMaxPeriod;
               
               fprintf(fileID, strcat(num2str(PrecisionParms(1)),'\n'));
               fprintf(fileID, strcat(num2str(PrecisionParms(2)),'\n'));
               fprintf(fileID, strcat(num2str(mp),'\n'));
               fclose(fileID);
           end
           filename=ConfFileName;
       end
       
   end
   
   methods (Static)
       %%
      % метод get-set для статической переменной ориентации ячейки (0-не задана(квадрат), 1-вертикальная, 2-горизонтальная)
       function out = GetSetCellOrient(Cellorient)
           persistent CellOrientation;
           if nargin
               CellOrientation = Cellorient;
           end
           out = CellOrientation;
       end
       
      % метод get-set для статической переменной типа поля (1-гексагональное, 0-квадратное)
       function out = GetSetFieldOrient(Fieldorient)
           persistent FieldOrientation;
           if nargin
               FieldOrientation = Fieldorient;
           end
           out = FieldOrientation;
       end
       %%
       %метод отрисовки ячейки КА
       function out = DrawCell(CA_cell)
           
           if ResultsProcessing.GetSetFieldOrient
               
               if ResultsProcessing.GetSetCellOrient==1
                   %% Отрисовка вертикального гексагона в гексагональном поле
                   i=cast(CA_cell.Indexes(1,1),'double');
                   j=cast(CA_cell.Indexes(1,2),'double');
                   k=cast(CA_cell.Indexes(1,3),'double');
                   x0=0;
                   y0=0;
               
                   switch k
                   
                       case 1
                           switch compareInt32(i,j)
                               case -1
                                   y0=-3/2*(j-i);
                               case 0
                                   y0=0;
                               case 1
                                   y0=3/2*(i-j);
                           end
                           x0=(i+j)*sqrt(3)/2;
                       
                       case 2
                           x0=-sqrt(3)/2*(i+(i-j));
                           y0=3/2*j;
                       
                       case 3
                           x0=-sqrt(3)/2*(j+(j-i));
                           y0=-3/2*i;
                       
                   end
                   
                   dx=sqrt(3)/2;
                   dy=1/2;
                   
                   x_arr=[x0 x0+dx x0+dx x0 x0-dx x0-dx];
                   y_arr=[y0 y0+dy y0+3*dy y0+4*dy y0+3*dy y0+dy];
               
                   patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% рисование гексагона
                   %%
               else
                   %% Отрисовка горизонтального гексагона в гексагональном поле
                   i=cast(CA_cell.Indexes(1,1),'double');
                   j=cast(CA_cell.Indexes(1,2),'double');
                   k=cast(CA_cell.Indexes(1,3),'double');
                   x0=0;
                   y0=0;
                   
%                    %первый вариант размещения координатных осей
%                    switch k
%                        
%                        case 1
%                            y0=-sqrt(3)/2*(i+j);
%                            x0=3/2*(i-j);
%                    
%                        case 2
%                            y0=sqrt(3)/2*(i-(j-i));
%                            x0=3/2*j;
%                      
%                        case 3
%                            y0=sqrt(3)/2*(j-(i-j));
%                            x0=-3/2*(j-(j-i));
%                        
%                    end

                   %второй вариант размещения координатных осей
                   switch k
                   
                       case 1
                           switch compareInt32(i,j)
                               case -1
                                   x0=-3/2*(j-i);
                               case 0
                                   x0=0;
                               case 1
                                   x0=3/2*(i-j);
                           end
                           y0=(i+j)*sqrt(3)/2;
                       
                       case 2
                           y0=-sqrt(3)/2*(i+(i-j));
                           x0=3/2*j;
                       
                       case 3
                           y0=-sqrt(3)/2*(j+(j-i));
                           x0=-3/2*i;
                       
                   end
                   
                   dy=sqrt(3)/2;
                   dx=1/2;
                   
                   x_arr=[x0 x0+dx x0 x0-(2*dx) x0-(3*dx) x0-(2*dx)];
                   y_arr=[y0 y0+dy  y0+2*(dy) y0+2*(dy) y0+dy y0];
               
                   patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% рисование гексагона
                   %%
               end
               
           else
               
               switch ResultsProcessing.GetSetCellOrient
                   
                   case 0
                       %% Отрисовка квадрата в квадратном поле
                       x_arr=[CA_cell.Indexes(2) CA_cell.Indexes(2)+1 CA_cell.Indexes(2)+1 CA_cell.Indexes(2)];
                       y_arr=[(CA_cell.Indexes(1)) (CA_cell.Indexes(1)) (CA_cell.Indexes(1))+1 (CA_cell.Indexes(1))+1];
                       
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% рисование квадрата
                       %%
                   case 1
                       %% Отрисовка вертикального гексагона в квадратном поле
                       x0 = cast(CA_cell.Indexes(1,1),'double');% визуальная координата на оси x
                       y0 = cast(CA_cell.Indexes(1,2),'double');% визуальная координата на оси y

                       %расчет шести точек гексагона на экране
                       if(x0)
                           x0=x0+(x0*sqrt(3)-x0);
                       end
                       
                       if(y0)
                           if mod(y0,2)
                               x0=x0+sqrt(3)/2;
                           end
                           y0=y0+(y0*1/2);
                       end
                       
                       dx=sqrt(3)/2;
                       dy=1/2;
                   
                       x_arr=[x0 x0+dx x0+dx x0 x0-dx x0-dx];
                       y_arr=[y0 y0+dy y0+3*dy y0+4*dy y0+3*dy y0+dy];
               
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% рисование гексагона
                       %%
                   case 2
                       %% Отрисовка горизонтального гексагона в квадратном поле
                       x0 = cast(CA_cell.Indexes(1,1),'double');% визуальная координата на оси x
                       y0 = cast(CA_cell.Indexes(1,2),'double');% визуальная координата на оси y

                       %расчет шести точек гексагона на экране
                       if(y0)
                           y0=y0+(y0*sqrt(3)-y0);
                       end
                       
                       if(x0)
                           if mod(x0,2)
                               y0=y0+sqrt(3)/2;
                           end
                           x0=x0+(x0*1/2);
                       end
                       
                       dy=sqrt(3)/2;
                       dx=1/2;
                   
                       x_arr=[x0 x0+dx x0 x0-(2*dx) x0-(3*dx) x0-(2*dx)];
                       y_arr=[y0 y0+dy  y0+2*(dy) y0+2*(dy) y0+dy y0];
               
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % рисование гексагона
                       %%
               end
           end
           out = CA_cell;
       end
       
       function out = GetCellValueModule(CA_cell)
          out = ComplexModule(CA_cell.z0);
       end
       
       %установка цвета состояния ячейки через максимальное и минимальное значение модуля состояния в массиве всего поля
       %%
       function cell=SetCellColor(CA_cell, color)
           CA_cell.Color=color;
           cell=CA_cell;
       end
       %%
   end
   
end

function mustBeInRange(a,b)
    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ',...
            num2str(b(1)),'...',num2str(b(2))])
    end
end

function res = compareInt32(a,b)
    if a>b
        res=1;
    else
        if a<b
            res=-1;
        else
            res=0;
        end
    end
end

function out = ComplexModule(compNum)
    out=sqrt(real(compNum)*real(compNum)+imag(compNum)*imag(compNum));
end