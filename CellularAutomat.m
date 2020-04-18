classdef CellularAutomat
   
    properties
        
        FieldType logical % ��� ������� (1-��������������, 0-����������)
        BordersType {mustBeInteger, mustBeInRange(BordersType,[1,3])} % ��� ������ (1-����� ������, 2-��������� ������, 3-�������� ������� )
        N double {mustBePositive, mustBeInteger} % ����� ����
        Base function_handle % ������� �����������
        Lambda function_handle % ����������� ������������ ����� �����
        Zbase double % �������� z*
        Miu0 double= 0% �������� ��0
        Miu double = 1% �������� ��
        Cells(1,:) CACell % ������ ���� ����� �� ����
        
    end
    
    methods(Static)
        
       % ����� get-set ��� ����������� ���������� "������� �������" ���� � ������
       function [base,lambda] = GetSetFuncs(basef,lambdaf)
           persistent baseFunc;
           persistent lambdaFunc;
           if nargin
               baseFunc=basef;
               lambdaFunc=lambdaf;
           end
           base = baseFunc;
           lambda = lambdaFunc;
       end
       
       %����� �������� ��������� ������
       function out = MakeIter(CA_cell)
           if ((length(CA_cell.CurrNeighbors)~=0) && (log(CA_cell.zPath(end))/log(10)<=15)) || (isequal(CA_cell.Indexes,[0 1 1]))
             
               z_last = CA_cell.zPath(end);
               [base,lambda] = CellularAutomat.GetSetFuncs;%�������� ������� �������� ����������� � ������
               basePart = base(z_last);% ���������� ����
               lambdaPart=0;
           
               neighborsZ=zeros(1,length(CA_cell.CurrNeighbors));
               neighborsZ=arrayfun(@(neighbor) neighbor.zPath(end)*1, CA_cell.CurrNeighbors);
           
               if regexp(func2str(lambda),'^@\(z_k,c\)')% ���� ������ �������� �� ���� ���������� (� ������ D2 ������ ����������-������ ������ ����������� �����)
                   onesArr=ones(1,length(CA_cell.CurrNeighbors));
                   onesArr(1:2:length(onesArr))=-1;
                   lambdaPart=lambda(neighborsZ,onesArr);% ���������� ������
               else
                   lambdaPart=lambda(neighborsZ);% ���������� ������
               end
               
               if isnan(lambdaPart) && isequal(CA_cell.Indexes,[0 1 1])
                   lambdaStr = func2str(lambda);
                   lambdaStr = regexprep(lambdaStr,'\(z_k\)','()');
                   lambdaStr = regexprep(lambdaStr,'\+\(.*','');
                   lambda=str2func(lambdaStr);
                   lambdaPart = lambda();
               end
               
               z_new=lambdaPart*basePart;
               CA_cell.zPath=[CA_cell.zPath z_new];
           end
           out = CA_cell;
       end       
       
       function out = ComplexModule(compNum)
           out=sqrt(real(compNum)*real(compNum)+imag(compNum)*imag(compNum));
       end
       
%        function out = UpdateNeighborsValues(CA_cell,cellArr)
%            logicNeib=zeros(1,length(cellArr));
%            ind=(cellArr==CA_cell.CurrNeighbors);
%            logicNeib = arrayfun(@(celli,neighbor) neighbor.Indexes==celli.Indexes ,cellArr,CA_cell.CurrNeighbors);
%            neibArrNumbs=find(logicNeib);
%            
%            if ~isempty(neibArrNumbs)
%                CA_cell.CurrNeighbors=cellArr(neibArrNumbs(:));
%            end
%            
%            out=CA_cell;
%        end
       
    end
    
    methods
        
       %����������� �� 
       function ca = CellularAutomat(fieldType, bordersType, n, base, lambda, zbase, miu0, miu)
           if nargin
               ca.FieldType=fieldType;
               ca.BordersType=bordersType;
               ca.N=n;
               ca.Base=base;
               ca.Lambda=lambda;
               ca.Zbase=zbase;
               ca.Miu0=miu0;
               ca.Miu=miu;
           end
       end
        
       %����� ������� ������
       function out = FindCellsNeighbors(ca, CA_cell)
           thisCA=ca; % ��������� �������� ��
           n=thisCA.N; % ����� ����
           
           logicNeib = zeros(1,n*n); % ������, ������� ��������� ��������� �������� ����� �������� ������� � ������� ����� ����
           
           %����� ������� ������ CA_cell � ����������� �� ���� ������ ��
           switch thisCA.BordersType
               %����� ������
               case 1
                   if thisCA.FieldType
                       
                       if(~CA_cell.IsExternal)
                           logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]),thisCA.Cells);
                       end
                       
                   else
                       
                       if(~CA_cell.IsExternal)
                           logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]),thisCA.Cells);
                       end
                       
                   end
                   
               %��������� ������
               case 2
                   if thisCA.FieldType
                       
                       if(any(CA_cell.Indexes(1:2))==n-1)
                       
                           if isequal(CA_cell.Indexes(1:2),[n-1 0])
                               
                               logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 (n-1)]),thisCA.Cells);
                       
                           end
                           
                           if isequal(CA_cell.Indexes(1:2),[n-1 n-1])
                           
                               logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 -(n-1)]),thisCA.Cells);
                       
                           end
                           
                           if (CA_cell.Indexes(1)==n-1 && CA_cell.Indexes(2)>0 && CA_cell.Indexes(2)~=n-1) || (CA_cell.Indexes(2)==n-1 && CA_cell.Indexes(1)>0 && CA_cell.Indexes(1)~=n-1)
                           
                               logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || (isequal(abs(cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 0]) && cell.Indexes(3)~=CA_cell.Indexes(3)),thisCA.Cells);                       
                       
                           end
                           
                       else
                           logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]),thisCA.Cells);
                       end
                   else
                       
                       logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[0 n-1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[n-1 0 0]),thisCA.Cells);
                   
                   end
                   
               %�������� �������    
               case 3
                   if thisCA.FieldType
                       logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]),thisCA.Cells);
                   else
                       logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]),thisCA.Cells);
                   end
                   
           end
           
           neibArrNumbs=find(logicNeib);
           if ~isempty(neibArrNumbs)
               CA_cell.CurrNeighbors = thisCA.Cells(neibArrNumbs(:));
           end
           
           out = CA_cell;
       end
       
       %������ � ����� �������� ������ ���������� ���������� �� ����� �� ��������
       function MakeFuncsWithNums(ca)
           thisCA = ca;
           
           MiuStr=strcat('(',num2str(thisCA.Miu));
           MiuStr=strcat(MiuStr,')');
           baseFuncStr=strrep(func2str(thisCA.Base),'c',MiuStr);
           
           Miu0Str=strcat('(',num2str(thisCA.Miu0));
           Miu0Str=strcat(Miu0Str,')');
           lambdaFuncStr=strrep(func2str(thisCA.Lambda),'Miu0',Miu0Str);
           lambdaFuncStr=strrep(lambdaFuncStr,'Miu',MiuStr);
           
           zBStr=strcat('(',num2str(thisCA.Zbase));
           zBStr=strcat(zBStr,')');
           lambdaFuncStr=strrep(lambdaFuncStr,'Zbase',zBStr);
           
           baseFunc=str2func(baseFuncStr);
           lambdaFunc=str2func(lambdaFuncStr);
           
           CellularAutomat.GetSetFuncs(baseFunc,lambdaFunc);
           
       end

    end
    
end

function mustBeInRange(a,b)
    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ',...
            num2str(b(1)),'...',num2str(b(2))])
    end
end
