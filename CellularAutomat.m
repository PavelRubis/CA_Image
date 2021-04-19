classdef CellularAutomat < IIteratedObject & handle 

    properties

        IteratedFunc
        FuncParams
        IteratedFuncStr

        Neighborhood NeighbourHood % тип окрестности
        N double {mustBePositive, mustBeInteger} % ребро поля
        Cells %(1, :) CA_cell = [] массив всех ячеек на поле
        Weights (1, :) double % массив весов всех соседей и центральной ячейки
    end

    methods

        function [obj] = CellularAutomat()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];

        end

        function [obj] = Initialization(obj, handles)

            arguments
                obj CellularAutomat
                handles struct
            end

            [obj, errorStr] = CreateCAField(obj, handles);

        end
        
        function [obj] = Iteration(obj)
        end

        function [obj] = CreateCAField(obj)
        end

    end

end
