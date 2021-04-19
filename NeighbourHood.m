classdef (Abstract) NeighbourHood

    properties (Abstract)
        BordersType
    end

    methods (Abstract)
        [caCell] = GetNeighbours(caCell)
    end

end
