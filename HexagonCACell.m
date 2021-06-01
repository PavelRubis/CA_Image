classdef HexagonCACell < CA_cell

    properties
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes
        Step
        %temporal
        HexRingNum double {mustBeInteger} = 0
        %temporal
        CAHandle CellularAutomat
        Indexes (1, 3) double
        cellOrientation logical
    end

    methods
        %конструктор €чейки
        function obj = HexagonCACell(value, CAindexes, CAhandle, orientation)

            if iscell(CAindexes)
                CAindexes = cell2mat(CAindexes);
            end

            obj.z0 = value;
            obj.ZPath = value;
            obj.CAHandle = CAhandle;
            obj.cellOrientation = mod(orientation, 2);
            obj.CAIndexes = CAindexes;

            obj.RenderColor = [0 0 0];
            obj.Step = 0;

        end

        function [obj] = SetIsExternal(obj)

            rowLength = length(find(arrayfun(@(caCell)caCell.CAIndexes(1) == obj.CAIndexes(1),obj.CAHandle.Cells)));

            if any([obj.CAIndexes(2) == 0, obj.CAIndexes(1) == 0, obj.CAIndexes(1) == 2 * (obj.CAHandle.N - 1), obj.CAIndexes(2) == rowLength - 1])
                obj.IsExternal = true;
                obj = SetCellIndexes(obj);
            else
                obj.IsExternal = false;
            end
        end
        
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

        function [obj] = SetCellIndexes(obj)

            arguments
                obj HexagonCACell
            end

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

        function [neibsArrIndexes, extraNeibsArrIndexes] = GetAllNeumannNeighbors(obj)

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

        function neibsArrIndexes = GetAllMooreNeighborsPlaces(obj)
            
            n = obj.CAHandle.N;
            neibsArrIndexes = [];

            if ~isempty(obj.CurrNeighbors)

                if obj.CAIndexes(1) < n - 1
                    neibsArrIndexes = mooreNeighborsPlaces(obj, [{[-1,-1]},{[0, -1]},{[1,  0]},{[1,  1]},{[0,  1]},{[-1, 0]}]);
                elseif obj.CAIndexes(1) > n - 1
                    neibsArrIndexes = mooreNeighborsPlaces(obj, [{[-1, 0]},{[0, -1]},{[1, -1]},{[1,  0]},{[0,  1]},{[-1, 1]}]);
                elseif obj.CAIndexes(1) == n - 1
                    neibsArrIndexes = mooreNeighborsPlaces(obj, [{[-1 -1]},{[0 -1]},{[1 -1]},{[1  0]},{[0  1]},{[-1 0]}]);
                end

                if obj.IsExternal && obj.CAHandle.Neighborhood.BordersType == 2
                   neibsArrIndexes =  extraMooreNeighborsPlaces(obj, neibsArrIndexes);
                end

            end

        end

        function neibsArrIndexes = mooreNeighborsPlaces(obj, diffsArr)
            
            neibsArrIndexes = zeros(1, 6);
            
            findFuncs = [
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{1})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{2})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{3})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{4})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{5})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{6})},
            ];

            for ind=1:length(findFuncs)
                val = find(arrayfun(findFuncs{ind}, obj.CurrNeighbors));
                if ~isempty(val)
                    neibsArrIndexes(ind) = val;
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

        
        function neibsArrIndexes = GetAllNeumannNeighborsPlaces(obj)
            
            n = obj.CAHandle.N;
            neibsArrIndexes = [];

            if ~isempty(obj.CurrNeighbors)

                if obj.CAIndexes(1) < n - 1
                    neibsArrIndexes = neumannNeighborsPlaces(obj, [{[-1,-1]},{[1,  0]},{[0,  1]}]);
                elseif obj.CAIndexes(1) > n - 1
                    neibsArrIndexes = neumannNeighborsPlaces(obj, [{[-1, 0]},{[1, -1]},{[0,  1]}]);
                elseif obj.CAIndexes(1) == n - 1
                    neibsArrIndexes = neumannNeighborsPlaces(obj, [{[-1 -1]},{[1 -1]},{[0  1]}]);
                end

                if obj.IsExternal && obj.CAHandle.Neighborhood.BordersType == 2
                   neibsArrIndexes =  extraNeumannNeighborsPlaces(obj, neibsArrIndexes);
                end

            end

        end

        function neibsArrIndexes = neumannNeighborsPlaces(obj, diffsArr)
            
            neibsArrIndexes = zeros(1, 3);
            
            findFuncs = [
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{1})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{2})},
                {@(neib) isequal(neib.CAIndexes - obj.CAIndexes, diffsArr{3})},
            ];

            for ind=1:length(findFuncs)
                val = find(arrayfun(findFuncs{ind}, obj.CurrNeighbors));
                if ~isempty(val)
                    neibsArrIndexes(ind) = val;
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


        function [obj] = Render(obj)

            if obj.cellOrientation == 1
                %% ќтрисовка вертикального гексагона в гексагональном поле
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
                patchik.UserData = strcat({'ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состо€нием z='},{num2str(obj.ZPath(end))});

                set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                %%
            else
                %% ќтрисовка горизонтального гексагона в гексагональном поле
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
                patchik.UserData = strcat({'ячейка с координатами:'}, {' '}, {'('}, {num2str(obj.CAIndexes(2))}, {','}, {num2str(obj.CAIndexes(1))}, {');'}, {' '}, {'и состо€нием z='},{num2str(obj.ZPath(end))});
                
                set(patchik, 'ButtonDownFcn', @CA_cell.showCellInfo);
                %%
            end

        end

    end

end
