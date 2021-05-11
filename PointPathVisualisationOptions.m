classdef PointPathVisualisationOptions < VisualisationOptions

    properties
        XAxesdataProcessingFunc function_handle
        YAxesdataProcessingFunc function_handle

        XAxescolorMapLabel (1, :) char
        YAxescolorMapLabel (1, :) char

        VisualPath (1, :) double
    end

    methods (Static)

        function out = GetSetPointPathVisualisationOptions(colorMap, xAxesdataProcessingFunc, yAxesdataProcessingFunc, xAxescolorMapLabel, yAxescolorMapLabel, visualpath)
%             mlock

            persistent clrMap;
            persistent xAxesdataFunc;
            persistent yAxesdataFunc;
            persistent xAxesLabel;
            persistent yAxesLabel;
            persistent visualPath;

            if nargin == 6
                clrMap = colorMap;
                xAxesdataFunc = xAxesdataProcessingFunc;
                yAxesdataFunc = yAxesdataProcessingFunc;
                xAxesLabel = xAxescolorMapLabel;
                yAxesLabel = yAxescolorMapLabel;
                visualPath = visualpath;
            end

            out = PointPathVisualisationOptions(clrMap, xAxesdataFunc, yAxesdataFunc, xAxesLabel, yAxesLabel, visualPath);
        end

    end

    methods

        function obj = PointPathVisualisationOptions(colorMap, xAxesdataProcessingFunc, yAxesdataProcessingFunc, xAxescolorMapLabel, yAxescolorMapLabel, visualpath)

            arguments
                colorMap (1, :) char
                xAxesdataProcessingFunc function_handle
                yAxesdataProcessingFunc function_handle
                xAxescolorMapLabel (1, :) char
                yAxescolorMapLabel (1, :) char
                visualpath (:, :) double
            end

            obj.ColorMap = colorMap;

            obj.XAxesdataProcessingFunc = xAxesdataProcessingFunc;
            obj.YAxesdataProcessingFunc = yAxesdataProcessingFunc;
            obj.XAxescolorMapLabel = xAxescolorMapLabel;
            obj.YAxescolorMapLabel = yAxescolorMapLabel;
            obj.VisualPath = visualpath;

        end

        function [newPathPart obj graphics] = PrepareDataAndAxes(obj, point, handles)

            arguments
                obj PointPathVisualisationOptions
                point IteratedPoint
                handles struct
            end

            str = strcat({'�����'},{' '}, {num2str(point.InitState)});

            switch point.Fate
                case 0
                    msg = strcat(str, {' ������ � ������������� �� ��������:'},{' '}, {num2str(point.LastIterNum - 1)});
                case 1
                    msg = strcat(str, {' �������� � ���������� �� ��������:'},{' '}, {num2str(point.LastIterNum - 1)});
                case inf
                otherwise
                    msg = strcat(str, {' ����� ������:'},{' '}, {num2str(point.Fate)}, {' '},{', ��������� �� ��������:'},{num2str(point.LastIterNum - 1)});
            end

            visualPath = [];

            if length(point.StatePath) > ModelingParams.GetIterCount
                visualPath = point.StatePath(length(point.StatePath) - ModelingParams.GetIterCount:end);
            else
                visualPath = point.StatePath;
            end

            visualPath = visualPath(find(~isnan(visualPath)));
            obj.VisualPath = visualPath;

            graphics = FormatAndPlotPath(obj, point, handles);

            newPathPart = [real(obj.VisualPath); imag(obj.VisualPath)];

            if point.Fate ~= inf
                msgbox(msg, '������������� ���������');
            end

        end

        function graphics = FormatAndPlotPath(obj, point, handles)

            arguments
                obj PointPathVisualisationOptions
                point IteratedPoint
                handles struct
            end

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

                handles.CAField.DataAspectRatio = [1 1 1];
                                
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
                    clrbr.Label.String = '����� ��������';
                end

                zoom on;
                graphics.Clrbr = clrbr;
                graphics.Clrmp = clrmp;
            end

        end

        check

        function MakeTitle(obj, point, handles)

            arguments
                obj PointPathVisualisationOptions
                point IteratedPoint
                handles struct
            end

            titleStr = strcat('z\rightarrow', strrep(point.IteratedFuncStr, '@(z)', ''));

            titleStr = strrep(titleStr, 'mu0', '\mu_{0}');
            titleStr = regexprep(titleStr, 'mu(?!_)', '\mu');
            titleStr = strrep(titleStr, '*', '\cdot');

            titleStr = strcat(titleStr, ' ; z_{0}=', num2str(point.FuncParams('z0')));
            titleStr = strcat(titleStr, ' ; \mu=', num2str(point.FuncParams('mu')));
            titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(point.FuncParams('mu0')));

            if contains(titleStr, 'eq')
                titleStr = strrep(titleStr, 'eq', 'z^{*}');
                titleStr = strcat(titleStr, ' ; z^{*}', num2str(point.FuncParams('z*')));
            end

            title(handles.CAField, strcat('\fontsize{16}', titleStr));
            handles.CAField.FontSize = 10;
        end

    end

end
