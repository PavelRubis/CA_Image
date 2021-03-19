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

        function obj = SaveModelingResults(obj, res, iteratedObject, calcParms, graphics)

            arguments
                obj SaveResults
                res (2, :) double;
                iteratedObject IIteratedObject
                calcParms ModelingParamsForPath
                graphics struct
            end

            if obj.IsSaveData

                switch class(iteratedObject)
                    case 'IteratedPoint'
                        obj = SavePointPath(obj, res, iteratedObject, calcParms);
                    case 'IteratedMatrix'
                        obj = SaveMatrixPath(obj, iteratedObject, calcParms);
                end

            end

        end

        function obj = SaveFig(obj, graphics)

            arguments
                obj SaveResults
                graphics struct
            end

            fig = graphics.Axs;

            if obj.FigureFileFormat == 1
                h = figure;
                set(h, 'units', 'normalized', 'outerposition', [0 0 1 1])
                colormap(graphics.Clrmp);
                h.CurrentAxes = copyobj([fig graphics.Clrbr], h);
                h.Visible = 'on';
            else
                set(fig, 'Units', 'pixel');
                pos = fig.Position;
                marg = 40;

                if contParms.SingleOrMultipleCalc
                    rect = [-2 * marg, -marg, pos(3) + 2.5 * marg, pos(4) + 2 * marg];
                else
                    rect = [-2 * marg, -1.5 * marg, pos(3) + 4.5 * marg, pos(4) + 2.5 * marg];
                end

                photo = getframe(fig, rect);
                [photo, cmp] = frame2im(photo);
                photoName = strcat(obj.ResPath, '\CAField');

                switch obj.FigureFileFormat
                    case 2
                        imwrite(photo, jet(256), strcat(photoName, '.png'));
                    case 3
                        imwrite(photo, strcat(photoName, '.jpg'), 'jpg', 'Quality', 100);
                end

                set(fig, 'Units', 'normalized');
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

                fprintf(fileID, 'Re\t\t\tIm\tFate\tlength\n');

                fprintf(fileID, '%.8e\t%.8e\t%d\t%d\r\n', res(1, end), res(2, end), point.Fate, point.LastIterNum - 1);

                fprintf(fileID, '\n\nТраектория:\n');
                fprintf(fileID, 'iter\t\tRe\t\tIm\n');
                fclose(fileID);
            else
                %8,12 15 17
                txtCell = SaveResults.txt2Cell(obj.ResultsFilename);
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

                SaveResults.cell2Txt(obj.ResultsFilename, txtCell, 'w');
            end

            iters = (lastIter:(lastIter - 1) + length(res(1, :)));
            SaveResults.createAndWriteTable2Txt(obj.ResultsFilename, iters, res);
        end

        function obj = SaveMatrixPath(obj, matr, calcParms)
            ConfFileName = strcat('\MultiCalc-', datestr(clock));
            ConfFileName = strcat(ConfFileName, '.txt');
            ConfFileName = strrep(ConfFileName, ':', '-');
            ConfFileName = strcat(obj.ResPath, ConfFileName);

            fileID = fopen(ConfFileName, 'w');
            fprintf(fileID, strcat('Множественное Моделирование от- ', datestr(clock)));

            fprintf(fileID, strcat('\n\nОтображение: ', func2str(contParms.ImageFunc)));

            PrecisionParms = ControlParams.GetSetPrecisionParms;

            fprintf(fileID, strcat('\n\n\nМаксимальный период=', num2str(ControlParams.GetSetMaxPeriod), '\nПорог бесконечности=', num2str(10^PrecisionParms(1)), '\nПорог сходимости=', num2str(PrecisionParms(2))));

            switch contParms.WindowParamName
                case 'z0'
                    fprintf(fileID, strcat('\nz0=', num2str(complex(mean(contParms.ReRangeWindow), mean(contParms.ImRangeWindow))), '\nmu=', num2str(ca.Miu), '\nmu0=', num2str(ca.Miu0)));
                otherwise
                    fprintf(fileID, strcat('\nz0=', num2str(contParms.SingleParams(1)), '\nmu=', num2str(ca.Miu), '\nmu0=', num2str(ca.Miu0)));
            end

            fprintf(fileID, '\nКоличество итераций T=%f\n', length(Res) - 1);

            fprintf(fileID, strcat('\nПараметр окна: ', contParms.WindowParamName));
            fprintf(fileID, '\nДиапазон параметра окна: ');

            paramStart = complex(contParms.ReRangeWindow(1), contParms.ImRangeWindow(1));
            paramStep = complex(contParms.ReRangeWindow(2) - contParms.ReRangeWindow(1), contParms.ImRangeWindow(2) - contParms.ImRangeWindow(1));
            paramEnd = complex(contParms.ReRangeWindow(end), contParms.ImRangeWindow(end));

            paramStartSrt = strcat(num2str(paramStart), ' : ');
            paramEndSrt = strcat(' : ', num2str(paramEnd));
            paramSrt = strcat(paramStartSrt, num2str(paramStep));
            paramSrt = strcat(paramSrt, paramEndSrt);
            fprintf(fileID, strcat(paramSrt, '\n\n'));
            fclose(fileID);
            dlmwrite(ConfFileName, 'Re	Im	Fate	length', '-append', 'delimiter', '');

            [X, Y] = meshgrid(contParms.ReRangeWindow, contParms.ImRangeWindow);
            WindowParam = X + i * Y;
            len = size(WindowParam);
            resArr = cell(len);
            resArr = arrayfun(@(re, im, p, n){[re im p n]}, real(WindowParam), imag(WindowParam), contParms.Periods, contParms.LastIters);

            resArr = cell2mat(resArr);
            resLen = size(resArr);

            resArrNew = zeros(len(1) * len(2), 4);
            c = 0;

            for j = 1:4:resLen(2)
                resArrNew(c * resLen(1) + 1:resLen(1) * (c + 1), :) = resArr(:, j:j + 3);
                c = c + 1;
            end

            dlmwrite(ConfFileName, resArrNew, '-append', 'delimiter', '\t');
        end

    end

    methods (Static)

        function createAndWriteTable2Txt(fileName, iters, res)

            arguments
                fileName (1, :) char
                iters (1, :) double
                res (:, :) double
            end

            iters = iters';
            res = res';
            res = [arrayfun(@(iter) {iter}, iters) arrayfun(@(item) {num2str(item, '%.8e')}, res)];
            writeableRes = cell2table(res);

            writetable(writeableRes, 'table.txt', 'Delimiter', '\t', 'WriteVariableNames', false);

            txtCell = SaveResults.txt2Cell('table.txt');
            SaveResults.cell2Txt(fileName, txtCell, 'a');
            delete table.txt;

        end

        function A = txt2Cell(fileName)
            fileID = fopen(fileName, 'r');
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

        function cell2Txt(fileName, A, permission)
            fileID = fopen(fileName, permission);

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

        %{

        function writePointResults(fileName, iters, res)

            arguments
                fileName (1, :) char
                iters (1, :) double
                res (2, :) double
            end

            iters = iters';
            res = res';
            res = [arrayfun(@(iter) {iter}, iters) arrayfun(@(item) {str2double(num2str(item, '%.8e'))}, res)];

            rowsCount = 1:length(iters);
            writeableRes = arrayfun(@(ind) res(ind, :), rowsCount, 'UniformOutput', false);

            fileID = fopen(fileName, 'a');
            arrayfun(@(formattedRow) fprintf(fileID, '%d\t%.8e\t%.8e\r\n', formattedRow{1}{1}, formattedRow{1}{2}, formattedRow{1}{3}), writeableRes, 'UniformOutput', false);
            fclose(fileID);
        end

        function len = writeMatrix2txt(filename, matrix, delimiter)

            arguments
                filename (1, :) char
                matrix (:, :) double
                delimiter (1, :) char
            end

            lenArr = arrayfun(@(col) SaveResults.getLongestItemLength(col{1}), SaveResults.getMatrixColumns(matrix));

            formattedRows = arrayfun(@(row) SaveResults.getFormattedRow(row{1}, delimiter, lenArr), SaveResults.getMatrixRows(matrix));

            arrayfun(@(formattedRow) dlmwrite(filename, formattedRow{1}, '-append', 'delimiter', ''), formattedRows, 'UniformOutput', false);

        end

        function formattedRow = getFormattedRow(row, delimiter, longestItemsLength)

            arguments
                row (1, :) double;
                delimiter (1, :) char;
                longestItemsLength (1, :) double;
            end

            formattedRow = {arrayfun(@(item, len) {SaveResults.getFormattedItem(item, len, delimiter)}, row, longestItemsLength)};

        end

        function formattedItem = getFormattedItem(item, longestItemLen, baseDelimiter)

            arguments
                item double;
                longestItemLen double;
                baseDelimiter (1, :) char;
            end

            spaceSign = ' ';
            itemStr = num2str(item, '%.8e');
            delimiter = cell(1, longestItemLen - length(itemStr));

            baseDelimiter = {baseDelimiter};

            if ~isempty(delimiter)
                delimiter(:) = {spaceSign};
                baseDelimiter = [delimiter baseDelimiter];
            end

            formattedItem = cell2mat([itemStr {cell2mat(baseDelimiter)}]);

        end

        function rows = getMatrixRows(matrix)

            arguments
                matrix (:, :) double;
            end

            rows = arrayfun(@(ind) {matrix(ind, :)}, 1:length(matrix(:, 1)));

        end

        function cols = getMatrixColumns(matrix)

            arguments
                matrix (:, :) double;
            end

            cols = arrayfun(@(ind) {matrix(:, ind)}, 1:length(matrix(1, :)));

        end

        function len = getLongestItemLength(matrixColumn)

            arguments
                matrixColumn (1, :) double;
            end

            len = max(arrayfun(@(item) length(cell2mat(item)), arrayfun(@(item) {num2str(item, '%.8e')}, matrixColumn)));

        end

        %}

    end

end

function mustBeInRange(a, b)

    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ', ...
                num2str(b(1)), '...', num2str(b(2))])
    end

end
