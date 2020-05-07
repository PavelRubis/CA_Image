classdef ControlParams %����� ���������� ����������
    
   properties
       IterCount {mustBeInteger, mustBePositive} %���������� ��������
       SingleOrMultipleCalc logical %��������� ��� ������������� �������
       IsPaused logical = false % �������� �� ���� �� ������ �������������� ��������
       ReRangeWindow(1,:) double % ������ �������������� �������� ��������� "����" 
       ImRangeWindow(1,:) double % ������ ������ �������� ��������� "����" 
       WindowParamName(1,:) char % �������� ��������� "����" 
       IsReady2Start logical = false% ����� �� ��
       MultiCalcFuncs (1,:) function_handle % ������� �������������
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
       
       %����� �������������
       function [z_new fStepNew]= MakeMultipleCalcIter(base,windowParam,z_old,z_old_1,fStepOld,zParam)
           if log(z_old)/(2.302585092994046)<15 && abs(z_old_1-z_old)>=1e-5
               if zParam
                   z_new=base(windowParam);
%                    z_new=base{1}(windowParam);
               else
                   z_new=base(windowParam,z_old);
%                    z_new=base{1}(windowParam,z_old);
               end
               fStepNew=fStepOld+1;
           else
               z_new=z_old;
               fStepNew=fStepOld;
           end
       end
       
       %����� �������� ���� � ������� ������� ����
       function [BaseFuncStrs, WindowParam] = MakeFuncsWithNumsForMultipleCalc(ca,contParms)
           [X,Y]=meshgrid(contParms.ReRangeWindow,contParms.ImRangeWindow);
           WindowParam=X+i*Y;
           switch contParms.WindowParamName
               case {'Z0' 'Z' 'z0' 'z'} % � ������ ���� �� Z0 �������� ������� ������� ����,� �������� ������ �������� ��
                   
                   MiuStr=strcat('(',num2str(ca.Miu));
                   MiuStr=strcat(MiuStr,')');
                   
                   zBaseStr=strcat('(',num2str(0.576412723031435+i*0.374699020737117));
                   zBaseStr=strcat(zBaseStr,')');
                   
                   baseFuncStr=strrep(func2str(@(z)(1+ Miu*abs(z-eq))*exp(i*z)),'Miu',MiuStr);
                   baseFuncStr=strrep(baseFuncStr,'c',MiuStr);
                   baseFuncStr=strrep(baseFuncStr,'eq',zBaseStr);
                   
                   baseFuncStr=str2func(baseFuncStr);
                   
%                    baseFuncStrs=cell(size(WindowParam));
%                    baseFuncStrs(:)={baseFuncStr};
                   
               case {'Miu','Mu','��'} % � ������ ���� �� �� �������� ������� ������� ����, ��� ��������� ������ ������� - ��������������� �������� �� �� ���������
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
%            baseFuncStrs=cell(size(WindowParam));
%            baseFuncStrs(:)={baseFuncStr};
           BaseFuncStrs=baseFuncStr;
       end
   end

end