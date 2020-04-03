clc;
clear;

%% ��������� ��������������� ���� � ������������� �����������
figure; 
hold on;

HexagonCell.setgetFieldOrient(1); % ������� ��������������� ����
HexagonCell.setgetHexOrient(1); % ������� ������������ ���������� ����������
HexagonCell.setgetN(5);% ������� N

for k=1:3
    for j = 0:HexagonCell.setgetN-1
        
        for i = 1:HexagonCell.setgetN-1
            hex=HexagonCell([i j k],0+0i, [], [randi(255) randi(255) randi(255)]);
            drawHexagon(hex); % ������ �������� ��������
        end
    end
end

%��������� ������ ��������� � ������ ���������
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex);

%��������� ������� ���������
hex=HexagonCell([4 1 1],0+0i, [], [0 0 0]);
drawHexagon(hex);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')


figure; 
hold on;
%% ��������� ��������������� ���� � ��������������� �����������

HexagonCell.setgetHexOrient(0);% ������� �������������� ���������� ����������
HexagonCell.setgetN(5);% ������� N

for k=1:3
    for j = 0:HexagonCell.setgetN-1
        
        for i = 1:HexagonCell.setgetN-1
            hex=HexagonCell([i j k],0+0i, [], [randi(255) randi(255) randi(255)]);
            drawHexagon(hex); % ������ �������� ��������
        end
    end
end

%��������� ������ ��������� � ������ ���������
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex);


%��������� �������� ���������
hex=HexagonCell([4 4 1],0+0i, [], [255 0 0]);
drawHexagon(hex);
%��������� �������� ���������
hex=HexagonCell([4 4 2],0+0i, [], [0 255 0]);
drawHexagon(hex);
%��������� ������ ���������
hex=HexagonCell([4 4 3],0+0i, [], [0 0 255]);
drawHexagon(hex);

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')
%% ��������� ����������� ���� � ��������������� �����������


figure; 
hold on;
HexagonCell.setgetFieldOrient(0); % ������� ����������� ����
HexagonCell.setgetHexOrient(0); % ������� �������������� ���������� ����������
HexagonCell.setgetN(5);% ������� N



%������� ���� ������ ��� ��������� ���� ����������
for x = 0:HexagonCell.setgetN-1

    for y = 0:HexagonCell.setgetN-1
        hex=HexagonCell([x y 0],0+0i, [], [randi(255) randi(255) randi(255)]);
        drawHexagon(hex) % ������ �������� ��������
    end
    
end

%��������� ������ ��������� � ������ ���������
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex)

%��������� ������� ��������� � � ������������� ������������
hex=HexagonCell([HexagonCell.setgetN-1 HexagonCell.setgetN-1 0],0+0i, [], [0 0 0]);
drawHexagon(hex)

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')

%% ��������� ����������� ���� � ������������� �����������

figure; 
hold on;
HexagonCell.setgetHexOrient(1);% ������� ������������ ���������� ����������
HexagonCell.setgetN(5);% ������� N


%������� ���� ������ ��� ��������� ���� ����������
for x = 0:HexagonCell.setgetN-1

    for y = 0:HexagonCell.setgetN-1
        hex=HexagonCell([x y 0],0+0i, [], [randi(255) randi(255) randi(255)]);
        drawHexagon(hex) % ������ �������� ��������
    end
    
end

%��������� ������ ��������� � ������ ���������
hex=HexagonCell([0 0 0],0+0i, [], [255 255 255]);
drawHexagon(hex)

%��������� ������� ��������� � � ������������� ������������
hex=HexagonCell([HexagonCell.setgetN-1 HexagonCell.setgetN-1 0],0+0i, [], [0 0 0]);
drawHexagon(hex)

axis image
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'Visible','off')
%%