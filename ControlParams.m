classdef ControlParams %класс параметров управления и множественного элементарного расчета
    
   properties
       IterCount double {mustBeInteger, mustBePositive} %количество итераций
       SingleOrMultipleCalc logical %одиночный или множественный рассчет
       ReRangeWindow  (1,:) double % массив действительных значений параметра "окна" 
       ImRangeWindow  (1,:) double % массив мнимых значений параметра "окна" 
       WindowParamName  (1,:) char % название параметра "окна" 
       WindowCenterValue double % центральная точка окна
       SingleParams  (1,2) double % одиночные параметры мультирасчета
       IsReady2Start logical = false% задан ли КА
       ImageFunc function_handle % отображение для множественного расчета
       Lambda (1,:) char % множитель лямбда перед отображением exp(i*z) 
       
       Periods  (:,:) double % значения периодов 
       LastIters  (:,:) double % последняя итерация
   end
   
   methods
       
       function obj=ControlParams(iterCount,singleOrMultipleCalc,reRangeWindow, imRangeWindow, windowParamName,imageFunc,lambda)
       
           if nargin
               obj.IterCount=iterCount;
               obj.SingleOrMultipleCalc=singleOrMultipleCalc;
               obj.ReRangeWindow=reRangeWindow;
               obj.ImRangeWindow=imRangeWindow;
               obj.WindowParamName=windowParamName;
               obj.ImageFunc=imageFunc;
               obj.Lambda=lambda;
           end
           
       end
       
   end
    
   methods(Static)
       
      % метод get-set для статической переменной функции мультирасчета
       function out = GetSetMultiCalcFunc(func)
           persistent MultiCalcFunc;
           if nargin==1
               MultiCalcFunc = func;
           end
           out = MultiCalcFunc;
       end
       
       
      % метод get-set для статической переменной порогов точности
       function out = GetSetPrecisionParms(parms)
           persistent PrecisionParms;
           if nargin==1
               PrecisionParms = parms;
           end
           out = PrecisionParms;
       end
       
      % метод get-set для статической переменной максимального периода в мультирасчете
       function out = GetSetMaxPeriod(mp)
           persistent MaxPeriod;
           if nargin==1
               MaxPeriod = mp;
           end
           out = MaxPeriod;
       end
       
      % метод get-set для статической переменной-флага пользовательского отображения
       function out = GetSetCustomImag(customBase)
           persistent CustomBase;
           if nargin==1
               CustomBase = customBase;
           end
           out = CustomBase;
       end
       
       %метод мультирасчета
       function [z_New fStepLast path] = MakeMultipleCalcIter(windowParam,z_Old,z_Old_1,itersCount,zParam,z_eq)
           PrecisionParms = ControlParams.GetSetPrecisionParms;
           func=ControlParams.GetSetMultiCalcFunc;
           path=nan(1,itersCount);
           path(1)=z_Old;
           fStepLast=1;
           while(fStepLast~=itersCount)
                       
               if log(z_Old)/(2.302585092994046)>=PrecisionParms(1) || abs(z_Old_1-z_Old)<PrecisionParms(2)
                   break;
               else
                   if zParam
                       z_New=func(windowParam);
                   else
                       z_New=func(windowParam,z_Old,z_eq);
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
       end
       
       %метод создания окна и матрицы функций базы
       function [WindowParam ContParms z_eqArr] = MakeFuncsWithNumsForMultipleCalc(ca,contParms)
           format long;
           [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           WindowParam=X+i*Y;
           z_eqArr=Inf(size(WindowParam));
           switch contParms.WindowParamName
               case 'z0' % в случае окна по Z0
                   
                   zBaseStr=strcat('(',num2str(ca.Zbase));
                   zBaseStr=strcat(zBaseStr,')');
                   
                   Miu0Str=strcat('(',num2str(ca.Miu0));
                   Miu0Str=strcat(Miu0Str,')');
                   
                   MiuStr=strcat('(',num2str(ca.Miu));
                   MiuStr=strcat(MiuStr,')');
                   
                   contParms.ImageFunc=str2func(strrep(func2str(contParms.ImageFunc),'@(Miu0,z,eq)','@(z)'));
                   contParms.ImageFunc=str2func(strrep(func2str(contParms.ImageFunc),'@(Miu,z,eq)','@(z)'));
                   contParms.ImageFunc=str2func(strrep(func2str(contParms.ImageFunc),'@(Miu,z)','@(z)'));
                   baseFuncStr=strrep(func2str(contParms.ImageFunc),'Miu0',Miu0Str);
                   baseFuncStr=strrep(baseFuncStr, 'Miu',MiuStr);
                   baseFuncStr=strrep(baseFuncStr,'eq',zBaseStr);
                   
               case 'Miu' % в случае окна по Мю
                   
                   baseFuncStr=func2str(contParms.ImageFunc);
                   baseFuncStr=strrep(baseFuncStr,'@(z)','@(Miu,z,eq)');
                   baseFuncStr=strrep(baseFuncStr,'@(Miu,z)','@(Miu,z,eq)');
                   baseFuncStr=strrep(baseFuncStr,'@(Miu0,z,eq)','@(Miu,z,eq)');
                   contParms.ImageFunc=str2func(baseFuncStr);
                   
                   Miu0Str=strcat('(',num2str(ca.Miu0));
                   Miu0Str=strcat(Miu0Str,')');
                   baseFuncStr=strrep(baseFuncStr,'Miu0',Miu0Str);
                   
                   pureFuncStr=regexprep(baseFuncStr,'@\(.+\)','');
                   
                   if contains(pureFuncStr,'eq')
                       z0Arr=zeros(size(WindowParam));
%                        ControlParams.GetSetMultiCalcFunc(baseFuncStr);
                       z0Arr(:) = ControlParams.CountZBaze(contParms.WindowCenterValue,-3.5+0.5*i);
                       z_eqArr=arrayfun(@ControlParams.CountZBaze,WindowParam,z0Arr);
                   end
               
               case 'Miu0' % в случае окна по Мю0
                   
                   baseFuncStr=func2str(contParms.ImageFunc);
                   
                   baseFuncStr=strrep(baseFuncStr,'@(z)','@(Miu0,z,eq)');
                   baseFuncStr=strrep(baseFuncStr,'@(Miu,z)','@(Miu0,z,eq)');
                   baseFuncStr=strrep(baseFuncStr,'@(Miu,z,eq)','@(Miu0,z,eq)');
                   contParms.ImageFunc=str2func(baseFuncStr);
                  
                   MiuStr=strcat('(',num2str(ca.Miu));
                   MiuStr=strcat(MiuStr,')');
                   
                   zBaseStr=strcat('(',num2str(ca.Zbase));
                   zBaseStr=strcat(zBaseStr,')');
                   
                   baseFuncStr=regexprep(baseFuncStr,'Miu(?=\D)',MiuStr);
                   baseFuncStr=regexprep(baseFuncStr,'Miu$',MiuStr);
                   baseFuncStr=regexprep(baseFuncStr,'(?<!,)eq',zBaseStr);
                   
           end
           baseFuncStr=str2func(baseFuncStr);
           ControlParams.GetSetMultiCalcFunc(baseFuncStr);
           ContParms=contParms;
       end
       
       function [z_eq] = CountZBaze(miu,z0)
           
           persistent func
           if isempty(func)
               func=@(z)(Miu)*exp(i*z);
           end
           
           MiuStr=num2str(miu);
           FbaseStr=strrep(func2str(func),'Miu',MiuStr);
           Fbase=str2func(FbaseStr);
    
           mapz_zero=@(z) abs(Fbase(z)-z);
%            mapz_zero=Fbase;
           mapz_zero_xy=@(z) mapz_zero(z(1)+i*z(2));
           [zeq,zer]=fminsearch(mapz_zero_xy, [real(z0) imag(z0)],optimset('TolX',1e-9));
           z_eq = complex(zeq(1),zeq(2));
       end
       
       function [fCodeNew iter period] = CheckConvergence(path)
           
           fCodeNew=[];
           PrecisionParms=ControlParams.GetSetPrecisionParms;
           MaxPeriod=ControlParams.GetSetMaxPeriod;
           
           if iscell(path)
               path=cell2mat(path);
           end
           
           path=path(find(~isnan(path)));
           
           if isempty(path)
               path=0;
           end
           if (log(path(end))/log(10)>PrecisionParms(1)) || isnan(path(end)) || isinf(path(end)) %бесконечность
               fCodeNew=-1;
               iter=length(path);
               period=0;
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
           for p=2:MaxPeriod
               if p>=length(path)
                   break;
               end
               k=p+1:length(path);
               prd = abs(path(k)-path(k-p)) < PrecisionParms(2);
               if any(prd)
                   iter=k(find(prd,1,'first'));
                   fCodeNew=3;
                   period=p;
                   return;
               end
           end
           
           fCodeNew=2;
           iter=length(path);
           period=Inf;
       end
       
   end

end