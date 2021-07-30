classdef NeumannNeighbourHood < NeighbourHood % объект окрестности фон-Неймана

    properties
        % Тип границ поля КА (1-линия смерти, 2-циклические, 3-закрытые)
        BordersType
    end

    methods

        % конструктор объекта в памяти
        function obj = NeumannNeighbourHood(bordersType)
            obj.BordersType = bordersType;
        end

        % установка соседей ячейки в окрестности фон-Неймана в зависимости от типа границ поля КА 
        function [caCell] = GetNeighbours(obj, caCell)
            [neibsArrIndexes, extraNeibsArrIndexes] = GetNeumannNeighbs(caCell);

            switch obj.BordersType
                % у внешних ячеек нет соседей
                case 1

                    if ~caCell.IsExternal
                        caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));
                    end

                % все ячейки имеют одинаковое число соседей за счет цикличности границ
                case 2
                    caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));

                    if caCell.IsExternal
                        caCell.CurrNeighbors = [caCell.CurrNeighbors caCell.CAHandle.Cells(find(extraNeibsArrIndexes))];
                    end

                % ячейки имеют соседей, реально находящихся в окрестности фон-Неймана (у граничных соседей меньше чем у внутренних)
                case 3
                    caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));
            end
            
            sortedNeighbors = GetNeumannNeighbsPlaces(caCell);
            caCell.CurrNeighbors = caCell.CurrNeighbors(sortedNeighbors(find(sortedNeighbors)));

        end

    end

end
