classdef ModelingParams

    properties
        IterCount double {mustBeInteger, mustBePositive}
        InfVal double
        EqualityVal double
        IsReady2Start logical = false
    end

    methods

        function obj = ModelingParams(iterCount, infVal, equalityVal)

            obj.IterCount = iterCount;
            obj.InfVal = infVal;
            obj.EqualityVal = equalityVal;

        end

    end

    methods (Static)
        % метод get-set для статической переменной порогов точности
        function out = GetSetPrecisionParms(infVal, equalityVal)
            persistent InfVal;
            persistent EqualityVal;

            if nargin == 2
                InfVal = infVal;
                EqualityVal = equalityVal;
            end

            out = [InfVal, EqualityVal];
        end

        function out = GetIterCount(iterCount)
            persistent IterCount;

            if nargin == 1
                IterCount = iterCount;
            end

            out = IterCount;
        end


        function [obj] = ModelingParamsInitialization(handles)

            errorCheck = false;
            errorStr = 'Ошибки в полях управления моделированием: ';
            errStruct = getappdata(handles.output,'errStruct');

            if isempty(regexp(handles.IterCountEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, 'Ошибка в поле числа итераций; ');
            end

            if isempty(regexp(handles.InfValueEdit.String, '^\d+$')) || isempty(regexp(handles.ConvergValueEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, 'Ошибка в полях точности вычислений; ');
            end

            if ~errorCheck
                obj = ModelingParams(str2double(handles.IterCountEdit.String), str2double(strcat('1e', handles.InfValueEdit.String)), str2double(strcat('1e-', handles.ConvergValueEdit.String)));
                ModelingParams.GetSetPrecisionParms(obj.InfVal, obj.EqualityVal);
                ModelingParams.GetIterCount(obj.IterCount);
            else
                obj = [];
                errStruct.check = 1;
                errStruct.msg = strcat(errStruct.msg, errorStr);
                setappdata(handles.output, 'errStruct', errStruct);
            end

        end

    end

end
