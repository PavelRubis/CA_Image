classdef SquareCACell < CA_cell % €чейка клеточного автомата, представл€ема€ квадратом

    properties
        % начальное состо€ние €чейки
        z0
        % значени€ состо€ний €чейки дл€ каждой итерации эволюции
        ZPath
        % флаг - €вл€етс€ ли €чейка внешней
        IsExternal
        % соседи €чейки в окрестности
        CurrNeighbors
        % цвет при отрисовке
        RenderColor
        % индексы в двумерном (в общем случае зубчатом) массиве пол€  ј
        CAIndexes
        % номер последней итерации эволюции  ј
        Step

        CAHandle CellularAutomat
    end

    methods
        %конструктор €чейки
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

        %установка свойства IsExternal (true - внешн€€, false - внутренн€€) на основе координат в массиве €чеек пол€
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

        % получение индексов соседних €чеек в массиве всех €чеек пол€ с окрестностью ћура
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

        % получение индексов соседних €чеек в массиве всех €чеек пол€ с окрестностью фон-Ќеймана
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


        % сортировка соседних €чеек в локальной окрестности фон-Ќеймана (по местам визуально снизу по часовой)
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

        % сортировка соседних €чеек в локальной окрестности ћура (по местам визуально снизу по часовой)
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

        % отрисовка квадратной €чейки в квадратном поле
        function [obj] = Render(obj)
            x_arr = [obj.CAIndexes(2) obj.CAIndexes(2) + 1 obj.CAIndexes(2) + 1 obj.CAIndexes(2)];
            y_arr = [(obj.CAIndexes(1)) (obj.CAIndexes(1)) (obj.CAIndexes(1)) + 1 (obj.CAIndexes(1)) + 1];

            patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование квадрата
            patchik.UserData = strcat({'ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состо€нием z='},{num2str(obj.ZPath(end))});
                
            set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
            %%
        end

    end

end
