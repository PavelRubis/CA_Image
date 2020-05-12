classdef ControlParams %����� ���������� ����������
    
   properties
       IterCount {mustBeInteger, mustBePositive} %���������� ��������
       SingleOrMultipleCalc logical %��������� ��� ������������� �������
       IsPaused logical = false % �������� �� ���� �� ������ �������������� ��������
       ReRangeWindow(1,:) double % ������ �������������� �������� ��������� "����" 
       ImRangeWindow(1,:) double % ������ ������ �������� ��������� "����" 
       WindowParamName(1,:) char % �������� ��������� "����" 
       IsReady2Start logical = false% ����� �� ��
       SingleParamName(1,:) char % �������� ���������� ��������� 
       SingleParamValue double % �������� ���������� ��������� 
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
       
      % ����� get-set ��� ����������� ���������� ������� �������������
       function out = GetSetMultiCalcFunc(func)
           persistent MultiCalcFunc;
           if nargin==1
               MultiCalcFunc = func;
           end
           out = MultiCalcFunc;
       end
       
       
      % ����� get-set ��� ����������� ���������� ������� �������������
       function out = GetSetPrecisionParms(parms)
           persistent PrecisionParms;
           if nargin==1
               PrecisionParms = parms;
           end
           out = PrecisionParms;
       end
       
       %����� �������������
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
       
       %����� �������� ���� � ������� ������� ����
       function [WindowParam] = MakeFuncsWithNumsForMultipleCalc(ca,contParms)
           [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           WindowParam=X+i*Y;
           switch contParms.WindowParamName
               case {'Z0' 'Z' 'z0' 'z'} % � ������ ���� �� Z0 �������� ������� ������� ����,� �������� ������ �������� ��
                   
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
                   
               case {'Miu0','Mu0','��0'} % � ������ ���� �� �� �������� ������� ������� ����, ��� ��������� ������ ������� - ��������������� �������� �� �� ���������
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