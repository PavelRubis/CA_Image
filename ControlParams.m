classdef ControlParams %класс параметров управления
    
   properties
       IterCount {mustBeInteger, mustBePositive} %количество итераций
       SingleOrMultipleCalc logical %одиночный или множественный рассчет
       IsPaused logical = false % закончен ли один из этапов множественного рассчета
       ReRangeWindow(1,:) double % массив действительных значений параметра "окна" 
       ImRangeWindow(1,:) double % массив мнимых значений параметра "окна" 
       WindowParamName(1,:) char % название параметра "окна" 
       IsReady2Start logical = false% задан ли КА
       SingleParamName(1,:) char % название одиночного параметра 
       SingleParamValue double % значение одиночного параметра 
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
       
      % метод get-set для статической переменной функции мультирасчета
       function out = GetSetMultiCalcFunc(func)
           persistent MultiCalcFunc;
           if nargin==1
               MultiCalcFunc = func;
           end
           out = MultiCalcFunc;
       end
       
       
      % метод get-set для статической переменной функции мультирасчета
       function out = GetSetPrecisionParms(parms)
           persistent PrecisionParms;
           if nargin==1
               PrecisionParms = parms;
           end
           out = PrecisionParms;
       end
       
       %метод мультирасчета
       function [z_New fStepLast delta] = MakeMultipleCalcIter(windowParam,z_Old,z_Old_1,itersCount,zParam)
           
           PrecisionParms = ControlParams.GetSetPrecisionParms;
           func=ControlParams.GetSetMultiCalcFunc;
           
           fStepLast=0;
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
               if zParam
                   windowParam=z_New;
               end
               
           end
           delta=abs(z_Old_1-z_Old);
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
       
       %метод создания окна и матрицы функций базы
       function [WindowParam] = MakeFuncsWithNumsForMultipleCalc(ca,contParms)
           [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           WindowParam=X+i*Y;
           switch contParms.WindowParamName
               case {'Z0' 'Z' 'z0' 'z'} % в случае окна по Z0 создание матрицы функций базы,с вставкой одного значения Мю
                   
                   SingleParamStr=strcat('(',num2str(contParms.SingleParamValue));
                   SingleParamStr=strcat(SingleParamStr,')');
                   
                   zBaseStr=strcat('(',num2str(0.576412723031435+i*0.374699020737117));
                   zBaseStr=strcat(zBaseStr,')');
                   
                   baseFuncStr=strrep(func2str(@(z)(1+ Miu*abs(z-eq))*exp(i*z)), contParms.SingleParamName,SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'c',SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'Miu',SingleParamStr);
                   baseFuncStr=strrep(baseFuncStr,'eq',zBaseStr);
                   
                   baseFuncStr=str2func(baseFuncStr);
                   
%                    baseFuncStrs=cell(size(WindowParam));
%                    baseFuncStrs(:)={baseFuncStr};
                   
               case {'Miu0','Mu0','Мю0'} % в случае окна по Мю создание матрицы функций базы, где множитель каждой функции - соответствующее значение Мю из диапазона
%                    profile on;
%                    paramsStrs = arrayfun(@(param){strcat('(',num2str(param))},WindowParam);
%                    paramsStrs = arrayfun(@(param){strcat(cell2mat(param),')')},paramsStrs);
                   
                   baseFuncStr=func2str(@(Miu,z)(1+ Miu*abs(z-eq))*exp(i*z));
                   zBaseStr=strcat('(',num2str(0.576412723031435+i*0.374699020737117));
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
%            BaseFuncStr=baseFuncStr;
%            baseFuncStrs=cell(size(WindowParam));
%            baseFuncStrs(:)={baseFuncStr};
       end
   end

end