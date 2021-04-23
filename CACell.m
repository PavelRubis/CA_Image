classdef CACell

    properties
        z0 double = 0 + 0i% начальное состо€ние €чейки
        ZPath (1, :) double% орбита €чейки
        Indexes (1, 3) int32% индексы €чейки на поле (i,j,k при заданной ориентации, x,y при )
        CurrNeighbors (1, :) CACell% массив соседей €чейки на текущей итерации
        IsExternal logical = false% €вл€етс€ ли €чейка внешней
        Color (1, 3) double% цвет дл€ отрисовки €чейки на поле

        fstep double = 0
    end

    methods
        %конструктор €чейки
        function obj = CACell(value, path, indexes, color, FieldType, N)

            if nargin

                if iscell(indexes)
                    indexes = cell2mat(indexes);
                end

                if iscell(color)
                    color = cell2mat(color);
                end

                if FieldType

                    if (any(indexes < 0) || any(indexes(1:2) >= N) || indexes(3) > 3 || (indexes(3) == 0 && any(indexes ~= 0))) && N ~= 1
                        error('Error in cell (i,j,k) indexes.');
                    else
                        obj.Indexes = indexes;

                        if (any(obj.Indexes(1:2) == (N - 1)))
                            obj.IsExternal = true;
                        end

                    end

                else

                    if (any(indexes(1:2) >= N) || any(indexes(1:2) < 0)) && N ~= 1
                        error('Error. X coordinate of cell must be <=N, Y coordinate of cell must be <=N and both coordinate must be >=0.');
                    else
                        obj.Indexes = indexes;

                        if (any(obj.Indexes(1:2) == (N - 1)) || any(obj.Indexes(1:2) == 0))
                            obj.IsExternal = true;
                        end

                    end

                end

                obj.z0 = value;
                obj.ZPath = path;
                obj.Indexes = indexes;
                obj.Color = color;
            end

        end

        function obj = SetColor(obj, value)
            obj.Color = value;
        end

        function sortedCACellNeighbours = SortNeumannCACellNeighbours(obj, ca)
            sortedCACellNeighbours = [];

            if length(obj.CurrNeighbors) > 0

                if ca.FieldType
                    
                    neib1 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 1 0])), obj.CurrNeighbors)));
                    sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib1)];

                    switch num2str([obj.Indexes(1) > 1 obj.Indexes(2) > 0])
                        case '0  0'
                            neib2 = find((arrayfun(@(neighbor) all(neighbor.Indexes == [0 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                            neib3 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 2) (obj.Indexes(1) + 1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                        case '0  1'
                            neib2 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(obj.Indexes(2) - 1) -neighbor.Indexes(1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                            neib3 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                        case '1  0'
                            neib2 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes - obj.Indexes, [-1 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                            neib3 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 2) (obj.Indexes(1) + 1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];
                        case '1  1'

                            neib2 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes - obj.Indexes, [-1 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                            neib3 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                    end

                else

                    if length(obj.CurrNeighbors) == 4
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(2)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(1)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(3)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(4)];
                    else
                        neib1 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib1)];

                        neib2 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [-1 0 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                        neib3 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                        neib4 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 0 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                    end

                end

            else
                sortedCACellNeighbours = obj.CurrNeighbors;
            end

        end

        function sortedCACellNeighbours = SortMooreCACellNeighbours(obj, ca)
            sortedCACellNeighbours = [];

            if length(obj.CurrNeighbors) > 0

                if ca.FieldType

                    neib1 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 1 0])), obj.CurrNeighbors)));
                    sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib1)];

                    neib2 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 1 0])), obj.CurrNeighbors)));
                    sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                    switch num2str([obj.Indexes(1) > 1 obj.Indexes(2) > 0])
                        case '0  0'
                            neib3 = find((arrayfun(@(neighbor) all(neighbor.Indexes == [0 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                            neib4 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 1) obj.Indexes(1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                            neib5 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 2) (obj.Indexes(1) + 1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib5)];

                        case '0  1'
                            neib3 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(obj.Indexes(2) - 1) -neighbor.Indexes(1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                            neib4 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(obj.Indexes(2) - 2) -(neighbor.Indexes(1) + 1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                            neib5 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib5)];

                        case '1  0'
                            neib3 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes - obj.Indexes, [-1 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                            neib4 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 1) obj.Indexes(1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                            neib5 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [(-neighbor.Indexes(2) + 2) (obj.Indexes(1) + 1)]) && neighbor.Indexes(3) ~= obj.Indexes(3), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib5)];
                        case '1  1'

                            neib3 = find((arrayfun(@(neighbor) isequal(neighbor.Indexes - obj.Indexes, [-1 0 0]), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                            neib4 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [-1 -1 0])), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                            neib5 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                            sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib5)];

                    end

                    neib6 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 0 0])), obj.CurrNeighbors)));
                    sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib6)];

                else

                    if length(obj.CurrNeighbors) == 8
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(4)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(1)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(2)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(3)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(5)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(8)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(7)];
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(6)];
                    else
                        neib1 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 -1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib1)];

                        neib2 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [-1 -1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib2)];

                        neib3 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [-1 0 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib3)];

                        neib4 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [-1 1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib4)];

                        neib5 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [0 1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib5)];

                        neib6 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib6)];

                        neib7 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 0 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib7)];

                        neib8 = find((arrayfun(@(neighbor) (isequal(neighbor.Indexes - obj.Indexes, [1 -1 0])), obj.CurrNeighbors)));
                        sortedCACellNeighbours = [sortedCACellNeighbours obj.CurrNeighbors(neib8)];

                    end

                end

            else
                sortedCACellNeighbours = obj.CurrNeighbors;
            end

        end

    end

    methods (Static)

        function obj = SetZ0(obj, value)
            obj.z0 = value;
            obj.ZPath = value;
        end

    end

end

function mustBeInRange(a, b)

    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ', ...
                num2str(b(1)), '...', num2str(b(2))])
    end

end
