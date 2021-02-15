classdef ModelingParams

    properties
        IterCount double {mustBeInteger, mustBePositive}
        InfVal double
        IsReady2Start logical = false
    end

    methods (Static)
        % метод get-set для статической переменной порогов точности
        function out = GetSetPrecisionParms(infVal)
            persistent InfVal;

            if nargin == 1
                InfVal = infVal;
            end

            out = InfVal;
        end

    end

end
