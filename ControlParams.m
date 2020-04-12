classdef ControlParams %класс параметров управления
    
   properties
       IterCount {mustBeInteger, mustBePositive} %количество итераций
       SingleOrMultipleCalc logical %одиночный или множественный рассчет
       IsPaused logical = false % закончен ли один из этапов множественного рассчета
       ReBorders (1,2) double {mustBeFinite}% граница "окна" на действительной оси
       ImBorders (1,2) double {mustBeFinite}% граница "окна" на мнимой оси
       IsReady2Start logical = false% задан ли КА
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