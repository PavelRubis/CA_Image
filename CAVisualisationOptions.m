classdef CAVisualisationOptions < VisualisationOptions & handle

    properties
        DataProcessingFunc function_handle
        PrecisionParmsFunc function_handle = @(param)param
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

            arguments
                obj CAVisualisationOptions
                ca CellularAutomat
                handles struct
            end

            res = [];

            modulesArr = zeros(1, length(ca.Cells));
            zbase = ones(1, length(ca.Cells));

            if isKey(ca.FuncParams, 'z*')
                zbase(:) = ca.FuncParams('z*');
            end
            PrecisionParms = ModelingParams.GetSetPrecisionParms;

            cellsValsArr = arrayfun(@(CACell) CACell.ZPath(end), ca.Cells);
            cellsValsArr = round(cellsValsArr*(1 / PrecisionParms(2))) / (1 / PrecisionParms(2));

            modulesArr = arrayfun(@(val) obj.DataProcessingFunc(val, zbase(1)), cellsValsArr);
            colorBarTitle = obj.ColorBarLabel;

            [modulesArrSrt, indxes] = sort(modulesArr);
            PrecisionParms(1) = obj.PrecisionParmsFunc(PrecisionParms(1));

            infValCACellsIndxes = find(modulesArr > PrecisionParms(1) | isnan(modulesArr));

            for ind = 1:length(infValCACellsIndxes)
                ca.Cells(infValCACellsIndxes(ind)).RenderColor = [0, 0, 0];
            end

            modulesArrNanInfFiltered = modulesArr;
            modulesArrNanInfFiltered(infValCACellsIndxes) = [];
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
            zoom off;

            colors = arrayfun(@(CACell) {CACell.RenderColor}, ca.Cells(indxes));
            colors = cell2mat(colors');

            if ~isempty(infValCACellsIndxes)
                colors = [colors; [0, 0, 0]];
            end

            visualValsArr = modulesArr;
            visualValsArr(infValCACellsIndxes) = inf;
            visualValsArr = sort(visualValsArr);

            [unqVisualValsArr, unqVisualValsArrIndxs] = unique(visualValsArr);
            unqColors = colors(unqVisualValsArrIndxs', :);

            clrbr = colorbar;
            clrmp = colormap(unqColors);
            clrbr.Ticks = [0:1 / length(unqVisualValsArr):1 - (1 / length(unqVisualValsArr))];
            clrbr.TickLabels = unqVisualValsArr;

            clrbr.Label.String = colorBarTitle;

            PlotFormatting(obj, ca, handles);

            graphics.Axs = handles.CAField;
            graphics.Clrbr = clrbr;
            graphics.Clrmp = clrmp;
            if ~IsContinue(ca) 
                msgbox('Значения одной или нескольких ячеек ушли в бесконечность.', 'Моделирование завершено');
            end
        end

        function PlotFormatting(obj, ca, handles)

            titleStr = '';
            if ~handles.CustomIterFuncCB.Value
                switch handles.BaseImagMenu.Value
                    case 1
                        titleStr = 'z\rightarrow\lambda\cdotexp(i\cdotz)';
                    case 2
                        titleStr = 'z\rightarrowz^{2}+\mu';
                    case 3
                        titleStr = 'z\rightarrow\lambda';
                end

                switch handles.LambdaMenu.Value
                    case 1
                        titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\Sigma_{k=1}^{n}\mu_{k}\cdotz_{k}^{t}');
                    case 2
                        titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu)\mid');
                    case 3
                        titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}(-1^{k})\cdotz_{k}^{t}\mid');
                    case 4
                        titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot( (1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu))');
                    case 5
                        titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                end
            else
                titleStr = ca.ConstIteratedFuncStr;
                titleStr = strrep(titleStr, '@(z,neibs,oness)', 'z\rightarrow');
            end

            titleStr = strrep(titleStr, 'mu0', '\mu_{0}');
            titleStr = regexprep(titleStr, 'mu(?!_)', '\mu');
            titleStr = strrep(titleStr, '*', '\cdot');
            titleStr = strcat(titleStr, ' ');

            if contains(titleStr, '\mu_{0}')
                titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(ca.FuncParams('mu0')));
            end

            if ~isempty(regexp(titleStr, '\\mu(?!_)'))
                titleStr = strcat(titleStr, ' ; \mu=', num2str(ca.FuncParams('mu')));
            end

            if contains(titleStr, 'z^{\cdot}(\mu)')
                titleStr = strrep(titleStr, 'z^{\cdot}(\mu)', 'z^{*}(\mu)');
                titleStr = strcat(titleStr, ' ; z^{*}(\mu)=', num2str(ca.FuncParams('z*')));
            end

            if ~isempty(regexp(titleStr, 'mui'))
                titleStr = strrep(titleStr, 'mui', '\mu_{i}');
            end

            neigborsStrs = regexp(titleStr, 'z[1-9]+', 'match');

            if ~isempty(neigborsStrs)
                neigborsIndxes = regexp(cell2mat(neigborsStrs), '[1-9]+', 'match');
                neigborsCount = max(str2double(neigborsIndxes));

                for k = 1:neigborsCount
                    titleStr = strrep(titleStr, strcat('z', num2str(k)), strcat('z_{', num2str(k), '}'));
                end

            end

            neigborsWeightsStrs = regexp(titleStr, 'mu[1-9]+', 'match');

            if ~isempty(neigborsWeightsStrs)
                neigborsWeightsIndxes = regexp(cell2mat(neigborsWeightsStrs), '[1-9]+', 'match');
                neigborsWeightsCount = max(str2double(neigborsWeightsIndxes));

                for k = 1:neigborsWeightsCount
                    titleStr = strrep(titleStr, strcat('mu', num2str(k)), strcat('\mu_{', num2str(k), '}'));
                end

            end

            title(handles.CAField, strcat('\fontsize{16}', titleStr));%,'interpreter','latex'
        end

    end
end