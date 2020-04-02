% визуализация квадратного КА поля на примере "Игра жизнь" 
clear;
clc;

%Ребро решетки КА
n=10;

figure;
%решетка КА (матрица порядка n)
grid=zeros(n);
grid(4,4)=1;
grid(5,5)=1;
grid(6,5)=1;
grid(6,4)=1;
grid(6,3)=1;
grid(2,8)=1;
length(grid);

%Решетка для отрисовки КА
dispgrid=grid;

%реверс столбцов решетки для правильной отрисовки
for j=1:n
    dispgrid(:,j)=fliplr(dispgrid(:,j)')';
end

dispgrid = [dispgrid; zeros(1, n)];
dispgrid = [dispgrid, zeros(n+1, 1)];

%созлание чб палитры
cmap = colormap;
cmap(1,:) = 1;
cmap(2:end,:) = 0;
colormap(cmap);

%отрисовка поля КА с двумя цветами ячеек в зависимости от значения(0 или 1)
h = pcolor(dispgrid);%ключевая команда - представление решетки КА в псевдоцвете
axis square
shading flat
set(gca, 'XTick', [])
set(gca, 'YTick', [])