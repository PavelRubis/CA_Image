clc;
clear;

figure; 
hold on;

% задание вертикальной ориентации и N=5
HexagonCell.setgetOrient(1);
HexagonCell.setgetN(5);

for k=1:3
    for j = 0:HexagonCell.setgetN-1
        
        for i = 1:HexagonCell.setgetN-1
            hex=HexagonCell([i j k],0+0i, [], [randi(255) randi(255) randi(255)]);
            drawHexagon(hex); % каждый рисуется отдельно
        end
    end
end

hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')



figure; 
hold on;
% задание горизонтальной ориентации и N=5
HexagonCell.setgetOrient(0);
HexagonCell.setgetN(10);


%двойной цикл только для отрисовки поля гексагонов

for x = 0:HexagonCell.setgetN-1

    for y = 0:HexagonCell.setgetN-1
        hex=HexagonCell([x y 0],0+0i, [], [randi(255) randi(255) randi(255)]);
        drawHexagon(hex) % каждый рисуется отдельно
    end
    
end

%отрисовка белого гексагона в поле
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex)

hex=HexagonCell([HexagonCell.setgetN-1 HexagonCell.setgetN-1 0],0+0i, [], [0 0 0]);
drawHexagon(hex)

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')