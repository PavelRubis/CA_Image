classdef ControlParams %класс параметров управления
    
   properties
       IterCount {mustBeInteger, mustBePositive} %количество итераций
       SingleOrMultipleCalc logical %одиночный или множественный рассчет
       IsPaused logical = false % закончен ли один из этапов множественного рассчета
       ReRangeWindow(1,:) double % массив действительных значений параметра "окна" 
       ImRangeWindow(1,:) double % массив мнимых значений параметра "окна" 
       WindowParamName(1,:) char % название параметра "окна" 
       IsReady2Start logical = false% задан ли КА
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