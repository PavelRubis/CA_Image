classdef ControlParams %����� ���������� ����������
    
   properties
       IterCount {mustBeInteger, mustBePositive} %���������� ��������
       SingleOrMultipleCalc logical %��������� ��� ������������� �������
       IsPaused logical = false % �������� �� ���� �� ������ �������������� ��������
       ReBorders (1,2) double {mustBeFinite}% ������� "����" �� �������������� ���
       ImBorders (1,2) double {mustBeFinite}% ������� "����" �� ������ ���
       IsReady2Start logical = false% ����� �� ��
   end
   
   methods
       
       function obj=ControlParams(iterCount,singleOrMultipleCalc, reBorders, imBorders)
       
           if nargin
               obj.IterCount=iterCount;
               obj.SingleOrMultipleCalc=singleOrMultipleCalc;
               obj.ReBorders=reBorders;
               obj.ImBorders=imBorders;
           end
           
       end
       
   end
    

end