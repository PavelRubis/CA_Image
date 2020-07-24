classdef ResultsProcessing
   %����� ��������� ����������� �������������
   properties
       isSave logical =0% ��������� �� ����������
       isSaveCA logical =0% ��������� �� ��
       isSaveFig logical =0% ��������� �� ������
       ResPath (1,:) char %���� � ����������� �����������
       CellsValuesFileFormat logical % ������ ����� ��� ������ �������� ����� (1-txt,0-xls)
       FigureFileFormat {mustBeInteger, mustBeInRange(FigureFileFormat,[1,3])}% ������ �������� ����
   end
   
   methods
       %�����������
       function obj = ResultsProcessing(resPath, cellsValuesFileFormat, figureFileFormat)
           if nargin
               obj.ResPath=resPath;
               obj.CellsValuesFileFormat=cellsValuesFileFormat;
               obj.FigureFileFormat=figureFileFormat;
           end
       end
       
       %����� ���������� �����������
       function resproc = SaveRes(obj, ca, graphics,contParms,Res)
           
           if contParms.SingleOrMultipleCalc 
               if obj.isSaveCA
                   ConfFileName=strcat('\Modeling-',datestr(clock));
                   ConfFileName=strcat(ConfFileName,'-CA-Conf.txt');
                   ConfFileName=strrep(ConfFileName,':','-');
                   ConfFileName=strcat(obj.ResPath,ConfFileName);
                   
                   fileID = fopen(ConfFileName, 'w');
                   fprintf(fileID, strcat('��������� ������������� ��  ',datestr(clock)));
                   if length(ca.Cells)==1
                       fprintf(fileID, '\n����� N=1\n');
                       fprintf(fileID, strcat('\n�����������: ',func2str(ca.Base)));
                       fprintf(fileID, strcat('\n����������� ��������� ������: ',func2str(ca.Lambda)));
                       fprintf(fileID, '\n���������� �������� N=%f\n',length(Res)-1);
                       fprintf(fileID, '������\n');
                       fprintf(fileID,'Re	Im	P	n\n');
                       fclose(fileID);
                       dlmwrite(ConfFileName,[real(ca.Cells(1).zPath(1)) imag(ca.Cells(1).zPath(end)) contParms.Periods contParms.LastIters],'-append','delimiter','\t');
                       
                       fileID = fopen(ConfFileName, 'a');
                       fprintf(fileID, '\n\n����������:\n');
                       fclose(fileID);
                       Res=Res';
                       dlmwrite(ConfFileName,'Re	Im','-append','delimiter','');
                       dlmwrite(ConfFileName,Res,'-append','delimiter','\t');
                   else
                       fprintf(fileID, '\n\n������������ ��:\n\n');
               
                       if ca.FieldType
                           fprintf(fileID, '��� ������� ����: ��������������\n');
                       else
                           fprintf(fileID, '��� ������� ����: ����������\n');
                       end
                       
                       switch ca.BordersType
                           case 1
                               fprintf(fileID, '��� ������ ����: "����� ������"\n');
                           case 2
                               fprintf(fileID, '��� ������ ����: ��������� ������\n');
                           case 3
                               fprintf(fileID, '��� ������ ����: �������� �������\n');
                       end
                       
                       fprintf(fileID, '����� N=%d\n',ca.N);
               
                       fprintf(fileID, strcat('������� �����������: ',func2str(ca.Base)));
                       fprintf(fileID, strcat('\n����������� ��������� ������: ',func2str(ca.Lambda)));
                       fprintf(fileID, '\n�������� ��=%f %fi\n',real(ca.Miu),imag(ca.Miu));
                       fprintf(fileID, '�������� ��0=%f %fi\n',real(ca.Miu0),imag(ca.Miu0));
                       fprintf(fileID, '�������� Iter=%f\n',contParms.IterCount-1);
                       fclose(fileID);
               
                       Z=[];
                       for j=1:length(ca.Cells)
                           idx=cast(ca.Cells(j).Indexes,'double');
                           Z=[Z ; [idx real(ca.Cells(j).zPath(end)) imag(ca.Cells(j).zPath(end))]];
                       end
