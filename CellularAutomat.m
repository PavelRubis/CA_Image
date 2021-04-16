classdef CellularAutomat < IIteratedObject

    properties

        IteratedFunc
        IteratedFuncStr
        FuncParams

        Neighborhood logical % тип окрестности (1-фон-Ќеймана, 0-ћура)
        N double {mustBePositive, mustBeInteger} % ребро пол€
        Cells (1, :) CA_cell % массив всех €чеек на поле
        Weights (1, :) double % массив весов всех соседей и центральной €чейки
    end

    methods

        function [obj] = CellularAutomat()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];

        end

    end

end
