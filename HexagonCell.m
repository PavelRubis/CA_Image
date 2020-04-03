classdef HexagonCell
    
   properties
      z0 double=0+0i % начальное состояние ячейки
      zPath(1,:) double % орбита ячейки
      Indexes(1,3) int32 % индексы ячейки на поле (i,j,k при вертикальной ориентации)
      
      %для отрисовки:
      Color(1,3) {mustBeNumeric, mustBeInRange(Color,[0,255])} % цвет 
   end
   
   methods (Static)
       
      % метод get-set для статической переменной ориентации гексагональной ячейки (1-вертикальная, 0-горизонтальная)
       function out = setgetHexOrient(orient)
           persistent HexOrientation;
           if nargin
               HexOrientation = orient;
           end
           out = HexOrientation;
       end
      % метод get-set для статической переменной ориентации поля (1-гексагональное, 0-квадратное)
       function out = setgetFieldOrient(orient)
           persistent FieldOrientation;
           if nargin
               FieldOrientation = orient;
           end
           out = FieldOrientation;
       end
       % метод get-set для статической переменной ребра решетки N
       function out = setgetN(n)
           persistent N;
           if nargin
               N = n;
           end
           out = N;
       end
       
   end
   
   methods
       % конструктор ячейки (ее дескриптора)
       function obj = HexagonCell(indexes, value, path, color)
           if nargin
               
               if HexagonCell.setgetFieldOrient
                   if(any(indexes)<0 || any(indexes)>HexagonCell.setgetN || (indexes(1) < 1 && indexes(3)~=0) || indexes(3) > 3 || (indexes(3)==0 && any(indexes)~=0))
                       error('Error in hexagon indexes.');
                   else
                       obj.Indexes=indexes;
                   end
               else
                   if(indexes(1) > HexagonCell.setgetN || indexes(2) >= HexagonCell.setgetN || any(indexes)<0)
                       error('Error. X coordinate of hexagon must be <=N, Y coordinate of hexagon must be <N and both coordinate must be >=0.');
                   else
                       obj.Indexes=indexes;
                   end
               end
               
               
               obj.z0=value;
               obj.zPath=path;
               obj.Color=color;
               
           end
       end
       
       % метод отрисовки гексагона в зависимости от его ориентации и ориентации поля
       function drawHexagon(obj)
           if HexagonCell.setgetFieldOrient
               
               if HexagonCell.setgetHexOrient
                   %% Отрисовка вертикального гексагона в гексагональном поле
                   i=cast(obj.Indexes(1,1),'double');
                   j=cast(obj.Indexes(1,2),'double');
                   k=cast(obj.Indexes(1,3),'double');
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
                   
                   x_i=[x0 x0+sqrt(3)/2 x0+sqrt(3)/2 x0 x0-sqrt(3)/2 x0-sqrt(3)/2];
                   y_i=[y0 y0+1/2 y0+3/2 y0+2 y0+3/2 y0+1/2];
               
                   patch(x_i,y_i,[obj.Color(1)/255 obj.Color(2)/255 obj.Color(3)/255]);
                   
               else
                   %% Отрисовка горизонтального гексагона в гексагональном поле
                   i=cast(obj.Indexes(1,1),'double');
                   j=cast(obj.Indexes(1,2),'double');
                   k=cast(obj.Indexes(1,3),'double');
                   x0=0;
                   y0=0;
               
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
                   
                   x_arr=[x0 x0+1/2 x0 x0-1 x0-3/2 x0-1];
                   y_arr=[y0 y0+sqrt(3)/2  y0+2*(sqrt(3)/2) y0+2*(sqrt(3)/2) y0+sqrt(3)/2 y0];
               
                   patch(x_arr,y_arr,[obj.Color(1)/255 obj.Color(2)/255 obj.Color(3)/255]);
                   
               end
               
           else
               
               if HexagonCell.setgetHexOrient
                   %% Отрисовка вертикального гексагона в квадратном поле
                   x0 = cast(obj.Indexes(1,1),'double');% визуальная координата на оси x
                   y0 = cast(obj.Indexes(1,2),'double');% визуальная координата на оси y

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
                   
                   x_i=[x0 x0+sqrt(3)/2 x0+sqrt(3)/2 x0 x0-sqrt(3)/2 x0-sqrt(3)/2];
                   y_i=[y0 y0+1/2 y0+3/2 y0+2 y0+3/2 y0+1/2];
               
                   patch(x_i,y_i,[obj.Color(1)/255 obj.Color(2)/255 obj.Color(3)/255]);
               else
                   %% Отрисовка горизонтального гексагона в квадратном поле
                   x0 = cast(obj.Indexes(1,1),'double');% визуальная координата на оси x
                   y0 = cast(obj.Indexes(1,2),'double');% визуальная координата на оси y

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
                   
                   x_arr=[x0 x0+1/2 x0 x0-1 x0-3/2 x0-1];
                   y_arr=[y0 y0+sqrt(3)/2  y0+2*(sqrt(3)/2) y0+2*(sqrt(3)/2) y0+sqrt(3)/2 y0];
               
                   patch(x_arr,y_arr,[obj.Color(1)/255 obj.Color(2)/255 obj.Color(3)/255]); % рисование гексагона случайным цветом
               end
               
               
           end
       end
       
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