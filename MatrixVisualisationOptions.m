classdef MatrixVisualisationOptions < VisualisationOptions

    methods

        function obj = MatrixVisualisationOptions(colorMap)

            arguments
                colorMap (1, :) char
            end

            obj.ColorMap = colorMap;

        end

        function [res, obj, graphics] = PrepareDataAndAxes(obj, matr, handles)

            arguments
                obj MatrixVisualisationOptions
                matr IteratedMatrix
                handles struct
            end

            res = [];

            axes(handles.CAField);

            Fcode = matr.PointsFates;
            fStepNew = matr.PointsSteps;

            clmp = [];

            maxPosSteps = max(fStepNew(find(Fcode == 1)));

            if isempty(maxPosSteps)
                maxPosSteps = 0;
            end

            maxNegSteps = max(fStepNew(find(Fcode == 0)));

            if isempty(maxNegSteps)
                maxNegSteps = 0;
            end

            maxPeriodSteps = max(Fcode(find(Fcode > 1 & Fcode ~= inf)));

            if isempty(maxPeriodSteps)
                maxPeriodSteps = 0;
            end

            chaosCheck = ~isempty(find(Fcode == inf));

            fStepNew(find(Fcode == inf)) = max(maxNegSteps) + 1;
            fStepNew(find(Fcode > 1 & Fcode < inf)) = Fcode(find(Fcode > 1 & Fcode < inf)) + maxPosSteps;

            Fcode(find(Fcode == 0 | Fcode == inf)) = -1;
            Fcode(find(Fcode > 1 & Fcode ~= inf)) = 1;

            clmp = [spring(chaosCheck); flipud(gray(maxNegSteps)); flipud(winter(maxPosSteps)); autumn(maxPeriodSteps)];
            clrmp = colormap(clmp);

            pcolor(matr.WindowOfValues{1}, matr.WindowOfValues{2}, (fStepNew .* Fcode));

            shading flat;
            clrbr = colorbar;

            if ~isempty(maxPeriodSteps)
                lim = clrbr.Limits;
                ticks = clrbr.Ticks;
                ticksDelta = ticks(2) - ticks(1);

                if lim(2) > maxPosSteps + ticksDelta / 5
                    ticks = ticks(find(ticks <= maxPosSteps));
                    ticks = [ticks maxPosSteps + ticksDelta / 5:ticksDelta / 5:lim(2)];
                    clrbr.Ticks = ticks;

                    lables = clrbr.TickLabels';
                    lables = arrayfun(@(num)str2double(cell2mat(num)), lables);
                    newLables = [lables(find(lables <= maxPosSteps)) (lables(find(lables > maxPosSteps)) - maxPosSteps)];
                    clrbr.TickLabels = {newLables};
                end

            end

            zoom on;
            MakeTitle(obj, matr, handles);

            graphics.Axs = handles.CAField;
            graphics.Clrbr = clrbr;
            graphics.Clrmp = clrmp;
        end

        function MakeTitle(obj, matr, handles)

            arguments
                obj MatrixVisualisationOptions
                matr IteratedMatrix
                handles struct
            end

            paramsSubStr = matr.ConstIteratedFuncStr(1:find(matr.ConstIteratedFuncStr == ')', 1, 'first'));
            titleStr = strcat('z\rightarrow', strrep(matr.ConstIteratedFuncStr, paramsSubStr, ''));

            titleStr = regexprep(titleStr, 'mu(?!\d)', '\mu');
            titleStr = strrep(titleStr, 'mu0', '\mu_{0}');
            titleStr = strrep(titleStr, '*', '\cdot');

            switch string(matr.WindowParam.Name)
                case "z0"
                    titleStr = strcat(titleStr, ' ; z_{cntr}=', num2str(matr.WindowParam.Value));
                    titleStr = strcat(titleStr, ' ; \mu=', num2str(matr.FuncParams('mu')));
                    titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(matr.FuncParams('mu0')));

                    if contains(titleStr, 'eq')
                        titleStr = strrep(titleStr, 'eq', 'z^{*}');
                        titleStr = strcat(titleStr, ' ; z^{*}=', num2str(IteratedMatrix.CountZBaze(matr.FuncParams('mu'), matr.WindowParam.Value)));
                    end

                    xlabel('Re(z_{0})');
                    ylabel('Im(z_{0})');

                case "mu"
                    titleStr = strcat(titleStr, ' ; z_{0}=', num2str(matr.FuncParams('z0')));
                    titleStr = strcat(titleStr, ' ; \mu_{cntr}=', num2str(matr.WindowParam.Value));
                    titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(matr.FuncParams('mu0')));
                    titleStr = strrep(titleStr, 'eq', 'z^{*}');

                    xlabel('Re(\mu)');
                    ylabel('Im(\mu)');
                case "mu0"

                    titleStr = strcat(titleStr, ' ; z_{0}=', num2str(matr.FuncParams('z0')));
                    titleStr = strcat(titleStr, ' ; \mu=', num2str(matr.FuncParams('mu')));
                    titleStr = strcat(titleStr, ' ; \mu_{0}_{cntr}=', num2str(matr.WindowParam.Value));

                    if contains(titleStr, 'eq')
                        titleStr = strrep(titleStr, 'eq', 'z^{*}');
                        titleStr = strcat(titleStr, ' ; z^{*}=', num2str(IteratedMatrix.CountZBaze(matr.FuncParams('mu'), matr.FuncParams('z0'))));
                    end

                    xlabel('Re(\mu_{0})');
                    ylabel('Im(\mu_{0})');

            end

            title(handles.CAField, strcat('\fontsize{16}', titleStr));
            handles.CAField.FontSize = 10;
        end

    end

end
