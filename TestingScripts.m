clear; clc;
format long;

Re=-3:0.001:-2.7;
Im=-0.465:0.001:-0.165;
Re=Re(randperm(length(Re)));
Im=Im(randperm(length(Im)));
compArr=arrayfun(@(re,im) complex(re,im),Re,Im);
compArr=compArr';
Im=Im';
Re=Re';

fieldType=true;
N=6;

coorditates=[];
cellCount=0;
formatSpec ='';
if fieldType
    cellCount=N*(N-1)*3;
    
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
    
    coorditates=[i j k];
   formatSpec='%d %d %d %f %f\n';
else
   formatSpec='%d %d %f %f\n';
    cellCount=N*N;
    for x=0:N-1
        for y=0:N-1     
            coorditates=[coorditates; x y];
        end
    end
end


Im=Im(1:cellCount,:);
Re=Re(1:cellCount,:);
Z0=[coorditates Re Im];
Z0=Z0';

fileID = fopen('sourceHex.txt', 'w');
fprintf(fileID,formatSpec,Z0);
fclose(fileID);


M=[];
fileID1 = fopen('sourceHex.txt', 'r');
M=fscanf(fileID1,formatSpec,[5 cellCount]);%
fclose(fileID1);
M=M';

% 
% 
% miu=1;
% f = @(z)miu*(exp(i*z));
% mapz_zero=@(z) abs(f(z)-z);
% z0=-3.5+0.5*i;
% mapz_zero_xy=@(z) mapz_zero(z(1)+i*z(2));
% [zeq,zer]=fminsearch(mapz_zero_xy, [real(z0) imag(z0)],optimset('TolX',1e-9));
% [zeq zer]
% 
% s.cells=[];
% N=5;
% 
% ResultsProcessing.GetSetFieldOrient(0);
% ResultsProcessing.GetSetCellOrient(2);
% 
% figure; 
% hold on;
% 
% for x=0:N-1
%     for y=0:N-1     
%         cell=CACell(0,[],[x,y,0],[rand(1) rand(1) rand(1)],ResultsProcessing.GetSetFieldOrient,N);
%         s.cells=[s.cells cell];
%     end
% end
% 
% arrayfun(@(cell) ResultsProcessing.DrawCell(cell),s.cells);
% 
% isNeib=zeros(1,N*N);
% 
% CA_cell=CACell(0,[],[randi(N-1) randi(N-1) 0],[rand(1) rand(1) rand(1)],ResultsProcessing.GetSetFieldOrient,N);
% 
% logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]),s.cells);
% neibArrNumbs=find(logicNeib);
% 
% if ~isempty(neibArrNumbs)
%     CA_cell.CurrNeighbors=[CA_cell.CurrNeighbors s.cells(neibArrNumbs(:))];
% end
% 
% axis image
% set(gca,'xtick',[])
% set(gca,'ytick',[])
% set(gca,'Visible','off')
% 
% 
% 
% s.cells=[];
% N=1;
% 
% ResultsProcessing.GetSetFieldOrient(1);
% ResultsProcessing.GetSetCellOrient(1);
% 
% figure; 
% hold on;
% 
% for k=1:3
%     for j = 0:N-1
%         for i = 1:N-1
%             cell=CACell(complex(randn,randn),[],[i,j,k],[1 1 0],ResultsProcessing.GetSetFieldOrient,N);
%             s.cells=[s.cells cell];
%         end
%     end
% end
% 
% values=randn(1,length(s.cells));
% for i=1:length(s.cells)
%     s.cells(i).z0=values(i);
% end
% 
% colors=colormap(jet(length(s.cells)));
% modulesArr=zeros(1,length(s.cells));
% 
% modulesArr=arrayfun(@(cell) ResultsProcessing.GetCellValueModule(cell),s.cells);
% [modulesArr, cellArrIndexes]=sort(modulesArr);
% for i=1:length(s.cells)
%     s.cells(cellArrIndexes(i)).Color=colors(i,:);
% end
% 
% arrayfun(@(cell) ResultsProcessing.DrawCell(cell),s.cells);
% 
% CA_cell=CACell(0,[],[2 2 1],[0 0 1],ResultsProcessing.GetSetFieldOrient,N);
% % ResultsProcessing.DrawCell(CA_cell)
% 
% logicNeib = arrayfun(@(cell) isequal(abs(cell.Indexes - CA_cell.Indexes),[0 1 0]) || isequal(abs(cell.Indexes - CA_cell.Indexes),[1 0 0]) || isequal(cell.Indexes - CA_cell.Indexes,[1 1 0])  || isequal(cell.Indexes - CA_cell.Indexes,[-1 -1 0]),s.cells);
% neibArrNumbs=find(logicNeib);
% if ~isempty(neibArrNumbs)
%     CA_cell.CurrNeighbors=[CA_cell.CurrNeighbors s.cells(neibArrNumbs(:))];
% end
% 
% 
% for i=1:length(CA_cell.CurrNeighbors)
%     CA_cell.CurrNeighbors(i).Color=[1 0 0];
% end
% 
% % 
% 
% % arrayfun(@(cell) ResultsProcessing.DrawCell(cell),CA_cell.CurrNeighbors);
% 
% axis image
% set(gca,'xtick',[])
% set(gca,'ytick',[])
% set(gca,'Visible','off')
% 
% function out = ComplexModule(compNum)
%     out=sqrt(real(compNum)*real(compNum)+imag(compNum)*imag(compNum));
% end
% 

