classdef ResultsProcessing
   %����� ��������� ����������� �������������
   properties
      ResPath (1,:) char %���� � ����������� �����������
      CellsValuesFileFormat logical % ������ ����� ��� ������ �������� ����� (1-txt,0-xls)
      FigureFileFormat {mustBeInteger, mustBeInRange(FigureFileFormat,[1,4])}% ������ �������� ����
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
       
       % ������� ����� ���������� �����������
       function SaveRes(obj, ca, fig)
           
       end
       
   end
   
   methods (Static)
       
      % ����� get-set ��� ����������� ���������� ���������� ������ (0-�� ������(�������), 1-������������, 2-��������������)
       function out = GetSetCellOrient(orient)
           persistent CellOrientation;
           if nargin
               CellOrientation = orient;
           end
           out = CellOrientation;
       end
       
      % ����� get-set ��� ����������� ���������� ���� ���� (1-��������������, 0-����������)
       function out = GetSetFieldOrient(orient)
           persistent FieldOrientation;
           if nargin
               FieldOrientation = orient;
           end
           out = FieldOrientation;
       end
       
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