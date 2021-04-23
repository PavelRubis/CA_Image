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

            obj.IterCount = iterCount;
            obj.InfVal = infVal;
            obj.EqualityVal = equalityVal;
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

            IIteratedObject = getappdata(handles.output, 'IIteratedObject');

            errorCheck = false;
            errorStr = '������ � ����� ���������� ��������������: ';

            if isempty(regexp(handles.IterCountEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, '������ � ���� ����� ��������; ');
            end

            if isempty(regexp(handles.InfValueEdit.String, '^\d+$')) || isempty(regexp(handles.ConvergValueEdit.String, '^\d+$'))
                errorCheck = true;
                errorStr = strcat(errorStr, '������ � ����� �������� ����������; ');
            end

            if (isempty(regexp(handles.MaxPeriodEdit.String, '^\d+$')))
                errorCheck = true;
                errorStr = strcat(errorStr, '������ � ���� ������������� �������; ');
            end

            if ~errorCheck

                if str2double(handles.MaxPeriodEdit.String) > str2double(handles.IterCountEdit.String)
                    errorCheck = true;
                    errorStr = strcat(errorStr, '������������ ������ �� ������ ��������� ����� ��������; ');
                end

            end

            if ~errorCheck
                obj = ModelingParamsForPath(str2double(handles.IterCountEdit.String), str2double(handles.InfValueEdit.String), str2double(strcat('1e-', handles.ConvergValueEdit.String)), str2double(handles.MaxPeriodEdit.String));
                ModelingParams.GetSetPrecisionParms(obj.InfVal, obj.EqualityVal);
                ModelingParamsForPath.GetSetMaxPeriod(obj.MaxPeriod);
                ModelingParams.GetIterCount(obj.IterCount);
            else
                obj = [];
                errordlg(errorStr, '������ �����')
            end

        end

    end

end
