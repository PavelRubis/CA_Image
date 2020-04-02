classdef SquareCell
    
   properties
      z0 double=0+0i % ��������� ��������� ������
      zPath(1,:) double % ������ ������
      Indexes(1,2) {mustBeReal, mustBeInteger} % ������� ������ �� ���� (i,j)
      
      %��� ���������:
      Color(1,3) {mustBeNumeric, mustBeInRange(Color,[0,255])} % ���� 
   end
   
   methods (Static)
       
       % ����� get-set ��� ����������� ���������� ����� ������� N
       function out = setgetN(n)
           persistent N;
           if nargin
               N = n;
           end
           out = N;
       end
       
       % ����� ��������� ���������� ������
       function out = drawSquare(cell)
%            N = HexagonCell.setgetN;
           x_i=[cell.Indexes(2) cell.Indexes(2)+1 cell.Indexes(2)+1 cell.Indexes(2)];
           y_i=[(cell.Indexes(1)) (cell.Indexes(1)) (cell.Indexes(1))+1 (cell.Indexes(1))+1];
               
           patch(x_i,y_i,[cell.Color(1)/255 cell.Color(2)/255 cell.Color(3)/255]); % ��������� �������� ��������� ������
       end
       
   end
   
   methods
       % ����������� ������ (�� �����������)
       function obj = SquareCell(indexes, value, path, color)
           if nargin
               obj.z0=value;
               obj.zPath=path;
               obj.Color=color;
               
               if(any(indexes) >= SquareCell.setgetN) || (any(indexes) < 0)
                   error('Error. Row of hexagon must be less than N and more than 1.');
               else
                   obj.Indexes=indexes;
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