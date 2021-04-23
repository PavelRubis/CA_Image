classdef ModelingParams

    properties
        IterCount double {mustBeInteger, mustBePositive}
        InfVal double
        EqualityVal double
        IsReady2Start logical = false
    end

    methods

        function obj = ModelingParams(iterCount, infVal, equalityVal)

            arguments
                iterCount double {mustBeInteger, mustBePositive}
                infVal double
                equalityVal double
            end

            obj.IterCount = iterCount;
            obj.InfVal = infVal;
            obj.EqualityVal = equalityVal;

        end

    end

    methods (Static)
        % ����� get-set ��� ����������� ���������� ������� ��������
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

            arguments
                handles struct
            end

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

            if ~errorCheck
                obj = ModelingParams(str2double(handles.IterCountEdit.String), str2double(handles.InfValueEdit.String), str2double(strcat('1e-', handles.ConvergValueEdit.String)));
                ModelingParams.GetSetPrecisionParms(obj.InfVal, obj.EqualityVal);
                ModelingParams.GetIterCount(obj.IterCount);
            else
                obj = [];
                errordlg(errorStr, '������ �����')
            end

        end

    end

end
