classdef PointPathVisualisationOptions < VisualisationOptions & handle

    properties
        XAxesdataProcessingFunc function_handle
        YAxesdataProcessingFunc function_handle

        XAxescolorMapLabel (1, :) char
        YAxescolorMapLabel (1, :) char

        VisualPath (1, :) double
    end

    methods

        function obj = PointPathVisualisationOptions(colorMap, xAxesdataProcessingFunc, yAxesdataProcessingFunc, xAxescolorMapLabel, yAxescolorMapLabel, visualpath)

            obj.ColorMap = colorMap;

            obj.XAxesdataProcessingFunc = xAxesdataProcessingFunc;
            obj.YAxesdataProcessingFunc = yAxesdataProcessingFunc;
            obj.XAxescolorMapLabel = xAxescolorMapLabel;
            obj.YAxescolorMapLabel = yAxescolorMapLabel;
            obj.VisualPath = visualpath;

        end

        function [newPathPart obj graphics] = PrepareDataAndAxes(obj, point, handles)

            str = strcat({'“очка'},{' '}, {num2str(point.InitState)});

            switch point.Fate
                case 0
                    msg = strcat(str, {' уходит в бесконечность на итерации:'},{' '}, {num2str(point.LastIterNum - 1)});
                case 1
                    msg = strcat(str, {' сходитс€ к аттрактору на итерации:'},{' '}, {num2str(point.LastIterNum - 1)});
                case inf
                otherwise
                    msg = strcat(str, {' имеет период:'},{' '}, {num2str(point.Fate)}, {' '},{', найденный на итерации:'},{num2str(point.LastIterNum - 1)});
            end
            
            visualPath = [];

            if length(point.StatePath) > ModelingParamsForPath.GetIterCount
                visualPath = point.StatePath(length(point.StatePath) - ModelingParamsForPath.GetIterCount:end);
            else
                visualPath = point.StatePath;
            end

            visualPath = visualPath(find(~isnan(visualPath)));
            visualPath = visualPath(find(~isinf(visualPath)));
            obj.VisualPath = visualPath;

            graphics = FormatAndPlotPath(obj, point, handles);

            newPathPart = [real(obj.VisualPath); imag(obj.VisualPath)];

            if point.Fate ~= inf
                msgbox(msg, 'ћоделирование завершено');
            end
            
            point.StatePath = point.StatePath(find(~isnan(point.StatePath)));

        end

        function graphics = FormatAndPlotPath(obj, point, handles)

            graphics.Axs = handles.CAField;

            if ~isempty(obj.VisualPath)
                visualPathLength = length(obj.VisualPath);

                visualFormatedPath = [real(obj.VisualPath); imag(obj.VisualPath)];

                axes(handles.CAField);
                cla reset;

                xlabel(obj.XAxescolorMapLabel);
                ylabel(obj.YAxescolorMapLabel);
              
                oldVisualFormatedPath = visualFormatedPath;
                tmpPath1 = oldVisualFormatedPath;
                tmpPath2 = oldVisualFormatedPath;
                visualFormatedPath(1, :) = obj.XAxesdataProcessingFunc(tmpPath1);
                visualFormatedPath(2, :) = obj.YAxesdataProcessingFunc(tmpPath2);

                eval(strcat('clrmp = colormap(', obj.ColorMap, '(visualPathLength));'));
                ms = 20;

                hold on;

                for ind = 1:length(visualFormatedPath)
                    plot(visualFormatedPath(1, ind), visualFormatedPath(2, ind), 'o', 'MarkerSize', ms, 'Color', clrmp(ind, :));

                    if ms ~= 2
                        ms = ms - 2;
                    end

                end

                %handles.CAField.DataAspectRatio = [1 1 1];
                
                imStep = (abs(max(visualFormatedPath(2, :)) - min(visualFormatedPath(2, :))) / length(visualFormatedPath(2, :))) * 0.2 * length(visualFormatedPath(2, :));
                reStep = (abs(max(visualFormatedPath(1, :)) - min(visualFormatedPath(1, :))) / length(visualFormatedPath(1, :))) * 0.2 * length(visualFormatedPath(1, :));

                handles.CAField.YTick = [min(visualFormatedPath(2, :)):imStep:max(visualFormatedPath(2, :))];
                handles.CAField.XTick = [min(visualFormatedPath(1, :)):reStep:max(visualFormatedPath(1, :))];

                ImLength = max(visualFormatedPath(2, :)) - min(visualFormatedPath(2, :));
                ReLength = max(visualFormatedPath(1, :)) - min(visualFormatedPath(1, :));

                Coeff = ReLength - ImLength;

                if Coeff ~= 0

                    if Coeff < 0
                        Coeff = abs(Coeff);

                        handles.CAField.XLim = [min(visualFormatedPath(1, :)) - Coeff / 2 max(visualFormatedPath(1, :)) + Coeff / 2];

                    else

                        handles.CAField.YLim = [min(visualFormatedPath(2, :)) - Coeff / 2 max(visualFormatedPath(2, :)) + Coeff / 2];

                    end

                end
                                
                xticks('auto');
                yticks('auto');

                handles.CAField.XGrid = 'on';
                handles.CAField.YGrid = 'on';

                MakeTitle(obj, point, handles);

                if visualPathLength < 15
                    clrbr = colorbar('Ticks', [1:visualPathLength] / visualPathLength, 'TickLabels', {1:visualPathLength});
                else
                    clrbr = colorbar('Ticks', [0, 0.2, 0.4, 0.6, 0.8, 1], ...
                        'TickLabels', {0, floor(visualPathLength * 0.2), floor(visualPathLength * 0.4), floor(visualPathLength * 0.6), floor(visualPathLength * 0.8), visualPathLength - 1});
                    clrbr.Label.String = '„исло итераций';
                end

                zoom on;
                graphics.Clrbr = clrbr;
                graphics.Clrmp = clrmp;
            end

        end

        check

        function MakeTitle(obj, point, handles)

            titleStr = strcat('z\rightarrow', strrep(point.IteratedFuncStr, '@(z)', ''));

            titleStr = strrep(titleStr, 'mu0', '\mu_{0}');
            titleStr = regexprep(titleStr, 'mu(?!_)', '\\mu');
            titleStr = strrep(titleStr, '*', '\cdot');

            titleStr = strcat(titleStr, ' ; z_{0}=', num2str(point.FuncParams('z0')));
            titleStr = strcat(titleStr, ' ; \mu=', num2str(point.FuncParams('mu')));
            titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(point.FuncParams('mu0')));

            if contains(titleStr, 'eq')
                titleStr = strrep(titleStr, 'eq', 'z^{*}');
                titleStr = strcat(titleStr, ' ; z^{*}=', num2str(point.FuncParams('z*')));
            end

            title(handles.CAField, strcat('\fontsize{16}', titleStr));
            handles.CAField.FontSize = 10;
        end

    end

end
