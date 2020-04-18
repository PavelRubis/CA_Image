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
N=5;

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
M=fscanf(fileID1,formatSpec,[4 cellCount]);%
fclose(fileID1);
M=M';

