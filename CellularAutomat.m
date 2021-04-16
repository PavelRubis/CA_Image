classdef CellularAutomat < IIteratedObject

    properties

        IteratedFunc
        IteratedFuncStr
        FuncParams

        Neighborhood logical % ��� ����������� (1-���-�������, 0-����)
        N double {mustBePositive, mustBeInteger} % ����� ����
        Cells (1, :) CA_cell % ������ ���� ����� �� ����
        Weights (1, :) double % ������ ����� ���� ������� � ����������� ������
    end

    methods

        function [obj] = CellularAutomat()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];

        end

    end

end
