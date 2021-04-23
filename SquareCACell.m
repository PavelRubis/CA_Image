classdef SquareCACell < CA_cell

    properties
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes
        Step

        CAHandle CellularAutomat
        VisualizationType double {mustBeInteger, mustBeInRange(VisualizationType, [0, 2])}
    end

    methods
        %конструктор €чейки
        function obj = SquareCACell(value, CAindexes, CAhandle, visType)

            if iscell(CAindexes)
                CAindexes = cell2mat(CAindexes);
            end

            if any([CAindexes(2) == 0, CAindexes(1) == 0, CAindexes(1) == (CAhandle.N - 1), CAindexes(2) == (CAhandle.N - 1)])
                obj.IsExternal = true;
            else
                obj.IsExternal = false;
            end

            obj.z0 = value;
            obj.ZPath = value;
            obj.CAHandle = CAhandle;
            obj.VisualizationType = visType;
            obj.CAIndexes = CAindexes;

            obj.RenderColor = [0 0 0];

        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetAllMooreNeighbors(obj)
            n = obj.CAHandle.N;
            checkDiffMatr = [
                        [0 1];
                        [1 0];
                        [1 1];
                        ];

            extraNeibsArrIndexes = [];
            extraCheckDiffMatr = [
                            [0 n - 1];
                            [n - 1 0];
                            [n - 1 n - 1];
                            [n - 1 1];
                            [1 n - 1];
                            ];

            neibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);

            if obj.IsExternal
                extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == extraCheckDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            end

        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetAllNeumannNeighbors(obj)
            n = obj.CAHandle.N;
            checkDiffMatr = [
                        [0 1];
                        [1 0];
                        ];

            extraNeibsArrIndexes = [];
            extraCheckDiffMatr = [
                            [0 n - 1];
                            [n - 1 0];
                            ];

            neibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);

            if obj.IsExternal
                extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == extraCheckDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            end

        end

        function [obj] = Render(obj)

            switch obj.VisualizationType

                case 0
                    %% ќтрисовка квадрата в квадратном поле
                    x_arr = [obj.CAIndexes(2) obj.CAIndexes(2) + 1 obj.CAIndexes(2) + 1 obj.CAIndexes(2)];
                    y_arr = [(obj.CAIndexes(1)) (obj.CAIndexes(1)) (obj.CAIndexes(1)) + 1 (obj.CAIndexes(1)) + 1];

                    patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование квадрата
                    %%
                case 1
                    %% ќтрисовка вертикального гексагона в квадратном поле
                    x0 = obj.CAIndexes(1, 1); % визуальна€ координата на оси x
                    y0 = obj.CAIndexes(1, 2); % визуальна€ координата на оси y

                    %расчет шести точек гексагона на экране
                    if (x0)
                        x0 = x0 + (x0 * sqrt(3) - x0);
                    end

                    if (y0)

                        if mod(y0, 2)
                            x0 = x0 + sqrt(3) / 2;
                        end

                        y0 = y0 + (y0 * 1/2);
                    end

                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                    y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                    patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    %%
                case 2
                    %% ќтрисовка горизонтального гексагона в квадратном поле
                    x0 = obj.CAIndexes(1, 1); % визуальна€ координата на оси x
                    y0 = obj.CAIndexes(1, 2); % визуальна€ координата на оси y

                    %расчет шести точек гексагона на экране
                    if (y0)
                        y0 = y0 + (y0 * sqrt(3) - y0);
                    end

                    if (x0)

                        if mod(x0, 2)
                            y0 = y0 + sqrt(3) / 2;
                        end

                        x0 = x0 + (x0 * 1/2);
                    end

                    dy = sqrt(3) / 2;
                    dx = 1/2;

                    x_arr = [x0 x0 + dx x0 x0 - (2 * dx) x0 - (3 * dx) x0 - (2 * dx)];
                    y_arr = [y0 y0 + dy y0 + 2 * (dy) y0 + 2 * (dy) y0 + dy y0];

                    patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    %%
            end

        end

    end

end

function res = CompareDouble(a, b)

    if a > b
        res = 1;
    else

        if a < b
            res = -1;
        else
            res = 0;
        end

    end

end

function mustBeInRange(a, b)

    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to RenderColor property is not in range ', ...
                num2str(b(1)), '...', num2str(b(2))])
    end

end
