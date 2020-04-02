clear; clc;

% равновесия
eq=0.576412723031435+i*0.374699020737117;mu0=0.25;
eq1=5.55491-i*1.31303;eq_1=eq1+eq;
eq2=-9.895815-i*1.360390;eq_2=eq+eq2;
alfa=-1/6;

% функции
mapz=@(z) (1+mu0*abs(z-eq)).*exp(i*z)
Fw=@(w) eq*(exp(i*w)-1)+mu0*eq*abs(w).*exp(i*w)-w;
Fcp=@(cp) [(1+mu0*abs(cp(2)-eq)).*exp(i*cp(1)); (1+mu0*abs(5/6*cp(2)+1/6*cp(1)-eq)).*exp(i*cp(2))];
mapz_zero=@(z) abs(mapz(z)-z)
twoosci1=@(p,ksi) exp(i*p)-p.*(1+mu0*abs(p-alfa*ksi-eq))
twoosci2=@(p,ksi) (1+mu0*abs(p-eq)).*exp(i*ksi)./(1+mu0*abs(p-alfa*ksi-eq))
twoosci=@(ksi) abs(twoosci1(alfa*ksi,ksi))+abs(twoosci2(alfa*ksi,ksi))


% исправленное моноравновесие
x=-30:0.1:30;y=-2:0.1:2;
[X,Y]=meshgrid(x,y);Z=X+i*Y;aFw=mapz_zero(Z);
contourf(X,Y,aFw);colorbar;

% юстировка моноравновесия
z0=-3.5+0.5*i;
mapz_zero_xy=@(z) mapz_zero(z(1)+i*z(2));
[zeq,zer]=fminsearch(mapz_zero_xy, [real(z0) imag(z0)],optimset('TolX',1e-6));
[zeq zer]

% окно по Fw
x=3:0.1:5;y=-1:0.1:2;
[X,Y]=meshgrid(x,y);Z=X+i*Y;aFw=abs(Fw(Z));
contourf(X,Y,aFw);colorbar;

% ручками устойчивость
N=10;dz=0.01+0.01*i;dzeta=zeros(1+N,1);dzeta(1)=eq_2+dz;
for k=1:N
dzeta(k+1)=mapz(dzeta(k));    
end;
dzeta

% неоднород
clc;NN=10000;L=10;N=20;dzeta=zeros(2,N+1);
S=L*(rand(4*NN,1)-1/2);Res=zeros(NN,4);
for s=1:NN
        dzeta(1,1)=S(s)+i*S(s+NN);dzeta(2,1)=S(s+2*NN)+i*S(s+3*NN);
        for k=1:N
            dzeta(:,k+1)=Fcp(dzeta(:,k));    
        end;
        Res(s,:)=[dzeta(1,1) dzeta(2,1) dzeta(1,end) dzeta(2,end)];
end
ind=find(abs(Res(:,3)-real(eq))>0.25)

% неоднор равновесие на линии, нету
x=2.70:0.01:2.725;y=1.25:0.001:1.35; [X,Y]=meshgrid(x,y);Z=X+i*Y;
contourf(X,Y,twoosci(Z));colorbar;

% двупериодич

twoper1=@(p) (0-i)*(log(p.*exp(-i*p))-log(1+mu0*abs(p-eq)))
twoper2=@(p,ksi) abs((p+ksi).*exp(-i*p)-(1+mu0*abs(p-eq+ksi/6)))

x=3:0.1:5;y=-1:0.1:2;a=2*pi*0;
[X,Y]=meshgrid(x,y);Z=X+i*Y;
F2per=twoper2(Z,a+twoper1(p));
contourf(X,Y,F2per);colorbar;

