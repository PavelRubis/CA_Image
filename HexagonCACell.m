classdef HexagonCACell < CA_cell % ячейка клеточного автомата, представляемая гексагоном

    properties
        % начальное состояние ячейки
        z0
        % значения состояний ячейки для каждой итерации эволюции
        ZPath
        % флаг - является ли ячейка внешней
        IsExternal
        % соседи ячейки в окрестности
        CurrNeighbors
        % цвет при отрисовке
        RenderColor
        % индексы в двумерном (в общем случае зубчатом) массиве поля КА
        CAIndexes
        % номер последней итерации эволюции КА
        Step
        % номер "кольца", состоящего из гексагональных ячеек к которому принадлежит данная ячейка
        HexRingNum double {mustBeInteger} = 0
        % указатель на КА
        CAHandle CellularAutomat
        % индексы i,j,k (нужны только для внешних ячеек) для поиска всех соседей в поле с цикличными границами 
        Indexes (1, 3) double
        % ориентация гексагона, представляемого ячейкой
        CellOrientation logical
        % тип поля КА (0-квадратное, 1-гексагональное)
        FieldType logical
    end

    methods
        %конструктор ячейки
        function obj = HexagonCACell(value, CAindexes, CAhandle, handles)

            cellOrientation = handles.HexOrientationPanel.UserData{2};
            fieldType = handles.FieldTypeGroup.UserData;

            if iscell(CAindexes)
                CAindexes = cell2mat(CAindexes);
            end

            obj.z0 = value;
            obj.ZPath = value;
            obj.CAHandle = CAhandle;
            obj.CellOrientation = cellOrientation;
            obj.FieldType = fieldType;
            obj.CAIndexes = CAindexes;

            obj.RenderColor = [0 0 0];
            obj.Step = 0;

        end

        % определение свойства IsExternal (true - внешняя, false - внутренняя) на основе координат в массиве ячеек поля
        function [obj] = SetIsExternal(obj)
            if obj.FieldType
               obj = SetIsExternalHex(obj);
            else
               obj = SetIsExternalSquare(obj);
            end
        end
        
        % определение свойства IsExternal на основе координат в массиве ячеек квадратного поля
        function [obj] = SetIsExternalSquare(obj)
            CAindexes = obj.CAIndexes;
            n = obj.CAHandle.N;
            if any([CAindexes(2) == 0, CAindexes(1) == 0, CAindexes(1) == (n - 1), CAindexes(2) == (n - 1)])
                obj.IsExternal = true;
            else
                obj.IsExternal = false;
            end
        end

        % определение свойства IsExterna на основе координат в массиве ячеек гексагонального поля
        function [obj] = SetIsExternalHex(obj)

            rowLength = length(find(arrayfun(@(caCell)caCell.CAIndexes(1) == obj.CAIndexes(1),obj.CAHandle.Cells)));

            if any([obj.CAIndexes(2) == 0, obj.CAIndexes(1) == 0, obj.CAIndexes(1) == 2 * (obj.CAHandle.N - 1), obj.CAIndexes(2) == rowLength - 1])
                obj.IsExternal = true;
                obj = SetCellIndexes(obj);
            else
                obj.IsExternal = false;
            end
        end
        
        % определение номера "кольца", которому принадлежит ячейка 
        function [obj] = RingNumSet(obj)

            for ringNum=0:(obj.CAHandle.N - 1)
                maxRow = 2 * (obj.CAHandle.N - 1) - ringNum;
                maxColInd = length(find(arrayfun(@(caCell)caCell.CAIndexes(1) == obj.CAIndexes(1),obj.CAHandle.Cells))) - (ringNum + 1);

                if all([all([obj.CAIndexes(1) >= ringNum, obj.CAIndexes(1) <= maxRow ]), any([obj.CAIndexes(1) == ringNum, obj.CAIndexes(2) == ringNum, obj.CAIndexes(1) == maxRow, obj.CAIndexes(2) == maxColInd])])
                    obj.HexRingNum = ringNum;
                    break;
                end

                any([obj.CAIndexes(1) == ringNum, obj.CAIndexes(2) == ringNum, obj.CAIndexes(1) == maxRow, obj.CAIndexes(2) == maxColInd])
            
            end
        end

        % определение индексов i,j,k (для внешних ячеек)
        function [obj] = SetCellIndexes(obj)

            if obj.IsExternal
                N = obj.CAHandle.N;
                [obj] = SetCellK_Index(obj);

                switch obj.Indexes(3)
                    case 1

                        if obj.CAIndexes(1) > N - 1
                            obj.Indexes(1) = N - 1;
                        else
                            obj.Indexes(1) = obj.CAIndexes(1);
                        end

                        if obj.CAIndexes(1) <= N - 1
                            obj.Indexes(2) = N - 1;
                        else
                            obj.Indexes(2) = mod(obj.CAIndexes(2), N - 1);
                        end
                        
                    case 2
                        obj.Indexes(1) = abs(obj.CAIndexes(2) - (N - 2)) + 1;
                        obj.Indexes(2) = obj.CAIndexes(1) - (N - 1);
                    case 3
                        obj.Indexes(1) = abs(obj.CAIndexes(1) - (N - 2)) + 1;
                        obj.Indexes(2) = abs(obj.CAIndexes(2) - (N - 1));
                end

            end

        end

        % определение индекса k (для внешних ячеек)
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

        % определение индексов соседей в массиве ячеека поля КА в зависимости от типа поля (окрестность Мура)
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetMooreNeighbs(obj)
            if obj.FieldType
                [neibsArrIndexes, extraNeibsArrIndexes] = GetHexFieldMooreNeighbs(obj);
            else
                [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldMooreNeighbs(obj);
            end
        end
        
        % определение индексов соседей в массиве ячеека поля КА в зависимости от типа поля (окрестность фон-Неймана)
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetNeumannNeighbs(obj)
            if obj.FieldType
                [neibsArrIndexes, extraNeibsArrIndexes] = GetHexFieldNeumannNeighbs(obj);
            else
                [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldNeumannNeighbs(obj);
            end
        end

        % сортировка соседей  (получение упорядоченных индексов в массиве всех ячеек) текущей ячейки в ее окрестности в зависимости от типа поля (окрестность Мура)
        function sortedNeighbors = GetMooreNeighbsPlaces(obj)
            if obj.FieldType
                sortedNeighbors = GetHexFieldMooreNeighbsPlaces(obj);
            else
                sortedNeighbors = GetSquareFieldMooreNeighbsPlaces(obj);
            end
        end
        
        % сортировка соседей  (получение упорядоченных индексов в массиве всех ячеек) текущей ячейки в ее окрестности в зависимости от типа поля (окрестность фон-Неймана)
        function sortedNeighbors = GetNeumannNeighbsPlaces(obj)
            if obj.FieldType
                sortedNeighbors = GetHexFieldNeumannNeighbsPlaces(obj);
            else
                sortedNeighbors = GetSquareFieldNeumannNeighbsPlaces(obj);
            end
        end

        % сортировка соседей (получение упорядоченных индексов в массиве всех ячеек) в окрестности текущей (квадратное поле, окрестность фон-Неймана)
        function sortedNeighbors =  GetSquareFieldNeumannNeighbsPlaces(obj)
            sortedNeighbors = GetSquareFieldMooreNeighbsPlaces(obj);
        end

        % сортировка соседей (получение упорядоченных индексов в массиве всех ячеек) в окрестности текущей (квадратное поле, окрестность Мура)
        function sortedNeighbors = GetSquareFieldMooreNeighbsPlaces(obj)
            
            sortedNeighbors = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1 -1]},{[0 -1]},{[1 -1]},{[1 0]},{[0 1]},{[-1 0]}]);
            
            if obj.IsExternal && obj.CAHandle.Neighborhood.BordersType == 2
                sortedNeighbors = extraSquareMooreNeighborsPlaces(obj, sortedNeighbors);
            end

            mooreNeibs = obj.CurrNeighbors(sortedNeighbors(find(sortedNeighbors)));

            sortedNeighbors = zeros(1,3);
            for ind=1:length(mooreNeibs)
                neibNum = GetSquareFieldMooreNeighbNum(obj, mooreNeibs(ind));

                if ~isempty(neibNum)
                    switch neibNum
                    case 1
                        sortedNeighbors(1) = find(arrayfun(@(otherNeib)isequal(otherNeib.CAIndexes,mooreNeibs(ind).CAIndexes),mooreNeibs));
                    case 3
                        sortedNeighbors(2) = find(arrayfun(@(otherNeib)isequal(otherNeib.CAIndexes,mooreNeibs(ind).CAIndexes),mooreNeibs));
                    case 5
                        sortedNeighbors(3) = find(arrayfun(@(otherNeib)isequal(otherNeib.CAIndexes,mooreNeibs(ind).CAIndexes),mooreNeibs));
                    end
                end

            end
            
            sortedNeighbors = sortedNeighbors(find(sortedNeighbors));

        end

        % определение номера соседней ячейки в окрестности данной ячейки в квадратном поле с шаблоном Мура
        function neibNum = GetSquareFieldMooreNeighbNum(obj, neib)
            
            n = obj.CAHandle.N;
            neibNum = [];

            checkDiffMatrArr = [
                {[
                    [-1 -1];
                    [(n - 1) (n - 1)];
                    [-1 (n - 1)];
                    [(n - 1) -1];
                ]},
                {[
                    [0  -1];
                    [0 (n - 1)];
                ]},
                {[
                    [1  -1];
                    [1 (n - 1)];
                    [-(n - 1) -1];
                    [-(n - 1) (n - 1)];
                ]},
                {[
                    [1   0];
                    [-(n - 1) 0];
                    [1 -(n - 1)];
                ]},
                {[
                    [0   1];
                    [0 -(n - 1)];
                ]},
                {[
                    [-1  0];
                    [(n - 1) 0];
                    [-1 -(n - 1)];
                ]}
            ];

            for ind=1:length(checkDiffMatrArr)
                if any(ismember(neib.CAIndexes - obj.CAIndexes == checkDiffMatrArr{ind}, [1 1], 'rows'))
                    neibNum = ind;
                    return;
                end
            end
            
        end
        
        function [neibsArrIndexes, extraNeibsArrIndexes] =  GetSquareFieldNeumannNeighbs(obj)
            [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldMooreNeighbs(obj);
        end

        % получение индексов (поиск в массиве всех ячеек поля) соседних ячеек в окрестности Мура в квадратном поле
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetSquareFieldMooreNeighbs(obj)
            
            checkDiffMatr = [
                        [-1 -1];
                        [0  -1];
                        [1  -1];
                        [1   0];
                        [0   1];
                        [-1  0];
            ];
            neibsArrIndexes = (arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells));
            
            extraNeibsArrIndexes = [];

            if obj.IsExternal
                n = obj.CAHandle.N;
                objIndxsArr = cell(1,length(obj.CAHandle.Cells));
                extraNeibsArrIndexes = zeros(1,length(obj.CAHandle.Cells));
                objIndxsArr(:) = {obj.CAIndexes};
                neibsSearchFunc = @(allCells,currCellIndxs,checkDiffMatr)(arrayfun(@(neighbor,currCellIndxs) any(ismember(neighbor.CAIndexes - cell2mat(currCellIndxs) == checkDiffMatr, [1 1], 'rows')), allCells, currCellIndxs));

                checkDiffMatr = [
                        [(n - 1) (n - 1)];
                        [-1 (n - 1)];
                        [(n - 1) -1];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);
            
                checkDiffMatr = [
                        [0 (n - 1)];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);
                
                checkDiffMatr = [
                        [1 (n - 1)];
                        [-(n - 1) -1];
                        [-(n - 1) (n - 1)];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);

                checkDiffMatr = [
                        [-(n - 1) 0];
                        [1 -(n - 1)];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);

                checkDiffMatr = [
                        [0 -(n - 1)];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);

                checkDiffMatr = [
                    [(n - 1) 0];
                    [-1 -(n - 1)];
                ];
                extraNeibsArrIndexes = extraNeibsArrIndexes + neibsSearchFunc(obj.CAHandle.Cells, objIndxsArr, checkDiffMatr);
                
            end
        end
        
        % получение индексов соседних ячеек, обусловленных циклическими границами в окрестности Мура в квадратном поле
        function neibsArrIndexes = extraSquareMooreNeighborsPlaces(obj, neibsArrIndexes)

            n = obj.CAHandle.N;
            objIndxsArr = cell(1,length(obj.CurrNeighbors));
            objIndxsArr(:) = {obj.CAIndexes};
            neibsSearchFunc = @(allCells,currCellIndxs,checkDiffMatr)find(arrayfun(@(neighbor,currCellIndxs) any(ismember(neighbor.CAIndexes - cell2mat(currCellIndxs) == checkDiffMatr, [1 1], 'rows')), allCells, currCellIndxs));

            if ~neibsArrIndexes(1)
                checkDiffMatr = [
                        [(n - 1) (n - 1)];
                        [-1 (n - 1)];
                        [(n - 1) -1];
                ];
                neibsArrIndexes(1) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end
            
            if ~neibsArrIndexes(2)
                checkDiffMatr = [
                        [0 (n - 1)];
                ];
                neibsArrIndexes(2) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end
            
            if ~neibsArrIndexes(3)
                checkDiffMatr = [
                        [1 (n - 1)];
                        [-(n - 1) -1];
                        [-(n - 1) (n - 1)];
                ];
                neibsArrIndexes(3) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end

            if ~neibsArrIndexes(4)
                checkDiffMatr = [
                        [-(n - 1) 0];
                        [1 -(n - 1)];
                ];
                neibsArrIndexes(4) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end
            
            if ~neibsArrIndexes(5)
                checkDiffMatr = [
                        [0 -(n - 1)];
                ];
                neibsArrIndexes(5) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end

            if ~neibsArrIndexes(6)
                checkDiffMatr = [
                    [(n - 1) 0];
                    [-1 -(n - 1)];
                ];
                neibsArrIndexes(6) = neibsSearchFunc(obj.CurrNeighbors, objIndxsArr, checkDiffMatr);
            end
        end

        
        % получение индексов (поиск в массиве всех ячеек поля) соседних ячеек в окрестности Мура в гексагональном поле
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetHexFieldMooreNeighbs(obj)

            neibsArrIndexes = [];
            extraNeibsArrIndexes = [];
            n = obj.CAHandle.N;
            
            checkDiffMatr = [
                        [0 1];
                        [1 0];
                        ];
            neibsArrIndexes = arrayfun(@(neighbor) any(ismember(abs(neighbor.CAIndexes - obj.CAIndexes) == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);

            if obj.CAIndexes(1) < n - 1

                checkDiffMatr = [
                            [1 1];
                            [-1 -1];
                            ];
                neibsArrIndexes = neibsArrIndexes + arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            elseif obj.CAIndexes(1) > n - 1

                checkDiffMatr = [
                            [1 -1];
                            [-1 1];
                            ];
                neibsArrIndexes = neibsArrIndexes + arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            elseif obj.CAIndexes(1) == n - 1
                
                checkDiffMatr = [
                            [1 -1];
                            [1  0];
                            [0  1];
                            [-1 0];
                            [-1 -1];
                            [0 -1];
                            ];
                neibsArrIndexes = arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            end

            if obj.IsExternal
               
                if isequal(obj.Indexes(1:2), [n - 1 0])

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2), [n - 1 n - 1]), obj.CAHandle.Cells);

                end

                if isequal(obj.Indexes(1:2), [n - 1 n - 1])

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2), [n - 1 0]), obj.CAHandle.Cells);

                end

                if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)

                    extraNeibsArrIndexes = arrayfun(@(neighbor) isequal(neighbor.Indexes(1:2) - obj.Indexes(1:2), [0 0]) & neighbor.Indexes(3) ~= obj.Indexes(3), obj.CAHandle.Cells);

                end

            end

        end

        % получение индексов (поиск  в массиве всех ячеек поля) соседних ячеек в окрестности фон-Неймана в гексагональном поле
        function [neibsArrIndexes, extraNeibsArrIndexes] = GetHexFieldNeumannNeighbs(obj)

            neibsArrIndexes = [];
            extraNeibsArrIndexes = [];
            n = obj.CAHandle.N;
            
            if obj.CAIndexes(1) < n - 1

                checkDiffMatr = [
                            [-1 -1];
                            [1 0];
                            [0 1];
                            ];
                neibsArrIndexes = arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            elseif obj.CAIndexes(1) > n - 1

                checkDiffMatr = [
                            [1 -1];
                            [0  1];
                            [-1 0];
                            ];
                neibsArrIndexes = arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            elseif obj.CAIndexes(1) == n - 1
                
                checkDiffMatr = [
                            [1  -1];
                            [0   1];
                            [-1 -1];
                            ];
                neibsArrIndexes = arrayfun(@(neighbor) any(ismember(neighbor.CAIndexes - obj.CAIndexes == checkDiffMatr, [1 1], 'rows')), obj.CAHandle.Cells);
            
            end

            if obj.IsExternal

                if isequal(obj.Indexes(1:2), [n - 1 0])

                    checkDiffMatr = [
                                [0 (n - 1) 0];
                                [0 (n - 1) 1];
                                [0 (n - 1) -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - obj.Indexes) == checkDiffMatr, [1 1 1], 'rows')), obj.CAHandle.Cells);

                end

                if isequal(obj.Indexes(1:2), [n - 1 n - 1])

                    checkDiffMatr = [
                                [0 -(n - 1) 1];
                                [0 -(n - 1) -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - obj.Indexes) == checkDiffMatr, [1 1 1], 'rows')), obj.CAHandle.Cells);

                end

                if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)

                    checkDiffMatr = [
                                [0 0 1];
                                [0 0 -2];
                                ];

                    extraNeibsArrIndexes = arrayfun(@(neighbor) any(ismember((neighbor.Indexes - obj.Indexes) == checkDiffMatr, [1 1 1], 'rows')), obj.CAHandle.Cells);

                end

            end

        end

        function neibsArrIndexes = GetHexFieldMooreNeighbsPlaces(obj)
            
            n = obj.CAHandle.N;
            neibsArrIndexes = [];

            if ~isempty(obj.CurrNeighbors)

                if obj.CAIndexes(1) < n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1,-1]},{[0, -1]},{[1,  0]},{[1,  1]},{[0,  1]},{[-1, 0]}]);
                elseif obj.CAIndexes(1) > n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1, 0]},{[0, -1]},{[1, -1]},{[1,  0]},{[0,  1]},{[-1, 1]}]);
                elseif obj.CAIndexes(1) == n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1 -1]},{[0 -1]},{[1 -1]},{[1  0]},{[0  1]},{[-1 0]}]);
                end

                if obj.IsExternal && obj.CAHandle.Neighborhood.BordersType == 2
                   neibsArrIndexes =  extraMooreNeighborsPlaces(obj, neibsArrIndexes);
                end

            end

        end

        % сортировка индексов соседей текущей ячейки в ее окрестности
        function neibsArrIndexes = neighborsOnTheirPlaces(obj, neibs, diffsArr)
            
            neibsArrIndexes = zeros(1, length(diffsArr));
            
            findFunc = @(neib,dif)isequal(neib.CAIndexes - obj.CAIndexes, cell2mat(dif));
            
            localDiff = cell(1,length(neibs));
            for ind=1:length(diffsArr)
                localDiff(:) = diffsArr(ind);
                if ~isempty(neibs)
                    val = find(arrayfun(findFunc, neibs, localDiff));
                    if ~isempty(val)
                        neibsArrIndexes(ind) = val;
                    end
                end
            end

        end
        
        function allNeibsArrIndexes = extraMooreNeighborsPlaces(obj, neibsArrIndexes)

            switch obj.Indexes(3)
                case 1
                   allNeibsArrIndexes = extraMooreNeighborsPlacesK_1(obj, neibsArrIndexes);
                case 2
                   allNeibsArrIndexes = extraMooreNeighborsPlacesK_2(obj, neibsArrIndexes);
                case 3
                   allNeibsArrIndexes = extraMooreNeighborsPlacesK_3(obj, neibsArrIndexes);
            end

        end
        
        function allNeibsArrIndexes = extraMooreNeighborsPlacesK_1(obj, neibsArrIndexes)

            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(4) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 3]),obj.CurrNeighbors));
               allNeibsArrIndexes(5) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 2]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(4) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 3]),obj.CurrNeighbors));
               allNeibsArrIndexes(5) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 2]),obj.CurrNeighbors));
               allNeibsArrIndexes(6) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 1]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 3]),obj.CurrNeighbors));
                ind2 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 2]),obj.CurrNeighbors));

                if obj.CAIndexes(1) > n - 1
                    allNeibsArrIndexes(4) = ind1;
                    allNeibsArrIndexes(5) = ind2;
                else
                    allNeibsArrIndexes(5) = ind1;
                    allNeibsArrIndexes(6) = ind2;
                end

            end

        end
        
        function allNeibsArrIndexes = extraMooreNeighborsPlacesK_2(obj, neibsArrIndexes)

            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 2]),obj.CurrNeighbors));
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 3]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 3]),obj.CurrNeighbors));
               allNeibsArrIndexes(4) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 2]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 1]),obj.CurrNeighbors));
                ind2 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 3]),obj.CurrNeighbors));

                if obj.CAIndexes(1) < 2 * (n - 1)
                    allNeibsArrIndexes(2) = ind1;
                    allNeibsArrIndexes(3) = ind2;
                else
                    allNeibsArrIndexes(3) = ind1;
                    allNeibsArrIndexes(4) = ind2;
                end

            end

        end

        function allNeibsArrIndexes = extraMooreNeighborsPlacesK_3(obj, neibsArrIndexes)
            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(5) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 3]),obj.CurrNeighbors));
               allNeibsArrIndexes(6) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 2]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 3]),obj.CurrNeighbors));
               allNeibsArrIndexes(6) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 2]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 1]),obj.CurrNeighbors));
                ind2 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 2]),obj.CurrNeighbors));

                if obj.CAIndexes(1) > 0
                    allNeibsArrIndexes(1) = ind1;
                    allNeibsArrIndexes(2) = ind2;
                else
                    allNeibsArrIndexes(1) = ind1;
                    allNeibsArrIndexes(6) = ind2;
                end

            end

        end

        
        function neibsArrIndexes = GetHexFieldNeumannNeighbsPlaces(obj)
            
            n = obj.CAHandle.N;
            neibsArrIndexes = [];

            if ~isempty(obj.CurrNeighbors)

                if obj.CAIndexes(1) < n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1,-1]},{[1,  0]},{[0,  1]}]);
                elseif obj.CAIndexes(1) > n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1, 0]},{[1, -1]},{[0,  1]}]);
                elseif obj.CAIndexes(1) == n - 1
                    neibsArrIndexes = neighborsOnTheirPlaces(obj, obj.CurrNeighbors, [{[-1 -1]},{[1 -1]},{[0  1]}]);
                end

                if obj.IsExternal && obj.CAHandle.Neighborhood.BordersType == 2
                   neibsArrIndexes =  extraNeumannNeighborsPlaces(obj, neibsArrIndexes);
                end

            end

        end
        
        function allNeibsArrIndexes = extraNeumannNeighborsPlaces(obj, neibsArrIndexes)

            switch obj.Indexes(3)
                case 1
                   allNeibsArrIndexes = extraNeumannNeighborsPlacesK_1(obj, neibsArrIndexes);
                case 2
                   allNeibsArrIndexes = extraNeumannNeighborsPlacesK_2(obj, neibsArrIndexes);
                case 3
                   allNeibsArrIndexes = extraNeumannNeighborsPlacesK_3(obj, neibsArrIndexes);
            end

        end
        
        function allNeibsArrIndexes = extraNeumannNeighborsPlacesK_1(obj, neibsArrIndexes)

            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 2]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 2]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 2]),obj.CurrNeighbors));

                allNeibsArrIndexes(3) = ind1;

            end

        end
        
        function allNeibsArrIndexes = extraNeumannNeighborsPlacesK_2(obj, neibsArrIndexes)
            
            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 2]),obj.CurrNeighbors));
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 3]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(2) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 3]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 3]),obj.CurrNeighbors));

                allNeibsArrIndexes(2) = ind1;

            end

        end

        function allNeibsArrIndexes = extraNeumannNeighborsPlacesK_3(obj, neibsArrIndexes)
            n = obj.CAHandle.N;
            allNeibsArrIndexes = neibsArrIndexes;
            
            if isequal(obj.Indexes(1:2), [n - 1 0])
               
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 1]),obj.CurrNeighbors));
               allNeibsArrIndexes(3) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, n - 1, 3]),obj.CurrNeighbors));
               return;

            end

            if isequal(obj.Indexes(1:2), [n - 1 n - 1])
                
               allNeibsArrIndexes(1) = find(arrayfun(@(neib) isequal(neib.Indexes,[n - 1, 0, 1]),obj.CurrNeighbors));
               return;

            end

            if (obj.Indexes(1) == n - 1 && obj.Indexes(2) > 0 && obj.Indexes(2) ~= n - 1) || (obj.Indexes(2) == n - 1 && obj.Indexes(1) > 0 && obj.Indexes(1) ~= n - 1)
                
                ind1 = find(arrayfun(@(neib) isequal(neib.Indexes,[obj.Indexes(1), obj.Indexes(2), 1]),obj.CurrNeighbors));

                allNeibsArrIndexes(1) = ind1;

            end

        end

        % отрисовка ячейки
        function [obj] = Render(obj)

            if obj.FieldType
                if obj.CellOrientation
                    %% Отрисовка вертикального гексагона в гексагональном поле
                    a = obj.CAIndexes(1);
                    b = obj.CAIndexes(2);

                    N = obj.CAHandle.N;

                    xShift = sqrt(3) / 2 * (N - 1 - abs(a - (N - 1)));

                    x0 = b * sqrt(3) - xShift;
                    y0 = 3/2 * a;

                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                    y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                    patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    patchik.UserData = strcat({'Ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состоянием z='},{num2str(obj.ZPath(end))});

                    set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                    %%
                else
                    %% Отрисовка горизонтального гексагона в гексагональном поле
                    a = obj.CAIndexes(1);
                    b = obj.CAIndexes(2);

                    N = obj.CAHandle.N;

                    yShift = sqrt(3) / 2 * (N - 1 - abs(a - (N - 1)));

                    x0 = 3/2 * a;
                    y0 = -b * sqrt(3) + yShift;

                    dy = sqrt(3) / 2;
                    dx = 1/2;

                    x_arr = [x0 x0 + dx x0 x0 - (2 * dx) x0 - (3 * dx) x0 - (2 * dx)];
                    y_arr = [y0 y0 + dy y0 + 2 * (dy) y0 + 2 * (dy) y0 + dy y0];

                    patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    patchik.UserData = strcat({'Ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состоянием z='},{num2str(obj.ZPath(end))});
                
                    set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                 %%
                end
            else
                if obj.CellOrientation
                    %% Отрисовка вертикального гексагона в квадратном поле
                    x0 = obj.CAIndexes(1, 1);
                    y0 = obj.CAIndexes(1, 2);

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

                    patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    patchik.UserData = strcat({'Ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состоянием z='},{num2str(obj.ZPath(end))});
                
                    set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                    %%
                else
                    %% Отрисовка горизонтального гексагона в квадратном поле
                    x0 = obj.CAIndexes(1, 1);
                    y0 = obj.CAIndexes(1, 2);

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

                    patchik = patch(x_arr, y_arr, [obj.RenderColor(1) obj.RenderColor(2) obj.RenderColor(3)]); % рисование гексагона
                    patchik.UserData = strcat({'Ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состоянием z='},{num2str(obj.ZPath(end))});
                
                    set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                    %%
                end
            end

        end

    end

end
