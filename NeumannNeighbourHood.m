classdef NeumannNeighbourHood < NeighbourHood % ������ ����������� ���-�������

    properties
        % ��� ������ ���� �� (1-����� ������, 2-�����������, 3-��������)
        BordersType
    end

    methods

        % ����������� ������� � ������
        function obj = NeumannNeighbourHood(bordersType)
            obj.BordersType = bordersType;
        end

        % ��������� ������� ������ � ����������� ���-������� � ����������� �� ���� ������ ���� �� 
        function [caCell] = GetNeighbours(obj, caCell)
            [neibsArrIndexes, extraNeibsArrIndexes] = GetNeumannNeighbs(caCell);

            switch obj.BordersType
                % � ������� ����� ��� �������
                case 1

                    if ~caCell.IsExternal
                        caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));
                    end

                % ��� ������ ����� ���������� ����� ������� �� ���� ����������� ������
                case 2
                    caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));

                    if caCell.IsExternal
                        caCell.CurrNeighbors = [caCell.CurrNeighbors caCell.CAHandle.Cells(find(extraNeibsArrIndexes))];
                    end

                % ������ ����� �������, ������� ����������� � ����������� ���-������� (� ��������� ������� ������ ��� � ����������)
                case 3
                    caCell.CurrNeighbors = caCell.CAHandle.Cells(find(neibsArrIndexes));
            end
            
            sortedNeighbors = GetNeumannNeighbsPlaces(caCell);
            caCell.CurrNeighbors = caCell.CurrNeighbors(sortedNeighbors(find(sortedNeighbors)));

        end

    end

end
