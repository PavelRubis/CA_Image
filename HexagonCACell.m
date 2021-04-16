classdef HexagonCACell

    properties
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes

        Indexes (3, :) double {mustBeNonnegative, mustBeInteger}
        cellOrientation logical
    end

    methods
        %конструктор ячейки
        function obj = HexagonCACell(value, Path, indexes, caIndexes, color, N)

            if nargin == 6

                if iscell(indexes)
                    indexes = cell2mat(indexes);
                end

                if iscell(color)
                    color = cell2mat(color);
                end

                if (any(indexes < 0) || any(indexes(1:2) >= N) || indexes(3) > 3 || (indexes(3) == 0 && any(indexes ~= 0))) && N ~= 1
                    error('Error in CA_cell (i,j,k) indexes.');
                else
                    obj.Indexes = indexes;

                    if (any(obj.Indexes(1:2) == (N - 1)))
                        obj.IsExternal = true;
                    end

                end

                obj.z0 = value;
                obj.ZPath = Path;
                obj.Indexes = indexes;
                obj.RenderColor = color;
                obj.CAIndexes = caIndexes;

            end

        end

        function [obj] = SetCellIndexes(obj, N)

            arguments
                obj HexagonCACell
                N double {mustBePositive, mustBeInteger}
            end

            if obj.IsExternal
                [obj] = SetCellK_Index(obj, N);

                switch obj.Indexes(3)
                    case 1
                        obj.Indexes(1) = obj.CAIndexes(2) - (N - 1);
                        obj.Indexes(2) = obj.CAIndexes(2) - (N - 1);
                    case 2
                        obj.Indexes(1) = abs(obj.CAIndexes(2) - (N - 2)) + 1;
                        obj.Indexes(2) = obj.CAIndexes(1) - (N - 1);
                    case 3
                        obj.Indexes(1) = abs(obj.CAIndexes(1) - (N - 2)) + 1;
                        obj.Indexes(2) = abs(obj.CAIndexes(2) - (N - 1));
                end

            end

        end

        function [obj] = SetCellK_Index(obj, N)

            obj.Indexes = [0 0 nan];

            if all([obj.CAIndexes(1) < N - 1 obj.CAIndexes(2) < N - 1])
                obj.Indexes(3) = 3;
            end

            if all([obj.CAIndexes(1) >= N - 1 obj.CAIndexes(1) <= 2 * (N - 1) obj.CAIndexes(2) < N - 1])
                obj.Indexes(3) = 2;
            end

            if (isnan(obj.Indexes(3)))
                obj.Indexes(3) = 1;
            end

        end

        function [obj] = Render(obj)

            if obj.cellOrientation == 1
                %% Отрисовка вертикального гексагона в гексагональном поле
                a = obj.Indexes(1, 1);
                b = obj.Indexes(1, 2);
                c = obj.Indexes(1, 3);
                x0 = 0;
                y0 = 0;

                switch c

                    case 1

                        switch CompareDouble(a, b)
                            case - 1
                                y0 = -3/2 * (b - a);
                            case 0
                                y0 = 0;
                            case 1
                                y0 = 3/2 * (a - b);
                        end

                        x0 = (a + b) * sqrt(3) / 2;

                    case 2
                        x0 = -sqrt(3) / 2 * (a + (a - b));
                        y0 = 3/2 * b;

                    case 3
                        x0 = -sqrt(3) / 2 * (b + (b - a));
                        y0 = -3/2 * a;

                end

                dx = sqrt(3) / 2;
                dy = 1/2;

                x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                %%
            else
                %% Отрисовка горизонтального гексагона в гексагональном поле
                a = obj.Indexes(1, 1);
                b = obj.Indexes(1, 2);
                c = obj.Indexes(1, 3);
                x0 = 0;
                y0 = 0;

                %                    %первый вариант размещения координатных осей
                %                    switch c
                %
                %                        case 1
                %                            y0=-sqrt(3)/2*(a+b);
                %                            x0=3/2*(a-b);
                %
                %                        case 2
                %                            y0=sqrt(3)/2*(a-(b-a));
                %                            x0=3/2*b;
                %
                %                        case 3
                %                            y0=sqrt(3)/2*(b-(a-b));
                %                            x0=-3/2*(b-(b-a));
                %
                %                    end

                %второй вариант размещения координатных осей
                switch c

                    case 1

                        switch CompareDouble(a, b)
                            case - 1
                                x0 = -3/2 * (b - a);
                            case 0
                                x0 = 0;
                            case 1
                                x0 = 3/2 * (a - b);
                        end

                        y0 = (a + b) * sqrt(3) / 2;

                    case 2
                        y0 = -sqrt(3) / 2 * (a + (a - b));
                        x0 = 3/2 * b;

                    case 3
                        y0 = -sqrt(3) / 2 * (b + (b - a));
                        x0 = -3/2 * a;

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
