classdef ControlParams %класс параметров управлени€
    
   properties
       IterCount {mustBeInteger, mustBePositive} %количество итераций
       SingleOrMultipleCalc logical %одиночный или множественный рассчет
       IsPaused logical = false % закончен ли один из этапов множественного рассчета
       ReRangeWindow(1,:) double % массив действительных значений параметра "окна" 
       ImRangeWindow(1,:) double % массив мнимых значений параметра "окна" 
       WindowParamName(1,:) char % название параметра "окна" 
       IsReady2Start logical = false% задан ли  ј
       SingleParamName(1,:) char % название одиночного параметра 
       SingleParamValue double % значение одиночного параметра 
       ImageFunc function_handle % отображение
       
       Periods (:,:) double % значени€ периодов 
       LastIters (:,:) double  % последн€€ итераци€
   end
   
   methods
       
       function obj=ControlParams(iterCount,singleOrMultipleCalc,reRangeWindow, imRangeWindow, windowParamName)
       
           if nargin
               obj.IterCount=iterCount;
               obj.SingleOrMultipleCalc=singleOrMultipleCalc;
               obj.ReRangeWindow=reRangeWindow;
               obj.ImRangeWindow=imRangeWindow;
               obj.WindowParamName=windowParamName;
           end
           
       end
       
   end
    
   methods(Static)
       
      % метод get-set дл€ статической переменной функции мультирасчета
       function out = GetSetMultiCalcFunc(func)
           persistent MultiCalcFunc;
           if nargin==1
               MultiCalcFunc = func;
           end
           out = MultiCalcFunc;
       end
       
       
      % метод get-set дл€ статической переменной функции мультирасчета
       function out = GetSetPrecisionParms(parms)
           persistent PrecisionParms;
           if nargin==1
               PrecisionParms = parms;
           end
           out = PrecisionParms;
       end
       
       %метод мультирасчета
       function [z_New fStepLast path] = MakeMultipleCalcIter(windowParam,z_Old,z_Old_1,itersCount,zParam)
           
           PrecisionParms = ControlParams.GetSetPrecisionParms;
           func=ControlParams.GetSetMultiCalcFunc;
           path=zeros(1,itersCount);
           path(1)=z_Old;
           fStepLast=1;
           while(fStepLast~=itersCount)
                       
               if log(z_Old)/(2.302585092994046)>=PrecisionParms(1) || abs(z_Old_1-z_Old)<PrecisionParms(2)
                   break;
               else
                   if zParam
                       z_New=func(windowParam);
                   else
                       z_New=func(windowParam,z_Old);
                   end
                   fStepLast=fStepLast+1;
               end
               z_Old_1 = z_Old;
               z_Old=z_New;
               path(fStepLast)=z_New;
               if zParam
                   windowParam=z_New;
               end
               
           end
           path={path};
%            delta=abs(z_Old_1-z_Old);
       end
       
