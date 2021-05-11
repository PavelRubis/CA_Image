classdef (Abstract, HandleCompatible) VisualisationOptions

    properties
        ColorMap (1, :) char
    end

    methods (Abstract)
        PrepareDataAndAxes(dataArr)
    end

end
