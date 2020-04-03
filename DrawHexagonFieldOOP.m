clc;
clear;

%% отрисовка гексагонального поля с вертикальными гексагонами
figure; 
hold on;

HexagonCell.setgetFieldOrient(1); % задание гексагонального поля
HexagonCell.setgetHexOrient(1); % задание вертикальной ориентации гексагонов
HexagonCell.setgetN(5);% задание N

for k=1:3
    for j = 0:HexagonCell.setgetN-1
        
        for i = 1:HexagonCell.setgetN-1
            hex=HexagonCell([i j k],0+0i, [], [randi(255) randi(255) randi(255)]);
            drawHexagon(hex); % каждый рисуется отдельно
        end
    end
end

%отрисовка белого гексагона в начале координат
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex);

%отрисовка черного гексагона
hex=HexagonCell([4 1 1],0+0i, [], [0 0 0]);
drawHexagon(hex);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')


figure; 
hold on;
%% отрисовка гексагонального поля с горизонтальными гексагонами

HexagonCell.setgetHexOrient(0);% задание горизонтальной ориентации гексагонов
HexagonCell.setgetN(5);% задание N

for k=1:3
    for j = 0:HexagonCell.setgetN-1
        
        for i = 1:HexagonCell.setgetN-1
            hex=HexagonCell([i j k],0+0i, [], [randi(255) randi(255) randi(255)]);
            drawHexagon(hex); % каждый рисуется отдельно
        end
    end
end

%отрисовка белого гексагона в начале координат
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex);


%отрисовка красного гексагона
hex=HexagonCell([4 4 1],0+0i, [], [255 0 0]);
drawHexagon(hex);
%отрисовка зеленого гексагона
hex=HexagonCell([4 4 2],0+0i, [], [0 255 0]);
drawHexagon(hex);
%отрисовка синего гексагона
hex=HexagonCell([4 4 3],0+0i, [], [0 0 255]);
drawHexagon(hex);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')
%% отрисовка квадратного поля с горизонтальными гексагонами


figure; 
hold on;
HexagonCell.setgetFieldOrient(0); % задание квадратного поля
HexagonCell.setgetHexOrient(0); % задание горизонтальной ориентации гексагонов
HexagonCell.setgetN(5);% задание N



%двойной цикл только для отрисовки поля гексагонов
for x = 0:HexagonCell.setgetN-1

    for y = 0:HexagonCell.setgetN-1
        hex=HexagonCell([x y 0],0+0i, [], [randi(255) randi(255) randi(255)]);
        drawHexagon(hex) % каждый рисуется отдельно
    end
    
end

%отрисовка белого гексагона в начале координат
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex)

%отрисовка черного гексагона в с максимальными координатами
hex=HexagonCell([HexagonCell.setgetN-1 HexagonCell.setgetN-1 0],0+0i, [], [0 0 0]);
drawHexagon(hex)

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')

%% отрисовка квадратного поля с вертикальными гексагонами

figure; 
hold on;
HexagonCell.setgetHexOrient(1);% задание вертикальной ориентации гексагонов
HexagonCell.setgetN(5);% задание N


%двойной цикл только для отрисовки поля гексагонов
for x = 0:HexagonCell.setgetN-1

    for y = 0:HexagonCell.setgetN-1
        hex=HexagonCell([x y 0],0+0i, [], [randi(255) randi(255) randi(255)]);
        drawHexagon(hex) % каждый рисуется отдельно
    end
    
end

%отрисовка белого гексагона в начале координат
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex)

%отрисовка черного гексагона в с максимальными координатами
hex=HexagonCell([HexagonCell.setgetN-1 HexagonCell.setgetN-1 0],0+0i, [], [0 0 0]);
drawHexagon(hex)

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')
%%