classdef ModelingParamsForPath < ModelingParams

    properties
        EqualityVal double
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

            obj.IterCount = iterCount;
            obj.InfVal = infVal;
            obj.EqualityVal = equalityVal;
            obj.MaxPeriod = maxPeriod;

        end

    end

    methods (Static)

        function out = GetSetPrecisionParms(infVal, equalityVal)
            persistent InfVal;
            persistent EqualityVal;

            if nargin == 2
                InfVal = infVal;
                EqualityVal = equalityVal;
            end

            out = [InfVal, EqualityVal];
        end

        function out = GetSetMaxPeriod(mp)
            persistent MaxPeriod;

            if nargin == 1
                MaxPeriod = mp;
            end

            out = MaxPeriod;
        end

        function out = GetIterCount(iterCount)
            persistent IterCount;

            if nargin == 1
                IterCount = iterCount;
            end

            out = IterCount;
        end

        function [obj] = ModelingParamsInitialization(handles)

            arguments
                handles struct
            end

            errorCheck = false;
            errorStr = 'Ошибки в полях управления моделированием: ';

            if isempty(regexp(handles.IterCountEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, 'Ошибка в поле числа итераций; ');
            end

            if isempty(regexp(handles.InfValueEdit.String, '^\d+$')) || isempty(regexp(handles.ConvergValueEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, 'Ошибка в полях точности вычислений; ');
            end

            if (isempty(regexp(handles.MaxPeriodEdit.String, '^\d+$')))
                errorCheck = true;
                errorStr = strcat(errorStr, 'Ошибка в поле максимального периода; ');
            end

            if ~errorCheck

                if str2double(handles.MaxPeriodEdit.String) > str2double(handles.IterCountEdit.String)
                    errorCheck = true;
                    errorStr = strcat(errorStr, 'Максимальный период не должен превышать число итераций; ');
                end

            end

            if ~errorCheck
                obj = ModelingParamsForPath(str2double(handles.IterCountEdit.String), str2double(handles.InfValueEdit.String), str2double(strcat('1e-', handles.ConvergValueEdit.String)), str2double(handles.MaxPeriodEdit.String));
                ModelingParamsForPath.GetSetPrecisionParms(obj.InfVal, obj.EqualityVal);
                ModelingParamsForPath.GetSetMaxPeriod(obj.MaxPeriod);
                ModelingParamsForPath.GetIterCount(obj.IterCount);
            else
                obj = [];
                errordlg(errorStr, 'Ошибки ввода')
            end

        end

    end

end