%        function [z_new fStepNew]= MakeMultipleCalcIter(windowParam,z_old,z_old_1,fStepOld,zParam)
%            if log(z_old)/(2.302585092994046)<15 && abs(z_old_1-z_old)>=1e-5
%                func=ControlParams.GetSetMultiCalcFunc;
%                if zParam
%                    z_new=func(windowParam);
% %                    z_new=base{1}(windowParam);
%                else
%                    z_new=func(windowParam,z_old);
% %                    z_new=base{1}(windowParam,z_old);
%                end
%                fStepNew=fStepOld+1;
%            else
%                z_new=z_old;
%                fStepNew=fStepOld;
%            end
%        end
       
       %метод создани€ окна и матрицы функций базы
       function [WindowParam ContParms] = MakeFuncsWithNumsForMultipleCalc(ca,contParms)
           format long;
           [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           WindowParam=X+i*Y;
           switch contParms.WindowParamName
               case {'Z0' 'Z' 'z0' 'z'} % в случае окна по Z0 создание матрицы функций базы,с вставкой одного значени€ ћю
                   
                   SingleParamStr=strcat('(',num2str(contParms.SingleParamValue));
                   SingleParamStr=strcat(SingleParamStr,')');
                   
                   zBaseStr=strcat('(',num2str(ca.Zbase));
%                    zBaseStr=strcat('(',num2str(0.576412723031435+i*0.374699020737117));
%                    z=-2.989980000000000 - i*0.456820000000000;
%                    z=0.576412723031435+i*0.374699020737117;
%                    zBaseStr=strcat('(',num2str(z));
                   zBaseStr=strcat(zBaseStr,')');
                   
                   contParms.ImageFunc=@(z)(1+ Miu*abs(z-eq))*exp(i*z);
                   baseFuncStr=strrep(func2str(@(z)(1+ Miu*abs(z-eq))*exp(i*z)), contParms.SingleParamName,SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'c',SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'Miu',SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'eq',zBaseStr);
                   
                   baseFuncStr=str2func(baseFuncStr);
                   
%                    baseFuncStrs=cell(size(WindowParam));
%                    baseFuncStrs(:)={baseFuncStr};
                   
               case {'Miu','Mu','ћю'} % в случае окна по ћю создание матрицы функций базы, где множитель каждой функции - соответствующее значение ћю из диапазона
%                    profile on;
%                    paramsStrs = arrayfun(@(param){strcat('(',num2str(param))},WindowParam);
%                    paramsStrs = arrayfun(@(param){strcat(cell2mat(param),')')},paramsStrs);
                   
%                    baseFuncStr=func2str(@(Miu,z)(1+ Miu*abs(z-eq))*exp(i*z));
                   baseFuncStr=func2str(@(Miu,z)Miu*exp(i*z));
                   contParms.ImageFunc=str2func(baseFuncStr);
                   zBaseStr=strcat('(',num2str(ca.Zbase));
%                    z=-2.989980000000000 - 0.456820000000000i;
%                    z=0.576412723031435+i*0.374699020737117;
%                    zBaseStr=strcat('(',num2str(z));
                   zBaseStr=strcat(zBaseStr,')');
                   baseFuncStr=strrep(baseFuncStr,'eq',zBaseStr);
                   
%                    zStr=strcat('(',num2str(0));
%                    zStr=strcat(zStr,')');
%                    baseFuncStr=strrep(baseFuncStr,'z',zStr);
                   baseFuncStr=str2func(baseFuncStr);
                   
%                    baseFuncStrs=cell(size(WindowParam));
%                    baseFuncStrs(:)={baseFuncStr};
%                    
%                    baseFuncStrs = arrayfun(@(base,param)strrep(cell2mat(base),'Miu',param),baseFuncStrs,paramsStrs);
%                    baseFuncStrs = arrayfun(@(base,param)strrep(cell2mat(base),'c',param),baseFuncStrs,paramsStrs);
%                    
%                    baseFuncStrs = arrayfun(@(base){str2func(cell2mat(base))},baseFuncStrs);
%                    profile viewer;
           end
           ControlParams.GetSetMultiCalcFunc(baseFuncStr);
           ContParms=contParms;
%            BaseFuncStr=baseFuncStr;
%            baseFuncStrs=cell(size(WindowParam));
%            baseFuncStrs(:)={baseFuncStr};
       end
       
       function [fCodeNew iter period] = CheckConvergence(path)
           
           fCodeNew=[];
           PrecisionParms=ControlParams.GetSetPrecisionParms;
           
           path=cell2mat(path);
           path=path(find(path));
           if (log(path(end))/log(10)>PrecisionParms(1)) || isnan(path(end)) || isinf(path(end)) %бесконечность
               fCodeNew=-1;
               iter=length(path);
               period=Inf;
               return;
           end
           
           %сходимость
           c=2:length(path);
           converg = abs(path(c-1) - path(c)) < PrecisionParms(2);
           if any(converg)
               iter=c(find(converg,1,'first'));
               fCodeNew=1;
               period=1;
               return;
           end
           
           %период
           for p=2:30
               k=p+1:length(path);
               prd = abs(path(k)-path(k-p)) < PrecisionParms(2);
               if any(prd)
                   iter=k(find(prd,1,'first'));
                   fCodeNew=3;
                   period=p;
                   return;
               end
           end
           
%            if abs(path(end-1)-path(end)) < 1e-2 %хаос
%                fCodeNew=2;
%                iter=length(path);
%                return;
%            end
           
           fCodeNew=2;
           iter=length(path);
           period=0;
       end
       
   end

end