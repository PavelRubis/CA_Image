% ������������ ����������� �� ���� �� ������� "���� �����" 
clear;
clc;

%����� ������� ��
n=10;

figure;
%������� �� (������� ������� n)
grid=zeros(n);
grid(4,4)=1;
grid(5,5)=1;
grid(6,5)=1;
grid(6,4)=1;
grid(6,3)=1;
grid(2,8)=1;
length(grid);

%������� ��� ��������� ��
dispgrid=grid;

%������ �������� ������� ��� ���������� ���������
for j=1:n
    dispgrid(:,j)=fliplr(dispgrid(:,j)')';
end

dispgrid = [dispgrid; zeros(1, n)];
dispgrid = [dispgrid, zeros(n+1, 1)];

%�������� �� �������
cmap = colormap;
cmap(1,:) = 1;
cmap(2:end,:) = 0;
colormap(cmap);

%��������� ���� �� � ����� ������� ����� � ����������� �� ��������(0 ��� 1)
h = pcolor(dispgrid);%�������� ������� - ������������� ������� �� � �����������
axis square
shading flat
set(gca, 'XTick', [])
set(gca, 'YTick', [])