%                        Z=Z';
                       ZFileName=strrep(ConfFileName,'-CA-Conf','-Z');
                       dlmwrite(ZFileName,'x	y	k	Re	Im','-append','delimiter','');
                       dlmwrite(ZFileName,Z,'-append','delimiter','\t');
                   end
               end
               
           else
               if obj.isSaveCA
                   ConfFileName=strcat('\MultiCalc-',datestr(clock));
                   ConfFileName=strcat(ConfFileName,'.txt');
                   ConfFileName=strrep(ConfFileName,':','-');
                   ConfFileName=strcat(obj.ResPath,ConfFileName);
                   
                   fileID = fopen(ConfFileName, 'w');
                   fprintf(fileID, strcat('������������� ������������� ��  ',datestr(clock)));
                   fprintf(fileID, '\n\n��������� �������������:\n\n');
                   
                   fprintf(fileID,strcat('�����������: ',func2str(contParms.ImageFunc)));
                   
                   fprintf(fileID, '\n���������� �������� N=%f\n',contParms.IterCount-1);
                   
                   fprintf(fileID, strcat('��������� ���������: ',num2str(contParms.SingleParams(1)),' ; ',num2str(contParms.SingleParams(2))));
                   fprintf(fileID, strcat('\n�������� ����: ',contParms.WindowParamName));
                   fprintf(fileID, '\n�������� ��������� ����: ');
                   
                   paramStart=complex(contParms.ReRangeWindow(1),contParms.ImRangeWindow(1));
                   paramStep=complex(contParms.ReRangeWindow(2)-contParms.ReRangeWindow(1),contParms.ImRangeWindow(2)-contParms.ImRangeWindow(1));
                   paramEnd=complex(contParms.ReRangeWindow(end),contParms.ImRangeWindow(end));
                       
                   paramStartSrt=strcat(num2str(paramStart),' : ');
                   paramEndSrt=strcat(' : ',num2str(paramEnd));
                   paramSrt=strcat(paramStartSrt,num2str(paramStep));
                   paramSrt=strcat(paramSrt,paramEndSrt);
                   fprintf(fileID,strcat(paramSrt,'\n\n'));
                   fclose(fileID);
                   dlmwrite(ConfFileName,'Re	Im	P	n','-append','delimiter','');
                  
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
                       colormap(graphics.Clrmp);
                       h.CurrentAxes = copyobj([fig graphics.Clrbr],h);
                       h.Visible='on';
               else
                   set(fig,'Units','pixel');
                   rect=fig.Position;
                   rect=rect-10;
                   drect=fig.TightInset;
                   
                   rect([1 2])=-drect([1 2])-2;
                   rect([3 4])= rect([3 4])+drect([3 4])+2;
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
               if ca.N~=1
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
                   
                   if ~ischar(param)
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
                       fclose(fileID);
                       dlmwrite(ConfFileName,param,'-append','delimiter','');
                   end
                   fileID = fopen(ConfFileName, 'a');
                   PrecisionParms = ControlParams.GetSetPrecisionParms;
                   fprintf(fileID, strcat(num2str(PrecisionParms(1)),'\n'));
                   fprintf(fileID, strcat(num2str(PrecisionParms(2)),'\n'));
                   fclose(fileID);
               end
               
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
      % ����� get-set ��� ����������� ���������� ���������� ������ (0-�� ������(�������), 1-������������, 2-��������������)
       function out = GetSetCellOrient(Cellorient)
           persistent CellOrientation;
           if nargin
               CellOrientation = Cellorient;
           end
           out = CellOrientation;
       end
       
      % ����� get-set ��� ����������� ���������� ���� ���� (1-��������������, 0-����������)
       function out = GetSetFieldOrient(Fieldorient)
           persistent FieldOrientation;
           if nargin
               FieldOrientation = Fieldorient;
           end
           out = FieldOrientation;
       end
       %%
       %����� ��������� ������ ��
       function out = DrawCell(CA_cell)
           
           if ResultsProcessing.GetSetFieldOrient
               
               if ResultsProcessing.GetSetCellOrient==1
                   %% ��������� ������������� ��������� � �������������� ����
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
               
                   patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% ��������� ���������
                   %%
               else
                   %% ��������� ��������������� ��������� � �������������� ����
                   i=cast(CA_cell.Indexes(1,1),'double');
                   j=cast(CA_cell.Indexes(1,2),'double');
                   k=cast(CA_cell.Indexes(1,3),'double');
                   x0=0;
                   y0=0;
                   
%                    %������ ������� ���������� ������������ ����
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

                   %������ ������� ���������� ������������ ����
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
               
                   patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% ��������� ���������
                   %%
               end
               
           else
               
               switch ResultsProcessing.GetSetCellOrient
                   
                   case 0
                       %% ��������� �������� � ���������� ����
                       x_arr=[CA_cell.Indexes(2) CA_cell.Indexes(2)+1 CA_cell.Indexes(2)+1 CA_cell.Indexes(2)];
                       y_arr=[(CA_cell.Indexes(1)) (CA_cell.Indexes(1)) (CA_cell.Indexes(1))+1 (CA_cell.Indexes(1))+1];
                       
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% ��������� ��������
                       %%
                   case 1
                       %% ��������� ������������� ��������� � ���������� ����
                       x0 = cast(CA_cell.Indexes(1,1),'double');% ���������� ���������� �� ��� x
                       y0 = cast(CA_cell.Indexes(1,2),'double');% ���������� ���������� �� ��� y

                       %������ ����� ����� ��������� �� ������
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
               
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]);% ��������� ���������
                       %%
                   case 2
                       %% ��������� ��������������� ��������� � ���������� ����
                       x0 = cast(CA_cell.Indexes(1,1),'double');% ���������� ���������� �� ��� x
                       y0 = cast(CA_cell.Indexes(1,2),'double');% ���������� ���������� �� ��� y

                       %������ ����� ����� ��������� �� ������
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
               
                       patch(x_arr,y_arr,[CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ���������
                       %%
               end
           end
           out = CA_cell;
       end
       
       function out = GetCellValueModule(CA_cell)
          out = ComplexModule(CA_cell.z0);
       end
       
       %��������� ����� ��������� ������ ����� ������������ � ����������� �������� ������ ��������� � ������� ����� ����
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