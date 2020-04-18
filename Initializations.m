classdef Initializations
    
    methods(Static)
        
        function [currCA,rangeError,rangeErrorStr] = Z0RangeInit(Re,Im,N,ca,isRand)
            if isRand==1
                Re=Re(randperm(length(Re)));
                Im=Im(randperm(length(Im)));
            end
            valuesArr=[];
            idxes=[];
            cellCount=0;
            
            if ca.FieldType
                cellCount=N*(N-1)*3;
            else
                cellCount=N*N;
            end
            
            if any([length(Re) length(Im)] < cellCount)
                rangeError=true;
                rangeErrorStr='Количество значений в заданном диапазоне меньше числа ячеек КА. ';
                currCA=ca;
                return;
            else
                rangeError=false;
                rangeErrorStr='';
            end
            
            if N~=1
                if ca.FieldType
                        
                    i=1:N-1;
                    i=i';
                    i_old=i;
                    for c=1:(cellCount/(N-1))-1
                        i=[i;i_old];
                    end
                    
                    j=ones(N*(N-1),1);
                    for c=0:N-1
                        j(1+((N-1)*c):(N-1)*(c+1),:)=c;
                    end
                    
                    j_old=j;
                    j=[j;j_old];
                    j=[j;j_old];
                    
                    k=ones(N*(N-1)*3,1);
                    k(1:(cellCount/3),:)=1;
                    k((cellCount/3)+1:(2*cellCount/3),:)=2;
                    k((2*cellCount/3)+1:cellCount,:)=3;
                        
                    idxes=arrayfun(@(i,j,k){[i j k]}, i',j',k');
                else
                    x=zeros(cellCount,1);
                    y=zeros(cellCount,1);
                    for i=0:N-1
                        x((i*N)+1:(i*N)+N+1)=i;
                    end
                    x=x(1:end-1);
                    
                    for i=0:N-1
                        y(1+i:N:length(y))=i;
                    end
                    idxes=arrayfun(@(x,y){[x y 0]}, x',y');
                end
                
            else
                value=complex(Re(1,1),Im(1,1));
                ca.Cells=CACell(value, value, [0 1 1], [0 0 0], ca.FieldType, 1);
                currCA=ca;
                return;
            end
            
            Re=Re(:,1:cellCount);
            Im=Im(:,1:cellCount);
            valuesArr=arrayfun(@(re,im) complex(re,im),Re,Im);
            
            colors=cell(1,cellCount);
            colors(:)=num2cell([0 0 0],[1 2]);
            fieldTypeArr=zeros(1,cellCount);
            fieldTypeArr(:)=ca.FieldType;
            NArr=zeros(1,cellCount);
            NArr(:)=N;
            
            ca.Cells=arrayfun(@(value, path, indexes, color, FieldType, N) CACell(value, path, indexes, color, FieldType, N) ,valuesArr,valuesArr,idxes,colors,fieldTypeArr,NArr);
            currCA=ca;
        end
        
    end
    
end