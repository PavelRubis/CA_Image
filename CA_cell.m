classdef (Abstract) CA_cell

    properties (Abstract)
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes
        Step
    end

    methods (Abstract)
        [obj] = Render(obj)

        [obj] = GetMooreNeighbs(obj)
        [obj] = GetNeumannNeighbs(obj)
        [indexes] = GetMooreNeighbsPlaces(obj)
        [indexes] = GetNeumannNeighbsPlaces(obj)

        [obj] = GetSquareFieldMooreNeighbs(obj)
        [obj] = GetSquareFieldNeumannNeighbs(obj)
        [indexes] = GetSquareFieldMooreNeighbsPlaces(obj)
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
