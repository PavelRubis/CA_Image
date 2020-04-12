classdef CACell
    
   properties
      z0 double=0+0i % начальное состо€ние €чейки
      zPath(1,:) double % орбита €чейки
      Indexes(1,3) int32 % индексы €чейки на поле (i,j,k при заданной ориентации, x,y при )
      CurrNeighbors(1,:) CACell % массив соседей €чейки на текущей итерации
      IsExternal logical = false % €вл€етс€ ли €чейка внешней
      Color(1,3) double {mustBeNumeric, mustBeInRange(Color,[0,1])} % цвет дл€ отрисовки €чейки на поле
   end
   

   
   methods
       %конструктор €чейки
       function obj = CACell(value, path, indexes, color, FieldType, N)
           if nargin
               
               if FieldType
                   if(any(indexes)<0 || any(indexes)>N || (indexes(1) < 1 && indexes(3)~=0) || indexes(3) > 3 || (indexes(3)==0 && any(indexes)~=0))
                       error('Error in cell (i,j,k) indexes.');
                   else
                       obj.Indexes=indexes;
                   end
               else
                   if(any(indexes)>=N || any(indexes)<0)
                       error('Error. X coordinate of cell must be <=N, Y coordinate of cell must be <=N and both coordinate must be >=0.');
                   else
                       obj.Indexes=indexes;
                   end
               end
               
               obj.z0=value;
               obj.zPath=path;
               obj.Indexes=indexes;
               obj.Color=color;
               
               if any(obj.Indexes)==(N-1)
                   obj.IsExternal=true;
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