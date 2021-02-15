classdef SaveResults

    properties
        IsSave logical = false
        IsSaveData logical
        IsSaveFig logical
        ResultsPath (1, :) char
        ResultsFilename (1, :) char
        DataFileFormat double {mustBeInteger, mustBeInRange(DataFileFormat, [0, 1])}
        FigureFileFormat double {mustBeInteger, mustBeInRange(FigureFileFormat, [1, 3])}
    end

    methods

        function obj = SaveResults()
            obj.IsSave = false;
            obj.IsSaveData = false;
            obj.IsSaveFig = false;
            obj.ResultsPath = '';
            obj.ResultsFilename = '';
            obj.DataFileFormat = 1;
            obj.FigureFileFormat = 1;
        end

        function obj = SavePointResults(obj, res, point, calcParms)

            arguments
                obj SaveResults
                res (2, :) double;
                point IteratedPoint
                calcParms ModelingParamsForPath
            end

            if obj.IsSaveData
                obj = SavePointPath(obj, res, point, calcParms);
            end

        end

        function obj = SavePointPath(obj, res, point, calcParms)

            arguments
                obj SaveResults
                res (2, :) double;
                point IteratedPoint
                calcParms ModelingParamsForPath
            end

            lastIter = 1;
            res = res(:, 2:end);

            if isempty(obj.ResultsFilename)
                obj.ResultsFilename = strcat('\Modeling-', datestr(clock));
                obj.ResultsFilename = strcat(obj.ResultsFilename, '-N-1-Path.txt');
                obj.ResultsFilename = strrep(obj.ResultsFilename, ':', '-');
                obj.ResultsFilename = strcat(obj.ResultsPath, obj.ResultsFilename);

                fileID = fopen(obj.ResultsFilename, 'a');
                fprintf(fileID, strcat('Одиночное Моделирование от-', datestr(clock)));
                fprintf(fileID, strcat('\n\n\nОтображение: ', strrep(point.IteratedFuncStr, '@(z)', '')));
                fprintf(fileID, strcat('\n\n\nМаксимальный период=', num2str(calcParms.MaxPeriod), ';Порог бесконечности=', strcat('1e+', num2str(calcParms.InfVal)), ';Порог сходимости=', num2str(calcParms.EqualityVal)));

                funcParamsNames = keys(point.FuncParams);
                funcParamsValues = values(point.FuncParams);

                for index = 1:length(point.FuncParams)
                    fprintf(fileID, strcat('\n', funcParamsNames{index}, '=', num2str(funcParamsValues{index})));
                end

                fprintf(fileID, '\nКоличество итераций T=%f\n', length(res));

                switch point.Fate
                    case 0
                        fprintf(fileID, '\n\nИтог: уходящая в бесконечность траектория\n');
                    case 1
                        fprintf(fileID, '\n\nИтог: сходящаяся к аттрактору траектория\n');
                    case inf
                        fprintf(fileID, '\n\nИтог: хаотичная траектория\n');
                    otherwise
                        fprintf(fileID, strcat('\n\nИтог: траектория с периодом: ', num2str(point.Fate), '\n'));
                end

                fprintf(fileID, 'Re\tIm\tFate\tlength\n');
                fclose(fileID);

                dlmwrite(obj.ResultsFilename, [real(res(end)) imag(res(end)) point.Fate point.LastIterNum - 1], '-append', 'delimiter', '\t');

                fileID = fopen(obj.ResultsFilename, 'a');
                fprintf(fileID, '\n\nТраектория:\n');
                fprintf(fileID, 'iter\tRe\tIm\n');
                fclose(fileID);
            else
                %8,12 15 17
                txtCell = SaveResults.txt2Cell(obj);
                lastIter = str2double(regexp(txtCell{end - 2}, '^\d+\s', 'match')) + 1;

                txtCell{7} = strcat('Максимальный период=', num2str(calcParms.MaxPeriod), ';Порог бесконечности=', strcat('1e+', num2str(calcParms.InfVal)), ';Порог сходимости=', num2str(calcParms.EqualityVal));
                txtCell{11} = strcat('Количество итераций T=', num2str(length(res)));

                finishStr = '';

                switch point.Fate
                    case 0
                        finishStr = 'уходящая в бесконечность траектория';
                    case 1
                        finishStr = 'сходящаяся к аттрактору траектория';
                    case inf
                        finishStr = 'хаотичная траектория';
                    otherwise
                        finishStr = strcat('траектория с периодом: ', num2str(point.Fate));
                end

                txtCell{14} = strcat('Итог: ', finishStr);
                txtCell{16} = cell2mat(strcat({num2str(real(res(end)))}, {'	'}, {num2str(imag(res(end)))}, {'	'}, {num2str(point.Fate)}, {'	'}, {num2str(point.LastIterNum)}));

                SaveResults.cell2Txt(obj, txtCell);
            end

            iters = (lastIter:(lastIter - 1) + length(res(1, :)));

            iters = iters';
            res = res';
            res = [iters res];
            dlmwrite(obj.ResultsFilename, res, '-append', 'delimiter', '\t', 'precision', str2double(regexp(num2str(calcParms.EqualityVal), '\d+$', 'match')));
            dlmwrite(obj.ResultsFilename, ' ', '-append');

        end

    end

    methods (Static)

        function A = txt2Cell(obj)
            fileID = fopen(obj.ResultsFilename, 'r');
            i = 1;
            tline = fgetl(fileID);
            A{i} = tline;

            while ischar(tline)
                i = i + 1;
                tline = fgetl(fileID);
                A{i} = tline;
            end

            fclose(fileID);
        end

        function cell2Txt(obj, A)
            fileID = fopen(obj.ResultsFilename, 'w');

            for i = 1:numel(A)

                if A{i + 1} == -1
                    fprintf(fileID, '%s\n\n', A{i});
                    break
                else
                    fprintf(fileID, '%s\n', A{i});
                end

            end

            fclose(fileID);

        end

        function obj = IsReady2Start(obj)

            arguments
                obj SaveResults
            end

            if (~obj.IsSave && any([obj.IsSaveFig obj.IsSaveData]))
                errordlg('Не указана директория сохранения результатов', 'Ошибка');
                obj = [];
            end

        end

    end

end

function mustBeInRange(a, b)

    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ', ...
                num2str(b(1)), '...', num2str(b(2))])
    end

end
