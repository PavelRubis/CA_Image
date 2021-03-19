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

            %
            fcodeIndicate = find(Fcode == 1);
            posSteps = unique(fStepNew(fcodeIndicate));

            fcodeIndicate = find(Fcode == 0);
            negSteps = unique(fStepNew(fcodeIndicate));

            chaosCodeIndicate = find(Fcode == inf);

            periodCodeIndicate = find(Fcode > 1 & Fcode ~= inf);
            fStepNew(periodCodeIndicate) = matr.PointsSteps(periodCodeIndicate);

            maxPosSteps = zeros(size(fStepNew));

            clmp = [];

            if ~isempty(posSteps)
                maxPosSteps(:) = max(posSteps);

                fStepNew(periodCodeIndicate) = maxPosSteps(periodCodeIndicate) + matr.PointsSteps(periodCodeIndicate);

                if ~isempty(negSteps)
                    fStepNew(chaosCodeIndicate) = max(negSteps) + 1;
                    clmp = [flipud(gray(max(negSteps))); flipud(winter(floor((max(negSteps) * ((max(posSteps) + 2) / max(negSteps))))))]; %(max(posSteps)-mod(max(posSteps),10))
                    Fcode(find(Fcode == 0)) = -1;
                else
                    clmp = flipud(winter(floor((max(posSteps) - mod(max(posSteps), 10)))));
                end

            else

                if ~isempty(negSteps)
                    clmp = flipud(gray(max(negSteps)));
                    Fcode(find(Fcode == 0)) = -1;
                end

            end

            if ~isempty(chaosCodeIndicate)
                clmp = [spring(1); clmp];
                Fcode(chaosCodeIndicate) = -1;
            end

            if ~isempty(periodCodeIndicate)
                clmp = [clmp; autumn(max(matr.PointsSteps(periodCodeIndicate)))];
                Fcode(periodCodeIndicate) = 1;
            end

            clrmp = colormap(clmp);

            pcolor(matr.WindowOfValues{1}, matr.WindowOfValues{2}, (fStepNew .* Fcode));

            shading flat;
            clrbr = colorbar;

            if ~isempty(periodCodeIndicate)
                lim = clrbr.Limits;
                ticks = clrbr.Ticks;
                ticksDelta = ticks(2) - ticks(1);

                if lim(2) > max(posSteps) + ticksDelta / 5
                    ticks = ticks(find(ticks <= max(posSteps)));
                    ticks = [ticks max(posSteps) + ticksDelta / 5:ticksDelta / 5:lim(2)];
                    clrbr.Ticks = ticks;

                    lables = clrbr.TickLabels';
                    lables = arrayfun(@(num)str2double(cell2mat(num)), lables);
                    newLables = [lables(find(lables <= max(posSteps))) (lables(find(lables > max(posSteps))) - max(posSteps))];
                    clrbr.TickLabels = {newLables};
                end

            end

            zoom on;
            MakeTitle(obj, matr, handles);

            graphics.Axs = handles.CAField;
            graphics.Clrbr = clrbr;
            graphics.Clrmp = clrmp;
            %

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
