classdef ControlParams %����� ���������� ���������� � �������������� ������������� �������
    
   properties
       IterCount double {mustBeInteger, mustBePositive} %���������� ��������
       SingleOrMultipleCalc logical %��������� ��� ������������� �������
       ReRangeWindow  (1,:) double % ������ �������������� �������� ��������� "����" 
       ImRangeWindow  (1,:) double % ������ ������ �������� ��������� "����" 
       WindowParamName  (1,:) char % �������� ��������� "����" 
       WindowCenterValue double % ����������� ����� ����
       SingleParams  (1,2) double % ��������� ��������� �������������
       IsReady2Start logical = false% ����� �� ��
       ImageFunc function_handle % ����������� ��� �������������� �������
       Lambda (1,:) char % ��������� ������ ����� ������������ exp(i*z) 
       
       Periods  (:,:) double % �������� �������� 
       LastIters  (:,:) double % ��������� ��������
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
       
      % ����� get-set ��� ����������� ���������� ������� �������������
       function out = GetSetMultiCalcFunc(func)
           persistent MultiCalcFunc;
           if nargin==1
               MultiCalcFunc = func;
           end
           out = MultiCalcFunc;
       end
       
       
      % ����� get-set ��� ����������� ���������� ������� ��������
       function out = GetSetPrecisionParms(parms)
           persistent PrecisionParms;
           if nargin==1
               PrecisionParms = parms;
           end
           out = PrecisionParms;
       end
       
      % ����� get-set ��� ����������� ���������� ������������� ������� � �������������
       function out = GetSetMaxPeriod(mp)
           persistent MaxPeriod;
           if nargin==1
               MaxPeriod = mp;
           end
           out = MaxPeriod;
       end
       
      % ����� get-set ��� ����������� ����������-����� ����������������� �����������
       function out = GetSetCustomImag(customBase)
           persistent CustomBase;
           if nargin==1
               CustomBase = customBase;
           end
           out = CustomBase;
       end
       
       %����� �������������
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
           if (log(path(end))/log(10)>PrecisionParms(1)) || isnan(path(end)) || isinf(path(end)) %�������������
               fCodeNew=-1;
               iter=length(path);
               period=0;
               return;
           end
           
           %����������
           c=2:length(path);
           converg = abs(path(c-1) - path(c)) < PrecisionParms(2);
           if any(converg)
               iter=c(find(converg,1,'first'));
               fCodeNew=1;
               period=1;
               return;
           end
           
           %������
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