classdef CAVisualisationOptions < VisualisationOptions

    properties
        DataProcessingFunc function_handle
        ColorBarLabel(1, :) char
    end

    methods

        function obj = CAVisualisationOptions(colorMap, dataProcessingFunc, colorBarLabel)

            arguments
                colorMap(1, :) char
                dataProcessingFunc function_handle
                colorBarLabel(1, :) char
            end

            obj.ColorMap = colorMap;

            obj.DataProcessingFunc = dataProcessingFunc;
            obj.ColorBarLabel = colorBarLabel;

        end

        function [res, obj, graphics] = PrepareDataAndAxes(obj, ca, handles)
            res = [];

            axes(handles.CAField);

            modulesArr = zeros(1, length(ca.Cells));
            zbase = ones(1, length(ca.Cells));

            if isKey(ca.FuncParams,'z*')
                zbase(:) = ca.FuncParams('z*');
            end
            PrecisionParms = ModelingParams.GetSetPrecisionParms;

            cellsValsArr = arrayfun(@(CACell) CACell.ZPath(end), ca.Cells);
            cellsValsArr = round(cellsValsArr*(1 / PrecisionParms(2))) / (1 / PrecisionParms(2));

            modulesArr = arrayfun(@(val) obj.DataProcessingFunc(val,zbase(1)), cellsValsArr);
            colorBarTitle = obj.ColorBarLabel;

            [modulesArrSrt, indxes] = sort(modulesArr);

            infValCACellsIndxes = find(modulesArr > PrecisionParms(1) | isnan(modulesArr));

            for ind = 1:length(infValCACellsIndxes)
                ca.Cells(infValCACellsIndxes(ind)).Color = [0, 0, 0];
            end

            minusinfValCACellsIndxes = find(modulesArr < -PrecisionParms(1));

            for ind = 1:length(minusinfValCACellsIndxes)
                ca.Cells(minusinfValCACellsIndxes(ind)).Color = [1, 1, 1];
            end

            modulesArrNanInfFiltered = modulesArr;
            modulesArrNanInfFiltered(infValCACellsIndxes) = [];
            modulesArrNanInfFiltered(minusinfValCACellsIndxes) = [];
            modulesArrNanInfFiltered = sort(modulesArrNanInfFiltered);

            %создание палитры
            eval(strcat('colors=colormap(', obj.ColorMap, '(', num2str(length(modulesArrNanInfFiltered)), '));'));

            for index = 1:length(modulesArrNanInfFiltered)
                sameValCACellsindxes = find(modulesArr == modulesArrNanInfFiltered(index));
                for ind = 1:length(sameValCACellsindxes)
                    ca.Cells(sameValCACellsindxes(ind)).RenderColor = colors(index, :);
                end
            end

            %отрисовка поля
            arrayfun(@(CACell) CACell.Render(), ca.Cells, 'UniformOutput', false);
            colors = arrayfun(@(CACell) {CACell.RenderColor}, ca.Cells(indxes));
            colors = cell2mat(colors');

            if ~isempty(infValCACellsIndxes)
                colors = [colors; [0, 0, 0]];
            end

            if ~isempty(minusinfValCACellsIndxes)
                colors = [[1, 1, 1]; colors];
            end

            visualValsArr = modulesArr;
            visualValsArr(infValCACellsIndxes) = inf;
            visualValsArr(minusinfValCACellsIndxes) = -inf;
            visualValsArr = sort(visualValsArr);

            [unqVisualValsArr, unqVisualValsArrIndxs] = unique(visualValsArr);
            unqColors = colors(unqVisualValsArrIndxs', :);

            clrbr = colorbar;
            clrmp = colormap(unqColors);
            clrbr.Ticks = [0:1 / length(unqVisualValsArr):1 - (1 / length(unqVisualValsArr))];
            clrbr.TickLabels = unqVisualValsArr;

            clrbr.Label.String = colorBarTitle;


            %{
 DataFormatting.PlotFormatting(contParms, ca, handles);
            %}


            graphics.Axs = handles.CAField;
            graphics.Clrbr = clrbr;
            graphics.Clrmp = clrmp;
        end
    end
end