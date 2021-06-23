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
    end

    methods
        %конструктор ячейки
        function obj = SquareCACell(value, CAindexes, CAhandle, handles)

            if iscell(CAindexes)
                CAindexes = cell2mat(CAindexes);
            end

            obj.z0 = value;
            obj.ZPath = value;
            obj.CAHandle = CAhandle;
            obj.CAIndexes = CAindexes;

            obj.RenderColor = [0 0 0];
            obj.Step = 0;

        end

        function obj = SetIsExternal(obj)
            CAindexes = obj.CAIndexes;
            n = obj.CAHandle.N;
            if any([CAindexes(2) == 0, CAindexes(1) == 0, CAindexes(1) == (n - 1), CAindexes(2) == (n - 1)])
                obj.IsExternal = true;
            else
                obj.IsExternal = false;
            end
        end
        
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetMooreNeighbs(obj)
            [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldMooreNeighbs(obj);
        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldMooreNeighbs(obj)
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

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetNeumannNeighbs(obj)
            [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldNeumannNeighbs(obj);
        end

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldNeumannNeighbs(obj)
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
        
        function neibsArrIndexes = GetNeumannNeighbsPlaces(obj)
            neibsArrIndexes = GetSquareFieldNeumannNeighbsPlaces(obj);
        end

        function neibsArrIndexes = GetSquareFieldNeumannNeighbsPlaces(obj)
            
            neibsArrIndexes = [];
            N = obj.CAHandle.N;

            checkDiffMatr1 = [
                        [0 -1];
                        [0 N-1];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr1, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr2 = [
                        [-1 0];
                        [N-1 0];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr2, [1 1], 'rows')),obj.CurrNeighbors) )];
            
            checkDiffMatr3 = [
                        [0 1];
                        [0 -(N-1)];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr3, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr4 = [
                        [1 0];
                        [-(N-1) 0];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr4, [1 1], 'rows')),obj.CurrNeighbors) )];
            
        end
        
        function neibsArrIndexes = GetMooreNeighbsPlaces(obj)
            neibsArrIndexes = GetSquareFieldMooreNeighbsPlaces(obj);
        end

        function neibsArrIndexes = GetSquareFieldMooreNeighbsPlaces(obj)
            
            neibsArrIndexes = [];
            N = obj.CAHandle.N;

            checkDiffMatr1 = [
                        [0 -1];
                        [0 N-1];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr1, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr2 = [
                        [-1 -1];
                        [N-1 N-1];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr2, [1 1], 'rows')),obj.CurrNeighbors) )];
            
            checkDiffMatr3 = [
                        [-1 0];
                        [N-1 0];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr3, [1 1], 'rows')),obj.CurrNeighbors) )];
            
            checkDiffMatr4 = [
                        [-1 1];
                        [N-1 -(N-1)];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr4, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr5 = [
                        [0 1];
                        [0 -(N-1)];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr5, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr6 = [
                        [1 1];
                        [-(N-1) -(N-1)];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr6, [1 1], 'rows')),obj.CurrNeighbors) )];

            checkDiffMatr7 = [
                        [1 0];
                        [-(N-1) 0];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr7, [1 1], 'rows')),obj.CurrNeighbors) )];
            
            checkDiffMatr8 = [
                        [1 -1];
                        [-(N-1) N-1];
                        ];

            neibsArrIndexes = [neibsArrIndexes find(arrayfun(@(neib) any(ismember(abs(neib.CAIndexes - obj.CAIndexes) == checkDiffMatr8, [1 1], 'rows')),obj.CurrNeighbors) )];
            
        end

        function [obj] = Render(obj)
            %% Отрисовка квадрата в квадратном поле
            x_arr = [obj.CAIndexes(2) obj.CAIndexes(2) + 1 obj.CAIndexes(2) + 1 obj.CAIndexes(2)];
            y_arr = [(obj.CAIndexes(1)) (obj.CAIndexes(1)) (obj.CAIndexes(1)) + 1 (obj.CAIndexes(1)) + 1];

            patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование квадрата
            patchik.UserData = strcat({'Ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состоянием z='},{num2str(obj.ZPath(end))});
                
            set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
            %%
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
