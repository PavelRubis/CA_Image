classdef CellularAutomat < IIteratedObject & handle 

    properties

        IteratedFunc
        FuncParams
        IteratedFuncStr

        Neighborhood NeighbourHood % ��� �����������
        N double {mustBePositive, mustBeInteger} % ����� ����
        Cells %(1, :) CA_cell = [] ������ ���� ����� �� ����
        Weights (1, :) double % ������ ����� ���� ������� � ����������� ������
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
