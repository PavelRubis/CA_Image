classdef CellularAutomat
   
    properties
        
        FieldType logical % тип решетки (1-гексагональный, 0-квадратный)
        BordersType {mustBeInteger, mustBeInRange(BordersType,[1,3])} % тип границ (1-лини€ смерти, 2-замыкание границ, 3-закрытые границы )
        N double {mustBePositive, mustBeInteger} % ребро пол€
        Base function_handle % базовое отображение
        Lambda function_handle % зависимость коеффициента перед базой
        Zbase double % параметр z*
        Miu0 double= 0% параметр мю0
        Miu double = 1% параметр мю
        Cells (1,:) CACell % массив всех €чеек на поле
        
    end
    
    methods(Static)
        
       % метод get-set дл€ статических переменных "готовых функций" базы и л€мбды
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
       
       %метод рассчета состо€ни€ €чейки
       function out = MakeIter(CA_cell)
           
           persistent PrecisionParms;
           if isempty(PrecisionParms)
              PrecisionParms = ControlParams.GetSetPrecisionParms;
           end
           
           if  (length(CA_cell.CurrNeighbors)~=0 && log(CA_cell.zPath(end))/log(10)<=PrecisionParms(1) && ~isnan(CA_cell.zPath(end))) || isequal(CA_cell.Indexes,[0 1 1])
             
               z_last = CA_cell.zPath(end);
               [base,lambda] = CellularAutomat.GetSetFuncs;%получаем функции базового отображени€ и л€мбды
               basePart = base(z_last);% вычисление базы
           
               neighborsZ=zeros(1,length(CA_cell.CurrNeighbors));
               neighborsZ=arrayfun(@(neighbor) neighbor.zPath(end)*1, CA_cell.CurrNeighbors);
           
               if regexp(func2str(lambda),'^@\(z_k,n\)')% если л€мбда завиисит от двух переменных (в случае D2 втора€ переменна€-массив единиц переменного знака)
                   onesArr=ones(1,length(CA_cell.CurrNeighbors));
                   onesArr(1:2:length(onesArr))=-1;
                   lambdaPart=lambda(neighborsZ,onesArr);% вычисление л€мбды
               else
                   lambdaPart=lambda(neighborsZ);% вычисление л€мбды
               end
               
               if isequal(CA_cell.Indexes,[0 1 1])
                   lambdaStr=func2str(lambda);
                   if contains(lambdaStr,'sum')
                       lambdaStr = regexprep(lambdaStr,'\)\+.+',')');
                       lambda=str2func(lambdaStr);
                   end
                   lambdaPart=lambda(neighborsZ);
               end
               
               if ControlParams.GetSetCustomImag
                   z_new=basePart;
               else
                   z_new=lambdaPart*basePart;
               end
               
               CA_cell.zPath=[CA_cell.zPath z_new];
               
               if (abs(CA_cell.zPath(end)-CA_cell.zPath(end-1))<PrecisionParms(2))
                   CA_cell.fstep=CA_cell.fstep;
               else
                   CA_cell.fstep=CA_cell.fstep+1;
               end
               
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
        
       %конструктор  ј 
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
        
       %поиск соседей €чейки
       function out = FindCellsNeighbors(ca, CA_cell)
           thisCA=ca; % экземпл€р текущего  ј
           n=thisCA.N; % ребро пол€
           generalNeib = []; % массив, индексы ненулевых элементов которого равны индексам соседей в массиве €чеек пол€
           extraNeib = [];
           extraGeneralNeib = [];
           if thisCA.FieldType
               generalNeib = zeros(1,n*(n-1)*3+1);
               extraGeneralNeib = zeros(1,n*(n-1)*3+1);
               extraNeib = zeros(1,n*(n-1)*3+1);
           else
               generalNeib = zeros(1,n*n);
           end
           
          CA_cell = CACell(CA_cell.z0,CA_cell.zPath, CA_cell.Indexes, CA_cell.Color, thisCA.FieldType, n);
           
           %поиск соседей €чейки CA_cell в зависимости от типа границ  ј
           switch thisCA.BordersType
               %лини€ смерти
               case 1
                   if thisCA.FieldType
                       
                       if(~CA_cell.IsExternal)
                           generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || ((isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 -1])) && all(cell.Indexes==0)),thisCA.Cells);
                           

                           switch CA_cell.Indexes(3)
                               case 1
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                   end
                                   
                               case 2
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                               
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                          extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                       
                           
                                   end
                                   
                               case 3
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                        
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                       end
                                   end
                           end
                           
                           if all(CA_cell.Indexes==0)
                               generalNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 1]),thisCA.Cells);
                           end
                       
                       end
                       
                   else
                       
                       if(~CA_cell.IsExternal)
                           generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]),thisCA.Cells);
                       end
                       
                   end
                   
               %замыкание границ
               case 2
                   if thisCA.FieldType
                       %добавить те, у которых либо j=0 либо i=1
                       
                       if(any(CA_cell.Indexes(1:2)==n-1))
                       
                           if isequal(CA_cell.Indexes(1:2),[n-1 0])
                               
                               extraNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 (n-1)]),thisCA.Cells);
                       
                           end
                           
                           if isequal(CA_cell.Indexes(1:2),[n-1 n-1])
                           
                               extraNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 -(n-1)]),thisCA.Cells);
                       
                           end
                           
                           if (CA_cell.Indexes(1)==n-1 && CA_cell.Indexes(2)>0 && CA_cell.Indexes(2)~=n-1) || (CA_cell.Indexes(2)==n-1 && CA_cell.Indexes(1)>0 && CA_cell.Indexes(1)~=n-1)
                           
                               extraNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || (isequal(abs(cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[0 0]) && cell.Indexes(3)~=CA_cell.Indexes(3)),thisCA.Cells);                    
                       
                           end
                       else
                           generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || ((isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 -1])) && all(cell.Indexes==0)),thisCA.Cells);
                       end
                           
                           switch CA_cell.Indexes(3)
                               case 1
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                   end
                                   
                               case 2
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                               
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                          extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                       
                           
                                   end
                                   
                               case 3
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                        
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                       end
                                   end
                           end
                           
                           if all(CA_cell.Indexes==0)
                               
                               generalNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 1]),thisCA.Cells);
                           
                           end
                       
                   else
                       
                       generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[0 n-1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[n-1 0 0]),thisCA.Cells);
                   
                   end
                   
               %закрытые границы    
               case 3
                   if thisCA.FieldType
                       generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]) || ((isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-1 -1])) && all(cell.Indexes==0)),thisCA.Cells);

                           switch CA_cell.Indexes(3)
                               case 1
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                   end
                                   
                               case 2
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==3 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                               
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                       
                                       else
                                           
                                          extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                           
                                       end
                                       
                           
                                   end
                                   
                               case 3
                                   
                                   if CA_cell.Indexes(2)==0 %&& CA_cell.Indexes(1)<n-1
                                       
                                       extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[-(CA_cell.Indexes(1)-1) cell.Indexes(2)]) && cell.Indexes(3)==1 && (CA_cell.Indexes(1)==cell.Indexes(2) || CA_cell.Indexes(1)==cell.Indexes(2)-1) ,thisCA.Cells);
                                   
                                   end
                                   if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)>0
                                       if all(CA_cell.Indexes(1:2)==1)
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1)) ,thisCA.Cells);
                                        
                                       else
                                           
                                           extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || CA_cell.Indexes(2)==cell.Indexes(1)-1) ,thisCA.Cells);
                                           if CA_cell.Indexes(1)==1 && CA_cell.Indexes(2)==n-1
                                               extraGeneralNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[(cell.Indexes(1)-1) -CA_cell.Indexes(2)]) && cell.Indexes(3)==2 && (CA_cell.Indexes(2)==cell.Indexes(1) || abs(CA_cell.Indexes(2)-cell.Indexes(1))==1) ,thisCA.Cells);
                                           end
                                       end
                                   end
                           end
                       
                       if all(CA_cell.Indexes==0)
                          
                           generalNeib = arrayfun(@(cell) isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 0]) || isequal((cell.Indexes(1:2) - CA_cell.Indexes(1:2)),[1 1]),thisCA.Cells);
                       
                       end
                       
                   else
                       generalNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]),thisCA.Cells);
                   end
                   
           end
           
           neibArrNumbs=find(generalNeib);
           if ~isempty(neibArrNumbs)
               CA_cell.CurrNeighbors = thisCA.Cells(neibArrNumbs(:));
           end
           
           neibArrNumbs=find(extraGeneralNeib);
           if ~isempty(neibArrNumbs)
               CA_cell.CurrNeighbors = [CA_cell.CurrNeighbors thisCA.Cells(neibArrNumbs(:))];
           end
           
           neibArrNumbs=find(extraNeib);
           if ~isempty(neibArrNumbs)
               CA_cell.CurrNeighbors = [CA_cell.CurrNeighbors thisCA.Cells(neibArrNumbs(:))];
           end
           
%            zeroNeibrs=arrayfun(@(cell) all(cell.Indexes==0) ,CA_cell.CurrNeighbors);
%            if any(zeroNeibrs==1)
%                if length(zeroNeibrs)~=1
%                    inxes=find(zeroNeibrs);
%                    inxes(1)=[];
%                    CA_cell.CurrNeighbors(inxes)=[];
%                end
%            end
           
           out = CA_cell;
       end
       
       %замена в обоих функци€х текста посто€нных параметров на текст их значени€
       function MakeFuncsWithNums(ca)
           thisCA = ca;
           
           MiuStr=strcat('(',num2str(thisCA.Miu));
           MiuStr=strcat(MiuStr,')');
           Miu0Str=strcat('(',num2str(thisCA.Miu0));
           Miu0Str=strcat(Miu0Str,')');
           baseFuncStr=strrep(func2str(thisCA.Base),'Miu0',Miu0Str);
           baseFuncStr=strrep(baseFuncStr,'Miu',MiuStr);
           
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
