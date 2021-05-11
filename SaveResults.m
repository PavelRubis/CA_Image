classdef SaveResults

    properties
        IsSaveData logical = false
        ResultsPath(1, :) char
        ResultsFilename(1, :) char
        DataFileFormat double {mustBeInteger, mustBeInRange(DataFileFormat, [0, 1])}
        FigureFileFormat double {mustBeInteger, mustBeInRange(FigureFileFormat, [1, 3])}
    end

    methods

        function obj = SaveResults()
            obj.IsSaveData = false;
            obj.ResultsPath = '';
            obj.ResultsFilename = '';
            obj.DataFileFormat = 1;
            obj.FigureFileFormat = 1;
        end

        function obj = SaveModelingResults(obj, res, oldIteratedObject, iteratedObject, calcParms, graphics)

            arguments
                obj SaveResults
                res(:, :) double;
                oldIteratedObject IIteratedObject
                iteratedObject IIteratedObject
                calcParms ModelingParams
                graphics struct
            end

            if obj.IsSaveData

                switch class(iteratedObject)
                    case 'IteratedPoint'

                        if isinf(oldIteratedObject.Fate)
                            obj = SavePointPath(obj, res, iteratedObject, calcParms);
                        end

                    case 'IteratedMatrix'
                        obj = SaveMatrixPath(obj, iteratedObject, calcParms);

                    case 'CellularAutomat'
                        obj = SaveCAState(obj, iteratedObject, calcParms);

                end

                [obj] = SaveFig(obj, graphics, iteratedObject);

            end

        end

        function obj = SaveFig(obj, graphics, iteratedObject)

            arguments
                obj SaveResults
                graphics struct
                iteratedObject IIteratedObject
            end

            fig = graphics.Axs;

            if obj.FigureFileFormat == 1
                h = figure('Visible', 'off');
                set(h, 'units', 'normalized', 'outerposition', [0, 0, 1, 1])
                colormap(graphics.Clrmp);
                h.CurrentAxes = copyobj([fig, graphics.Clrbr], h);
                h.Visible = 'on';
                savefig(h, strcat(strrep(obj.ResultsFilename, '.txt', ''), '.fig'));
                h.Visible = 'off';
                clear h;
            else
                set(fig, 'Units', 'pixel');
                pos = fig.Position;
                marg = 40;

                if string(class(iteratedObject)) ~= "IteratedMatrix"
                    rect = [-2 * marg, -marg, pos(3) + 2.5 * marg, pos(4) + 2 * marg];
                else
                    rect = [-2 * marg, -1.5 * marg, pos(3) + 4.5 * marg, pos(4) + 2.5 * marg];
                end

                photo = getframe(fig, rect);
                [photo, cmp] = frame2im(photo);
                photoName = strrep(obj.ResultsFilename, '.txt', '');

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
                res(2, :) double;
                point IteratedPoint
                calcParms ModelingParamsForPath
            end

            point.StatePath = point.StatePath(find(~isnan(point.StatePath)));

            lastIter = 1;
            res = res(:, 2:end);
            persistent resultsFilePath;
            if isempty(resultsFilePath)
                resultsFilePath = obj.ResultsPath;
            end
            pointOrRes = false;

            if isempty(obj.ResultsFilename) || string(resultsFilePath) ~= string(obj.ResultsPath)

                resultsFilePath = obj.ResultsPath;
                pointOrRes = true;

                obj.ResultsFilename = strcat('\Modeling-', datestr(clock));
                obj.ResultsFilename = strcat(obj.ResultsFilename, '-N-1-Path.txt');
                obj.ResultsFilename = strrep(obj.ResultsFilename, ':', '-');

                if SaveResults.IsCustomResultsPath(obj)
                    obj.ResultsFilename = strcat(obj.ResultsPath, obj.ResultsFilename);
                else
                    obj.ResultsFilename(1) = [];
                end

                fileID = fopen(obj.ResultsFilename, 'a');
                fprintf(fileID, strcat('Одиночное Моделирование от-', datestr(clock)));
                fprintf(fileID, strcat('\n\n\nОтображение: ', strrep(point.IteratedFuncStr, '@(z)', '')));

                fprintf(fileID, strcat('\n\nМаксимальный период=', num2str(calcParms.MaxPeriod), '\n'));
                fprintf(fileID, strcat('Порог бесконечности = ', num2str(10^calcParms.InfVal, '%.1e'), '\n'));
                fprintf(fileID, strcat('Порог сходимости=', num2str(calcParms.EqualityVal, '%.1e'), '\n'));

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

                fprintf(fileID, '%.8e\t%.8e\t%d\t%d\r\n', real(point.StatePath(end)), imag(point.StatePath(end)), point.Fate, point.LastIterNum);

                fprintf(fileID, '\n\nТраектория:\n');
                fprintf(fileID, 'iter\t\tRe\t\tIm\n');
                fclose(fileID);
            else
                %8,12 15 17
                txtCell = SaveResults.txt2Cell(obj.ResultsFilename);
                lastIter = str2double(regexp(txtCell{end - 2}, '^\d+\s', 'match')) + 1;

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

                txtCell{16} = strcat('Итог: ', finishStr);
                txtCell{18} = cell2mat(strcat({num2str(real(res(end)))}, {'	'}, {num2str(imag(res(end)))}, {'	'}, {num2str(point.Fate)}, {'	'}, {num2str(point.LastIterNum)}));

                SaveResults.cell2Txt(obj.ResultsFilename, txtCell, 'w');
            end

            iters = (lastIter:(lastIter - 1) + length(res(1, :)));
            SaveResults.WritePointPathTable2Txt(obj.ResultsFilename, iters, res, point, pointOrRes);
        end

        function obj = SaveCAState(obj, ca, calcParms)

            obj.ResultsFilename = strcat('\CA-Modeling-', datestr(clock), '.txt');
            obj.ResultsFilename = strrep(obj.ResultsFilename, ':', '-');

            if SaveResults.IsCustomResultsPath(obj)
                obj.ResultsFilename = strcat(obj.ResultsPath, obj.ResultsFilename);
            else
                obj.ResultsFilename(1) = [];
            end

            fileID = fopen(obj.ResultsFilename, 'a');
            fprintf(fileID, strcat('Моделирование клеточного автомата от-', datestr(clock)));
            fprintf(fileID, '\n\nКонфигурация КА:\n\n');

            if string(class(ca.Cells(1))) == "HexagonCACell"
                fprintf(fileID, 'Тип решетки поля: гексагональное\n');
            else
                fprintf(fileID, 'Тип решетки поля: квадратное\n');
            end

            if string(class(ca.Neighborhood)) == "MooreNeighbourHood"
                fprintf(fileID, 'Тип окрестности: Мура\n');
            else
                fprintf(fileID, 'Тип окрестности: фон-Неймана\n');
            end

            switch ca.Neighborhood.BordersType
                case 1
                    fprintf(fileID, 'Тип границ поля: "линия смерти"\n');
                case 2
                    fprintf(fileID, 'Тип границ поля: замыкание границ\n');
                case 3
                    fprintf(fileID, 'Тип границ поля: закрытые границы\n');
            end

            fprintf(fileID, 'Ребро N=%d\n', ca.N);
            fprintf(fileID, strcat('\nОтображение: ', strrep(ca.ConstIteratedFuncStr, '@(z,neibs,oness)', 'z->'), '\n'));

            funcParamsNames = keys(ca.FuncParams);
            funcParamsValues = values(ca.FuncParams);

            for index = 1:length(ca.FuncParams)
                fprintf(fileID, cell2mat(strcat({'Параметр '}, funcParamsNames(index), '=', num2str(funcParamsValues{index}), '\n')));
            end

            absoluteIter = length(ca.Cells(1).ZPath) - 1;
            lastAbsoluteIter = absoluteIter - calcParms.IterCount;

            fprintf(fileID, strcat('Всего итераций T=', num2str(absoluteIter), '\n\n\n'));
            fprintf(fileID, strcat('Конфигурация КА на предыдущем этапе расчета Tl=', num2str(lastAbsoluteIter), ':\n\n'));
            fclose(fileID);
            dlmwrite(obj.ResultsFilename, 'X       Y              Re	Im', '-append', 'delimiter', '');

            cells = ca.Cells';
            res = [arrayfun(@(caCell) {num2str(caCell.CAIndexes(1))}, cells), arrayfun(@(caCell) {num2str(caCell.CAIndexes(2))}, cells), arrayfun(@(caCell) {num2str(real(caCell.ZPath(lastAbsoluteIter + 1)), '%.8e')}, cells), arrayfun(@(caCell) {num2str(imag(caCell.ZPath(lastAbsoluteIter + 1)), '%.8e')}, cells)];

            writeableRes = cell2table(res);
            writetable(writeableRes, 'table.txt', 'Delimiter', '\t', 'WriteVariableNames', false);

            txtCell = SaveResults.txt2Cell('table.txt');
            SaveResults.cell2Txt(obj.ResultsFilename, txtCell, 'a');
            delete table.txt;

            for ind = lastAbsoluteIter + 2:absoluteIter + 1

                fileID = fopen(obj.ResultsFilename, 'a');
                fprintf(fileID, strcat('Значения ячеек на итерации Iter=', num2str(ind - 1), '\n\n'));
                fclose(fileID);
                dlmwrite(obj.ResultsFilename, 'X       Y              Re	Im', '-append', 'delimiter', '');

                res = [arrayfun(@(caCell) {num2str(caCell.CAIndexes(1))}, cells), arrayfun(@(caCell) {num2str(caCell.CAIndexes(2))}, cells), arrayfun(@(caCell) {num2str(real(caCell.ZPath(ind)), '%.8e')}, cells), arrayfun(@(caCell) {num2str(imag(caCell.ZPath(ind)), '%.8e')}, cells)];

                writeableRes = cell2table(res);
                writetable(writeableRes, 'table.txt', 'Delimiter', '\t', 'WriteVariableNames', false);

                txtCell = SaveResults.txt2Cell('table.txt');
                SaveResults.cell2Txt(obj.ResultsFilename, txtCell, 'a');
                delete table.txt;
            end

        end

        function obj = SaveMatrixPath(obj, matr, calcParms)
            obj.ResultsFilename = strcat('\MultiCalc-', datestr(clock));
            obj.ResultsFilename = strcat(obj.ResultsFilename, '.txt');
            obj.ResultsFilename = strrep(obj.ResultsFilename, ':', '-');

            if SaveResults.IsCustomResultsPath(obj)
                obj.ResultsFilename = strcat(obj.ResultsPath, obj.ResultsFilename);
            else
                obj.ResultsFilename(1) = [];
            end

            fileID = fopen(obj.ResultsFilename, 'w');

            paramsSubStr = matr.ConstIteratedFuncStr(1:find(matr.ConstIteratedFuncStr == ')', 1, 'first'));

            fprintf(fileID, strcat('Множественное моделирование от- ', datestr(clock)));

            fprintf(fileID, strcat('\n\nОтображение: ', strrep(matr.ConstIteratedFuncStr, paramsSubStr, '')));

            PrecisionParms = ModelingParams.GetSetPrecisionParms;

            fprintf(fileID, strcat('\n\nМаксимальный период=', num2str(ModelingParamsForPath.GetSetMaxPeriod), '\n'));
            fprintf(fileID, strcat('Порог бесконечности = ', num2str(10^PrecisionParms(1), '%.1e'), '\n'));
            fprintf(fileID, strcat('Порог сходимости=', num2str(PrecisionParms(2), '%.1e'), '\n'));

            funcParamsNames = keys(matr.FuncParams);
            funcParamsValues = values(matr.FuncParams);

            for index = 1:length(matr.FuncParams)

                if string(funcParamsNames(index)) ~= string(matr.WindowParam.Name)
                    fprintf(fileID, cell2mat(strcat('\n', funcParamsNames(index), '=', num2str(funcParamsValues{index}))));
                end

            end

            fprintf(fileID, '\nКоличество итераций T=%f\n', calcParms.IterCount);

            fprintf(fileID, strcat('\nПараметр окна: ', matr.WindowParam.Name));
            fprintf(fileID, strcat('\nЦентральное значение параметра окна: ', num2str(matr.WindowParam.Value)));
            fprintf(fileID, '\nДиапазон параметра окна: ');

            tmpVal = sort(unique(matr.WindowOfValues{1}));
            fprintf(fileID, strcat('\nRe: ', num2str(matr.WindowOfValues{1}(1)), ':', num2str(tmpVal(2) - tmpVal(1)), ':', num2str(matr.WindowOfValues{1}(end))));
            fprintf(fileID, strcat('\nIm: ', num2str(matr.WindowOfValues{2}(1)), ':', num2str(matr.WindowOfValues{2}(2) - matr.WindowOfValues{2}(1)), ':', num2str(matr.WindowOfValues{2}(end)), '\n\n'));

            fclose(fileID);
            dlmwrite(obj.ResultsFilename, 'Re              Im              Fate	length', '-append', 'delimiter', '');

            WindowParam = matr.WindowOfValues{1} + 1i * matr.WindowOfValues{2};

            WindowParam = WindowParam(:)';
            WindowParam = WindowParam';

            matr.PointsFates = matr.PointsFates(:)';
            matr.PointsFates = matr.PointsFates';

            matr.PointsSteps = matr.PointsSteps(:)';
            matr.PointsSteps = matr.PointsSteps';

            res = [arrayfun(@(item) {num2str(item, '%.8e')}, real(WindowParam)), arrayfun(@(item) {num2str(item, '%.8e')}, imag(WindowParam)), arrayfun(@(fate) {fate}, matr.PointsFates), arrayfun(@(step) {step}, matr.PointsSteps)];

            writeableRes = cell2table(res);
            writetable(writeableRes, 'table.txt', 'Delimiter', '\t', 'WriteVariableNames', false);

            txtCell = SaveResults.txt2Cell('table.txt');
            SaveResults.cell2Txt(obj.ResultsFilename, txtCell, 'a');
            delete table.txt;
        end

    end

    methods (Static)

        function WritePointPathTable2Txt(fileName, iters, res, point, pointOrRes)

            arguments
                fileName(1, :) char
                iters(1, :) double
                res(:, :) double
                point IteratedPoint
                pointOrRes logical
            end

            if pointOrRes
                iters = 1:length(point.StatePath);
                res = [arrayfun(@(iter) {iter}, iters); arrayfun(@(zPathItem) {num2str(real(zPathItem), '%.8e')}, point.StatePath); arrayfun(@(zPathItem) {num2str(imag(zPathItem), '%.8e')}, point.StatePath)];
                res = res';
            else
                iters = iters';
                res = res';
                res = [arrayfun(@(iter) {iter}, iters), arrayfun(@(item) {num2str(item, '%.8e')}, res)];
            end
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

        function check = IsCustomResultsPath(obj)

            arguments
                obj SaveResults
            end

            check = true;

            if (obj.IsSaveData && (isempty(obj.ResultsPath) || ~ischar(obj.ResultsPath)))
                check = false;
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
