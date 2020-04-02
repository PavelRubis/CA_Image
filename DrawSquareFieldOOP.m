clc;
clear;

figure; 
hold on;

% ������� N=10
SquareCell.setgetN(10);

SquareField=[];
for i=0:SquareCell.setgetN-1
    for j=0:SquareCell.setgetN-1
        sq=SquareCell([i j],0+0i,[],[randi(255) randi(255) randi(255)]);
        SquareCell.drawSquare(sq);
        SquareField=[SquareField sq];
    end
end

% ������ �� arrayfun ������ ������ (�� ����� ������)
% SquareField=arrayfun(SquareCell.drawSquare,SquareField);

% ��������� ������ �������� � ��������� 1;1
sq=SquareCell([0 0],0+0i,[],[255 255 255]);
SquareCell.drawSquare(sq);

% ��������� ������� �������� � ��������� N;N
sq=SquareCell([SquareCell.setgetN-1 SquareCell.setgetN-1],0+0i,[],[0 0 0]);
SquareCell.drawSquare(sq);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')