classdef (Abstract) CA_cell

    properties (Abstract)
        z0
        ZPath
        IsExternal
        CurrNeighbors
        RenderColor
        CAIndexes
    end

    methods (Abstract)
        [obj] = Render(obj)
        [obj] = GetAllMooreNeighbors(obj)
        [obj] = GetAllNeumannNeighbors(obj)
    end

end
