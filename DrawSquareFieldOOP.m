clc;
clear;

figure; 
hold on;

% задание N=10
SquareCell.setgetN(10);

SquareField=[];
for i=0:SquareCell.setgetN-1
    for j=0:SquareCell.setgetN-1
        sq=SquareCell([i j],0+0i,[],[randi(255) randi(255) randi(255)]);
        SquareCell.drawSquare(sq);
        SquareField=[SquareField sq];
    end
end

% почему то arrayfun выдает ошибку (не видит ячейку)
% SquareField=arrayfun(SquareCell.drawSquare,SquareField);

% рисование белого квадрата с индексами 1;1
sq=SquareCell([0 0],0+0i,[],[255 255 255]);
SquareCell.drawSquare(sq);

% рисование черного квадрата с индексами N;N
sq=SquareCell([SquareCell.setgetN-1 SquareCell.setgetN-1],0+0i,[],[0 0 0]);
SquareCell.drawSquare(sq);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')