classdef ModelingParamsForPath < ModelingParams

    properties
        MaxPeriod double {mustBeInteger, mustBePositive}
    end

    methods

        function obj = ModelingParamsForPath(iterCount, infVal, equalityVal, maxPeriod)

            arguments
                iterCount double {mustBeInteger, mustBePositive}
                infVal double
                equalityVal double
                maxPeriod double {mustBeInteger, mustBePositive}
            end
            obj@ModelingParams(iterCount,infVal,equalityVal);
            obj.MaxPeriod = maxPeriod;

        end

    end

    methods (Static)

        function out = GetSetMaxPeriod(mp)
            persistent MaxPeriod;

            if nargin == 1
                MaxPeriod = mp;
            end

            out = MaxPeriod;
        end

        function [obj] = ModelingParamsInitialization(handles)

            arguments
                handles struct
            end

            errStruct = getappdata(handles.output,'errStruct');
            errStruct.msg = strcat(errStruct.msg,'Ошибки в полях управления моделированием: '); 

            if isempty(regexp(handles.IterCountEdit.String, '^\d+$'))
                errStruct.check = 1;
                errStruct.msg = strcat(errStruct.msg, 'Ошибка в поле числа итераций; ');
            end

            if isempty(regexp(handles.InfValueEdit.String, '^\d+$')) || isempty(regexp(handles.ConvergValueEdit.String, '^\d+$'))
                errStruct.check = 1;
                errStruct.msg = strcat(errStruct.msg, 'Ошибка в полях точности вычислений; ');
            end

            if (isempty(regexp(handles.MaxPeriodEdit.String, '^\d+$')))
                errStruct.check = 1;
                errStruct.msg = strcat(errStruct.msg, 'Ошибка в поле максимального периода; ');
            end

            if ~errStruct.check

                if str2double(handles.MaxPeriodEdit.String) > str2double(handles.IterCountEdit.String)
                    errStruct.check = 1;
                    errStruct.msg = strcat(errStruct.msg, 'Максимальный период не должен превышать число итераций; ');
                end

            end

            if ~errStruct.check
                obj = ModelingParamsForPath(str2double(handles.IterCountEdit.String), str2double(strcat('1e+', handles.InfValueEdit.String)), str2double(strcat('1e-', handles.ConvergValueEdit.String)), str2double(handles.MaxPeriodEdit.String));
                ModelingParams.GetSetPrecisionParms(obj.InfVal, obj.EqualityVal);
                ModelingParamsForPath.GetSetMaxPeriod(obj.MaxPeriod);
                ModelingParams.GetIterCount(obj.IterCount);
            else
                obj = [];
            end
            
            setappdata(handles.output, 'errStruct', errStruct);

        end

    end

end
