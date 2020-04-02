% ∆юлиа
clear; clc;

%constants
% mu0 = 2.5*i;
mu0=0.25;
eq=0.576412723031435+i*0.374699020737117;
eq2 = 0.373217667547526 +     0.580971149430551*i;
maxStep = 1000; % ограничитель максимального числа итераций дл€ данной точки. 
%функци€
func = @(z)(1+ mu0*abs(z-eq))*exp(i*z);


ax = -10; %лева€ граница промежутка по х
bx = 10; %права€ граница промежутка по х
ay = -10; %нижн€€ граница промежутка по у
by = 2; %верхн€€ граница промежутка по у
N = 1000; %(N+1)*(N+1) - общее количество точек вычислительной сетки на всем поле
hx = (bx-ax)/N;
hy = (by-ay)/N;

x = ax : hx : bx;
y = ay : hy : by;
[X,Y]=meshgrid(x,y);Z=X+i*Y;

fcode = zeros(size(Z));
fstep = zeros(size(Z));

for k=1:1:N+1 %номер строки
    for l = 1:1:N+1 %номер столбца
        
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


%построение
figure;
clmp = [flipud(gray(128));flipud(parula(128))];
colormap(clmp);
contourf(X, Y, (fstep.*fcode), 'LineStyle', 'none');
colorbar;
grid on;
string_legend = strcat('Julia','\mu_0=',num2str(mu0));
legend(string_legend);
legend('show');


