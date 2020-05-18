function [tr, fin] = Julia(flag, choice, mu0, Depth, Region, Point) 
%% Построение множеств Жюлиа и Фату.
% Формат вызова [tr, FJ] = Julia(2, 3, 1+2i, [200 400 600], [-5 5;-5 5], [0 0]);
% tr - вектор-орбита точки, координаты х и у которой задаются Point;
% fin - судьбы орбит, в 3-м измерении - 1й слой - код завершения, 
% 2й - номер хода, 3й - последнее значение орбиты.
% Код завершения: 0 - уход в бесконечность, 1 - сходимость к равновесию, 2 -
% медленное схождение к равновесию, когда число итераций больше глубины расчёта, 3 - хаотическая 
% или квазипериодическая орбита.
% flag: если аргумент равен 0, то просчитывается только орбита, рисуется её график; если равен 1, то 
% просчитывается только множество Жюлиа; если равен 2, то выполняются обе операции.
% сhoice - выбор функции (map) из трех, зависящей от параметра mu0.
% Depth - глубина расчёта трёхэлментным вектором: 1 - число точек по х, 2 - по y, 3 - максимальная 
% длина орбиты (шагов по t).
%%

%constants
eq=0.576412723031435+1i*0.374699020737117; %eq2 = 0.373217667547526 +  1i*0.580971149430551;
eps1=1e-5; eps2=1e-3; ColorOrbit=[1 0 0; 1 0.5 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1]; orbita=zeros(Depth(3)+1,1);
%functions
func1 = @(z)(1+ mu0*abs(z-eq))*exp(1i*z); func2 = @(z) exp(1i*z);  func3 = @(z) mu0*exp(1i*z);
switch(choice)
    case 1 
        func=func1;
    case 2 
        func=func2;
    case 3 
        func=func3;
    otherwise
        func=@(z) z.^2+mu0;
end

switch (flag)
    case 0
        ViewOrbit(); tr=orbita; fin=0;
    case 1
        tr=0;  FatouJulia(1);
    case 2
        ViewOrbit(); tr=orbita; FatouJulia(2);
    otherwise
        tr=0; fin=0; error('Первый аргумент: 0-1-2 ?');
end

    function [dest,num,last] = Orbit (z0)
       orbita(1)=z0; step = 0;
       while(1)
           step = step + 1; orbita(step+1) = func(orbita(step));
           if (~isfinite(orbita(step+1)))
               dest=0; num=step; last=orbita(step); 
               break
           end;
           if (abs(orbita(step+1)-orbita(step))<eps1)
               dest=1; num=step; last=orbita(step); 
               break
           end;
           if (step > Depth(3))
               num=step;  last=orbita(step);
               if (abs(orbita(step+1)-orbita(step))<eps2)
                dest=2;
               else dest=3;
               end
             break;
           end;  end;  end
    
    function ViewOrbit ()
        [c1,c2,last] = Orbit(Point(1)+1i*Point(2)); N=size(ColorOrbit,1); len=ceil(c2/N);  base=1:N;
        base=ones(len,1)*base;  radius=round(100./base(1:c2)); color_orbita=ColorOrbit(base(:),:);  figure(1);
        color_orbita = color_orbita(1:c2,:); scatter(real(orbita(1:c2)),imag(orbita(1:c2)), radius(1:c2), color_orbita);
        grid on;   title('Orbit of z=(0,0)');
    end

    function FatouJulia(way)
       tic;  [X,Y]=meshgrid(linspace(Region(1,1),Region(1,2),Depth(1)+1), linspace(Region(2,1),Region(2,2),...
      Depth(2)+1));  Z=X+i*Y;  temp=zeros(size(Z));  fin=cat(3,temp,temp,temp);    clear('temp');  
      [fin(:,:,1),fin(:,:,2),fin(:,:,3)]=arrayfun(@Orbit,Z);  toc;  ViewFJ(way);
       
       function ViewFJ(way)
           ncolor=128;
        switch(way)
            case 1
                temp=(fin(:,:,1)==0);   temp1=(1-2*temp).*fin(:,:,2); 
                nc_inf=ceil(ncolor*abs(min(temp1(:)))/max(temp1(:)));  figure(2);
                colormap([flipud(gray(nc_inf));flipud(parula(ncolor))]);
                contourf(X,Y,temp1,'LineStyle', 'none');  grid('on');  colorbar;
                
            case 2
                info_dest=zeros(5,4); sfin=size(fin);  sf=sfin(1)*sfin(2); 
                shift_fin=zeros(sfin(1),sfin(2)); temp=ones(1,sf);
                for dest=0:3
                   temp=find((fin(1:sf)==dest));
                   if (~isempty(temp))
                      info_dest(1,dest+1)=max(fin(sf+temp))+1; info_dest(2,dest+1)=min(fin(sf+temp));
                   else
                      info_dest(1,dest+1)=1;info_dest(2,dest+1)=0; 
                   end
                   info_dest(5,dest+1)=nnz(temp);  shift_fin(temp)=dest;
                end
                info_dest(3,:)=[0 cumsum(info_dest(1:3))];   info_dest(4,:)=info_dest(1,:)-info_dest(2,:);
                temp=sum(info_dest(4,:));   info_dest(4,:)=ceil(ncolor/temp*info_dest(4,:));
                Cnames={'gray','winter','hot','autumn'};  Cmap=[];
                for dest=(0:3)+1
                   eval(strcat('temp=',Cnames{dest},'(',num2str(info_dest(4,dest)),');'));   Cmap=[Cmap;temp];
                end
                % Суммарно по полю: по столбцам - коды, по строкам
                % max, min элементы, сдвиг элемента, число цветов, общее число  элементов такого рода.
                info_dest,  figure(3);  colormap(jet(4));   title(gca,'faceted');   shading flat;   pha=pcolor(X,Y,shift_fin);
                set(pha, 'EdgeColor', 'none');   grid on;  colorbar;  ffin=@(a) info_dest(3,a+1);
                shift_fin=fin(:,:,2)+arrayfun(ffin,shift_fin);   figure(4);   title(gca,'FatouJuliaSets'); colormap(Cmap);  
                ph=pcolor(X,Y,shift_fin);   set(ph, 'EdgeColor', 'none');   shading flat;  colorbar;    grid on;
        end; end;  end;  end
