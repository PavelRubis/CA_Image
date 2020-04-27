classdef ControlParams %����� ���������� ����������
    
   properties
       IterCount {mustBeInteger, mustBePositive} %���������� ��������
       SingleOrMultipleCalc logical %��������� ��� ������������� �������
       IsPaused logical = false % �������� �� ���� �� ������ �������������� ��������
       ReRangeWindow(1,:) double % ������ �������������� �������� ��������� "����" 
       ImRangeWindow(1,:) double % ������ ������ �������� ��������� "����" 
       WindowParamName(1,:) char % �������� ��������� "����" 
       IsReady2Start logical = false% ����� �� ��
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
    

end