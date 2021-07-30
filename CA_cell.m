classdef (Abstract) CA_cell % абстрактная ячейка клеточного автомата

    properties (Abstract)
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
    end

    methods (Abstract)
        % метод отрисовки ячейки
        [obj] = Render(obj)

        % метод нахождения соседей в гексагональном поле с окрестностью Мура
        [obj] = GetMooreNeighbs(obj)
        % метод нахождения соседей в гексагональном поле с окрестностью фон-Неймана
        [obj] = GetNeumannNeighbs(obj)
        % метод сортировки соседей в окрестности ячейки в гексагональном поле с окрестностью Мура
        [indexes] = GetMooreNeighbsPlaces(obj)
        % метод сортировки соседей в окрестности ячейки в гексагональном поле с окрестностью фон-Неймана
        [indexes] = GetNeumannNeighbsPlaces(obj)

        % метод нахождения соседей в квадратном поле с окрестностью Мура
        [obj] = GetSquareFieldMooreNeighbs(obj)
        % метод нахождения соседей в квадратном поле с окрестностью фон-Неймана
        [obj] = GetSquareFieldNeumannNeighbs(obj)
        % метод сортировки соседей в окрестности ячейки в квадратном поле с окрестностью Мура
        [indexes] = GetSquareFieldMooreNeighbsPlaces(obj)
        % метод сортировки соседей в окрестности ячейки в квадратном поле с окрестностью фон-Неймана
        [indexes] = GetSquareFieldNeumannNeighbsPlaces(obj)
    end
    
    methods (Static)

        function out = GetOrSetHandles(handles)
            persistent Handles;

            if nargin == 1
                Handles = handles;
            end

            out = Handles;
        end
        
        % визуализация состояния клетки КА (представленной патчем на поле)
        function showCellInfo(sender, event)
            handles = CA_cell.GetOrSetHandles;
            if string(class(sender)) == string('matlab.graphics.primitive.Patch')
                handles.CellInfoLabel.String = sender.UserData;
            else
                handles.CellInfoLabel.String = '';
            end

        end
    end
end
