% �����
clear; clc;

%constants
% mu0 = 2.5*i;
mu0=0.25;
eq=0.576412723031435+i*0.374699020737117;
eq2 = 0.373217667547526 +     0.580971149430551*i;
maxStep = 1000; % ������������ ������������� ����� �������� ��� ������ �����. 
%�������
func = @(z)(1+ mu0*abs(z-eq))*exp(i*z);


ax = -10; %����� ������� ���������� �� �
bx = 10; %������ ������� ���������� �� �
ay = -10; %������ ������� ���������� �� �
by = 2; %������� ������� ���������� �� �
N = 1000; %(N+1)*(N+1) - ����� ���������� ����� �������������� ����� �� ���� ����
hx = (bx-ax)/N;
hy = (by-ay)/N;

x = ax : hx : bx;
y = ay : hy : by;
[X,Y]=meshgrid(x,y);Z=X+i*Y;

fcode = zeros(size(Z));
fstep = zeros(size(Z));

for k=1:1:N+1 %����� ������
    for l = 1:1:N+1 %����� �������
        
        step = 0;
        
        while(1)
            oldZ = Z(l,k);
            Z(l,k)= func(Z(l,k));
        
            step = step + 1;
        
            if(abs(oldZ-Z(l,k))<1e-5)
                fcode(l,k) = 1; %attractor
                fstep(l,k) = step;
                break;
            end
        
            if(isinf(Z(l,k))) %infinity 
                fcode(l,k)=-1;
                fstep(l,k) = step;
                break;
            end
        
            if (step > maxStep)
                fcode(l,k)=0;
                fstep(l,k) = maxStep;
                break;
            end
        end
    end
end


%����������
figure;
clmp = [flipud(gray(128));flipud(parula(128))];
colormap(clmp);
contourf(X, Y, (fstep.*fcode), 'LineStyle', 'none');
colorbar;
grid on;
string_legend = strcat('Julia','\mu_0=',num2str(mu0));
legend(string_legend);
legend('show');


