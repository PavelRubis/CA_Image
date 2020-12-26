classdef Initializations
    
    methods(Static)
        
        function [currCA,rangeError,rangeErrorStr] = Z0RandRangeInit(Re,Im,N,ca,isRand)
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
                    idxes=[{[0 0 0]} idxes];
                    cellCount=cellCount+1;
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
        
        function [currCA] = Z0IncRangeInit(StartPoint,XStep,YStep,z0,N,ca)
            
            valuesArr=[];
            idxes=[];
            cellCount=0;
            
            if ca.FieldType
                cellCount=N*(N-1)*3;
            else
                cellCount=N*N;
            end
            
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
                    idxes=[{[0 0 0]} idxes];
                    cellCount=cellCount+1;
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
                    xIndArr = x';
                    yIndArr = y';
                end
                
                if ca.FieldType
                    ReRange = real(StartPoint):XStep:real(StartPoint) + (XStep *(cellCount-1));
                    ImRange = imag(StartPoint):YStep:imag(StartPoint) +(YStep *(cellCount-1));
                    valuesArr=arrayfun(@(re,im) complex(re,im),ReRange,ImRange);
                else
                    valuesArr=arrayfun(@(xInd,yInd) (StartPoint + complex(xInd*XStep,yInd*YStep)) ,xIndArr,yIndArr);
                end
                valuesArr=valuesArr+z0;
            
                colors=cell(1,cellCount);
                colors(:)=num2cell([0 0 0],[1 2]);
                fieldTypeArr=zeros(1,cellCount);
                fieldTypeArr(:)=ca.FieldType;
                NArr=zeros(1,cellCount);
                NArr(:)=N;
                
                ca.Cells=arrayfun(@(value, path, indexes, color, FieldType, N) CACell(value, path, indexes, color, FieldType, N) ,valuesArr,valuesArr,idxes,colors,fieldTypeArr,NArr);
                
                currCA=ca;
            
        end
        
        function [ca,FileWasRead] = Z0FileInit(currCA,N,path,fileWasRead)
                ca=currCA;
                FileWasRead=fileWasRead;
                
                cellCount=0;
                fieldType= currCA.FieldType;
                z0Arr=[];

                if(regexp(path,'\.txt$'))
                    if fieldType
                        if N~=1
                            cellCount=N*(N-1)*3+1;
                        else
                            cellCount=1;
                        end
                        z0Size=[5 cellCount];
                        formatSpec = '%d %d %d %f %f\n';
                    else
                        cellCount=N*N;
                        z0Size=[4 cellCount];
                        formatSpec = '%d %d %f %f\n';
                    end
                    file = fopen(path, 'r');
                    z0Arr = fscanf(file, formatSpec,z0Size);
                    fclose(file);
                
                else
                    if fieldType
                        cellCount=N*(N-1)*3+1;
                    else
                        cellCount=N*N;
                    end
                    z0Arr=xlsread(path,1);
                    z0Arr=z0Arr';
                end
                
                if length(z0Arr(1,:))~=cellCount || (fieldType && length(z0Arr(:,1))==4)|| (~fieldType && length(z0Arr(:,1))==5)
                    errordlg('Ошибка. Количество начальных состояний в файле не соответствует заданному числу ячеек, или данные в файле не подходят для инициализации Z0.','modal');
                else
                    valuesArr=[];
                    idxes=[];
                    colors=[];
                    z0Arr=z0Arr';
        
                    if fieldType
                        
                        valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,4),z0Arr(:,5));
                        for i=1:cellCount
                            indx=z0Arr(i,1:3);
                            if (any(indx<0) || any(indx(1:2)>=N) || indx(3) > 3 || (indx(3)==0 && any(indx~=0)))
                                errordlg('Ошибка. Количество начальных состояний в файле не соответствует заданному числу ячеек, или данные в файле не подходят для инициализации Z0.','modal');
                                return;
                            end
                            idxes=[idxes {indx}];
                        end
                        
                    else
                        
                        valuesArr=arrayfun(@(re,im) complex(re,im),z0Arr(:,3),z0Arr(:,4));
                        for i=1:cellCount
                            indx=[z0Arr(i,1:2) 0];
                            if (any(indx(1:2)>=N) || any(indx(1:2)<0))
                                errordlg('Ошибка. Количество начальных состояний в файле не соответствует заданному числу ячеек, или данные в файле не подходят для инициализации Z0.','modal');
                                return;
                            end
                            idxes=[idxes {indx}];
                        end
                        
                    end
                    
                    fileWasRead=true;
                    valuesArr=valuesArr';
        
                    colors=cell(1,cellCount);
                    colors(:)=num2cell([0 0 0],[1 2]);
        
                    fieldTypeArr=zeros(1,cellCount);
                    fieldTypeArr(:)=fieldType;
        
                    NArr=zeros(1,cellCount);
                    NArr(:)=N;
                    
                    currCA.Cells=arrayfun(@(value, path, indexes, color, FieldType, N) CACell(value, path, indexes, color, FieldType, N) ,valuesArr,valuesArr,idxes,colors,fieldTypeArr,NArr);
        
                    msgbox(strcat('Начальная конфигурация КА была успешно задана из файла',path),'modal');
                    currCA.N=N;
                    
                    ca=currCA;
                    FileWasRead=fileWasRead;
                end
                
        end
        
    end
end