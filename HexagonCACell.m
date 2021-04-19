classdef HexagonCACell < CA_cell

    properties
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes

        CAHandle CellularAutomat
        Indexes (3, :) double {mustBeNonnegative, mustBeInteger}
        cellOrientation logical
    end

    methods
        %����������� ������
        function obj = HexagonCACell(value, Path, caIndexes, color, N)

            if nargin == 5

                if iscell(caIndexes)
                    caIndexes = cell2mat(caIndexes);
                end

                if iscell(color)
                    color = cell2mat(color);
                end

                if (any(obj.Indexes(1:2) == (N - 1), obj.Indexes(1:2) == 0))
                    obj.IsExternal = true;
                end

                obj.z0 = value;
                obj.ZPath = Path;
                obj.RenderColor = color;
                obj.CAIndexes = caIndexes;

            end

        end

        function [obj] = SetCellCAIndexes(obj)
            % �������� ���-�� �����, �������������� ����� �� � ����� �����. ���������� ����� �����. ��� �� ����� ����������
        end

        function [obj] = SetCellIndexes(obj)

            arguments
                obj HexagonCACell
            end

            if obj.IsExternal
                N = obj.CAHandle.N;
                [obj] = SetCellK_Index(obj);

                switch obj.Indexes(3)
                    case 1
                        obj.Indexes(1) = obj.CAIndexes(2) - (N - 1);
                        obj.Indexes(2) = obj.Indexes(1);
                    case 2
                        obj.Indexes(1) = abs(obj.CAIndexes(2) - (N - 2)) + 1;
                        obj.Indexes(2) = obj.CAIndexes(1) - (N - 1);
                    case 3
                        obj.Indexes(1) = abs(obj.CAIndexes(1) - (N - 2)) + 1;
                        obj.Indexes(2) = abs(obj.CAIndexes(2) - (N - 1));
                end

            end

        end

        function [obj] = SetCellK_Index(obj)

            obj.Indexes = [0 0 nan];
            N = obj.CAHandle.N;

            if all([obj.CAIndexes(1) < N - 1, obj.CAIndexes(2) <= N - 1])
                obj.Indexes(3) = 3;
            end

            if all([obj.CAIndexes(1) >= N - 1, obj.CAIndexes(2) < N - 1])
                obj.Indexes(3) = 2;
            end

            if (isnan(obj.Indexes(3)))
                obj.Indexes(3) = 1;
            end

        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetAllMooreNeighbors(obj)

            checkDiffMatr = [
                        [1 1];
                        [0 1];
                        [1 0];
                        ];
            neibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);

            extraNeibsArrIndexes = [];
            n = obj.CAHandle.N;

            if obj.IsExternal

                if isequal(obj.Indexes(1:2), [n - 1 0])

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2), [n - 1 n - 1]), obj.CAHandle.Cells);

                end

                if isequal(CA_cell.Indexes(1:2), [n - 1 n - 1])

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2), [n - 1 0]), obj.CAHandle.Cells);

                end

                if (CA_cell.Indexes(1) == n - 1 && CA_cell.Indexes(2) > 0 && CA_cell.Indexes(2) ~= n - 1) || (CA_cell.Indexes(2) == n - 1 && CA_cell.Indexes(1) > 0 && CA_cell.Indexes(1) ~= n - 1)

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [0 0]), obj.CAHandle.Cells);

                end

            end

        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetAllNeumannNeighbors(obj)

            checkDiffMatr = [
                        [-1 -1];
                        [0 1];
                        [1 0];
                        ];
            neibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.CAIndexes - obj.CAIndexes) == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            extraNeibsArrIndexes = [];

            if obj.IsExternal

                if isequal(CA_cell.Indexes(1:2), [n - 1 0])

                    checkDiffMatr = [
                                [0 (n - 1) 0];
                                [0 (n - 1) 1];
                                [0 (n - 1) -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - CA_cell.Indexes) == checkDiffMatr, [1 1 1], 'rows')), thisCA.Cells);

                end

                if isequal(CA_cell.Indexes(1:2), [n - 1 n - 1])

                    checkDiffMatr = [
                                [0 -(n - 1) 1];
                                [0 -(n - 1) -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - CA_cell.Indexes) == checkDiffMatr, [1 1 1], 'rows')), thisCA.Cells);

                end

                if (CA_cell.Indexes(1) == n - 1 && CA_cell.Indexes(2) > 0 && CA_cell.Indexes(2) ~= n - 1) || (CA_cell.Indexes(2) == n - 1 && CA_cell.Indexes(1) > 0 && CA_cell.Indexes(1) ~= n - 1)

                    checkDiffMatr = [
                                [0 0 1];
                                [0 0 -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - CA_cell.Indexes) == checkDiffMatr, [1 1 1], 'rows')), thisCA.Cells);

                end

            end

        end

        function [obj] = Render(obj)

            if obj.cellOrientation == 1
                %% ��������� ������������� ��������� � �������������� ����
                a = obj.CAIndexes(1);
                b = obj.CAIndexes(2);

                N = obj.CAHandle.N;

                xShift = sqrt(3) / 2 * (N - 1 - abs(a - (N - 1)));

                x0 = a * sqrt(3) - xShift;
                y0 = 3/2 * b;

                dx = sqrt(3) / 2;
                dy = 1/2;

                x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % ��������� ���������
                %%
            else
                %% ��������� ��������������� ��������� � �������������� ����
                a = obj.CAIndexes(1);
                b = obj.CAIndexes(2);

                N = obj.CAHandle.N;

                yShift = sqrt(3) / 2 * (N - 1 - abs(a - (N - 1)));

                x0 = 3/2 * a;
                y0 = -b * 2 * sqrt(3) + yShift;

                dy = sqrt(3) / 2;
                dx = 1/2;

                x_arr = [x0 x0 + dx x0 x0 - (2 * dx) x0 - (3 * dx) x0 - (2 * dx)];
                y_arr = [y0 y0 + dy y0 + 2 * (dy) y0 + 2 * (dy) y0 + dy y0];

                patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % ��������� ���������
                %%
            end

        end

    end

end