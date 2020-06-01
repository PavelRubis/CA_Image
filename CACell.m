classdef CACell
    
   properties
      z0 double=0+0i % начальное состо€ние €чейки
      zPath double % (1,:)  % орбита €чейки
      Indexes int32 % (1,3)  % индексы €чейки на поле (i,j,k при заданной ориентации, x,y при )
      CurrNeighbors CACell % (1,:)  % массив соседей €чейки на текущей итерации
      IsExternal logical = false % €вл€етс€ ли €чейка внешней
      Color double% (1,3)  %{mustBeNumeric, mustBeInRange(Color,[0,1])} % цвет дл€ отрисовки €чейки на поле
      
      fstep double = 0
   end
   

   
   methods
       %конструктор €чейки
       function obj = CACell(value, path, indexes, color, FieldType, N)
           if nargin
               if iscell(indexes)
                   indexes=cell2mat(indexes);
               end
               if iscell(color)
                   color=cell2mat(color);
               end
               
               if FieldType
                   if(any(indexes)<0 || any(indexes)>=N || indexes(3) > 3 || (indexes(3)==0 && any(indexes)~=0)) && N~=1
                       error('Error in cell (i,j,k) indexes.');
                   else
                       obj.Indexes=indexes;
                       if (any(obj.Indexes==(N-1))) %|| any(obj.Indexes(1:2)==0))
                           obj.IsExternal=true;
                       end
                   end
               else
                   if(any(indexes)>=N || any(indexes)<0) && N~=1
                       error('Error. X coordinate of cell must be <=N, Y coordinate of cell must be <=N and both coordinate must be >=0.');
                   else
                       obj.Indexes=indexes;
                       if (any(obj.Indexes(1:2)==(N-1)) || any(obj.Indexes(1:2)==0))
                           obj.IsExternal=true;
                       end
                   end
               end
               
               obj.z0=value;
               obj.zPath=path;
               obj.Indexes=indexes;
               obj.Color=color;
           end
       end
       

       
   end
   
   methods(Static)
       function obj = SetZ0(obj,value)
           obj.z0=value;
           obj.zPath=value;
       end
   end
   
end

function mustBeInRange(a,b)
    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ',...
            num2str(b(1)),'...',num2str(b(2))])
    end
end