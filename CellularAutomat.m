classdef CellularAutomat < IIteratedObject & handle

    properties

        IteratedFunc
        FuncParams
        IteratedFuncStr

        Cells %массив всех €чеек на поле
        Neighborhood % тип окрестности
        N double {mustBePositive, mustBeInteger} % ребро пол€
        Weights(1, :) double = [1, 1, 1, 1, 1] % массив весов всех соседей и центральной €чейки
        ConstIteratedFuncStr(1, :) char
    end

    methods

        function obj = CellularAutomat()

            obj.IteratedFunc = @(z, neibs, oness)nan;
            obj.IteratedFuncStr = '@(z,neibs,oness)nan';
            obj.FuncParams = [];

        end

        function obj = Initialization(obj, handles)

            arguments
                obj CellularAutomat
                handles struct
            end

            errStruct.check = 0;
            errStruct.msg = 'ќшибки в текстовых пол€х параметров: ';
            setappdata(handles.output, 'errStruct', errStruct);

            errStruct = SetMainProperties(obj, handles, errStruct);

            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
                return;
            end

            SetFuncParams(obj, handles);
            GetIteratedFuncStr(obj, handles);
            errStruct = CheckIteratedFuncStr(obj, errStruct);

            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
                return;
            end

            CreateCAField(obj, handles);
            errStruct = CellsInitialization(obj, handles, errStruct);

            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
                return;
            end

        end


        function [obj] = BeforeModeling(obj)

            arguments
                obj CellularAutomat
            end
            obj = obj;
        end

        function errStruct = SetMainProperties(obj, handles, errStruct)

            if isempty(regexp(handles.NFieldEdit.String, '^\d+$')) || str2double(handles.NFieldEdit.String) < 3
                errStruct.check = true;
                errStruct.msg = strcat(errStruct.msg, 'N; ');
            else
                obj.N = str2double(handles.NFieldEdit.String);
            end

            obj.Neighborhood = getappdata(handles.output, 'Neighborhood');
        end

        function SetFuncParams(obj, handles)

            probalyParamsNames = {'z0', 'mu0', 'mu'};
            probalyParamsValues = [];

            if (~isempty(regexp(handles.z0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues, str2double(handles.z0Edit.String)];

            else
                probalyParamsValues = [probalyParamsValues, nan];
            end

            if (~isempty(regexp(handles.Miu0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues, str2double(handles.Miu0Edit.String)];

            else
                probalyParamsValues = [probalyParamsValues, nan];
            end

            if (~isempty(regexp(handles.MiuEdit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues, str2double(handles.MiuEdit.String)];

            else
                probalyParamsValues = [probalyParamsValues, nan];
            end

            obj.FuncParams = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for ind = 1:length(probalyParamsNames)
                obj.FuncParams(probalyParamsNames{ind}) = probalyParamsValues(ind);
            end

        end

        function GetIteratedFuncStr(obj, handles)

            funcStr = '';

            if ~handles.CustomIterFuncCB.Value

                switch handles.BaseImagMenu.Value
                    case 1
                        funcStr = strcat(funcStr, '@(z,neibs,oness)(exp(i * z))');
                    case 2
                        funcStr = strcat(funcStr, '@(z,neibs,oness)(z^2+mu)');
                    case 3
                        funcStr = strcat(funcStr, '@(z,neibs,oness)(1)');

                end

                switch handles.LambdaMenu.Value

                    case 1
                        funcStr = strcat(funcStr, '*mu0 + sum(neibs)');
                    case 2
                        funcStr = strcat(funcStr, '*mu + mu0*(abs(sum(neibs-eq)/(length(neibs))))');

                    case 3
                        funcStr = strcat(funcStr, '*mu + mu0*abs(sum(neibs.*oness))');

                    case 4
                        funcStr = strcat(funcStr, '*mu + mu0*(sum(neibs-eq)/(length(neibs)))');

                    case 5
                        funcStr = strcat(funcStr, '*(mu + mu0)');

                end

            else
                funcStr = strcat(funcStr, '@(z,neibs,oness)', handles.UsersBaseImagEdit.String);
            end

            obj.IteratedFuncStr = funcStr;

        end

        function errStruct = CheckIteratedFuncStr(obj, errStruct)

            funcParamsNames = keys(obj.FuncParams);
            funcParamsValues = values(obj.FuncParams);

            iteratedFuncStr = obj.IteratedFuncStr;
            testFuncStr = obj.IteratedFuncStr;
            obj.ConstIteratedFuncStr = obj.IteratedFuncStr;

            if ~isempty(regexp(testFuncStr, 'mui'))
                iteratedFuncStr = strrep(iteratedFuncStr, 'mui', strcat('(', num2str(obj.Weights(1)), ')'));
                testFuncStr = strrep(testFuncStr, 'mui', '(0)');
            end

            for index = 1:length(obj.FuncParams)

                if contains(iteratedFuncStr, funcParamsNames(index))

                    if (~isnan(funcParamsValues{index}))
                        iteratedFuncStr = regexprep(iteratedFuncStr, strcat(funcParamsNames(index), '(?!\d)'), strcat('(', num2str(funcParamsValues{index}), ')'));
                        testFuncStr = regexprep(testFuncStr, strcat(funcParamsNames(index), '(?!\d)'), '(0)');
                    else
                        errStruct.check = true;
                        errStruct.msg = strcat(errStruct.msg, funcParamsNames(index), '; ');
                    end

                end

            end

            if ~isempty(regexp(iteratedFuncStr, 'z[1-9]+'))

                neigborsStrs = regexp(iteratedFuncStr, 'z[1-9]+', 'match');
                neigborsIndxes = regexp(cell2mat(neigborsStrs), '[1-9]+', 'match');
                neigborsCount = max(str2double(neigborsIndxes));

                if neigborsCount > length(obj.Weights) - 1
                    errStruct.check = true;
                    errStruct.msg = strcat(errStruct.msg, {' „исло параметров соседей превышает количество €чеек в окрестности'}, '; ');
                end

                for k = 1:neigborsCount
                    testFuncStr = strrep(testFuncStr, strcat('z', num2str(k)), '(0)');
                end

            end

            if ~isempty(regexp(iteratedFuncStr, 'mu[1-9]+'))

                neigborsWeightsStrs = regexp(iteratedFuncStr, 'mu[1-9]+', 'match');
                neigborsWeightsIndxes = regexp(cell2mat(neigborsWeightsStrs), '[1-9]+', 'match');
                neigborsWeightsCount = max(str2double(neigborsWeightsIndxes));

                if neigborsWeightsCount >= length(obj.Weights)
                    errStruct.check = true;
                    errStruct.msg = strcat(errStruct.msg, {' „исло параметров соседей превышает количество €чеек в окрестности'}, '; ');
                else
                    weights = obj.Weights(2:end);
                    for k = 1:neigborsWeightsCount
                        iteratedFuncStr = strrep(iteratedFuncStr, strcat('mu', num2str(k)), strcat('(', num2str(weights(k)), ')'));
                        testFuncStr = strrep(testFuncStr, strcat('mu', num2str(k)), '(0)');
                    end

                end

            end

            if contains(testFuncStr, 'eq') && (~isempty(regexp(testFuncStr, 'exp\(\s*z\s*\*\s*i\s*)')) || ~isempty(regexp(testFuncStr, 'exp\(\s*i\s*\*\s*z\s*)')))

                zBase = IteratedPoint.calcZBase(obj.FuncParams('mu'));
                obj.FuncParams('z*') = zBase;

                iteratedFuncStr = regexprep(iteratedFuncStr, strcat('eq', '(?!\d)'), strcat('(', num2str(zBase), ')'));
                testFuncStr = regexprep(testFuncStr, strcat('eq', '(?!\d)'), '(0)');

            end

            if ~isempty(regexp(testFuncStr, 'nc'))
                testFuncStr = strrep(testFuncStr, 'nc', '(0)');
            end

            try

                testFunc = str2func(testFuncStr);

                if any([isnan(testFunc(0, 0, 0)), isinf(testFunc(0, 0, 0))])
                    warning(cell2mat(strcat({'Entered iterated function '}, {strrep(obj.IteratedFuncStr, '@(z,neibs,oness)', '')}, {' returns an NaN or Inf values in case of parameters equal to 0'})));
                end

                obj.IteratedFunc = str2func(iteratedFuncStr);

            catch
                errStruct.check = true;
                errStruct.msg = strcat(errStruct.msg, {' Ќеправильный формат итерированной функции; '});
            end

            obj.IteratedFuncStr = iteratedFuncStr;
        end

        function CreateCAField(obj, handles)

            arguments
                obj CellularAutomat
                handles struct
            end

            switch string(handles.FieldTypeGroup.UserData)
                case "HexFieldRB"
                    GenerateHexField(obj, handles)
                case "SquareFieldRB"
                    GenerateSquareField(obj, handles)
            end

            GetNeighboursFunc = @(caCell)GetNeighbours(obj.Neighborhood, caCell);
            obj.Cells = arrayfun(GetNeighboursFunc, obj.Cells);

        end

        function GenerateHexField(obj, handles)
            N = obj.N;
            cellsCount = (N * (N - 1) * 3) + 1;

            indexesMatr = [];

            for row = 0:2 * (N - 1)

                colsCount = (2 * N - 1) - abs(N-1-row);
                matrRow = zeros(colsCount, 2);
                matrRow(:, 1) = row;
                matrRow(:, 2) = 0:colsCount - 1;
                indexesMatr = cat(1, indexesMatr, matrRow);

            end

            indexesArrfunc = @(ind)({indexesMatr(ind, :)});
            indexesArr = arrayfun(indexesArrfunc, 1:cellsCount);

            CACellCreation = @(CAindexes)HexagonCACell(0, CAindexes, obj, handles.HexOrientationPanel.UserData);
            obj.Cells = arrayfun(CACellCreation, indexesArr);

            indRingCellsCount = zeros(1,N);
            for ind = 1:length(obj.Cells)
                obj.Cells(ind) = SetIsExternal(obj.Cells(ind));
                obj.Cells(ind) = RingNumSet(obj.Cells(ind));
            end
            
        end

        function GenerateSquareField(obj, handles)
            N = obj.N;
            cellsCount = N * N;

            indexesMatr = [];

            for row = 0:(N - 1)

                colsCount = N;
                matrRow = zeros(colsCount, 2);
                matrRow(:, 1) = row;
                matrRow(:, 2) = 0:colsCount - 1;
                indexesMatr = cat(1, indexesMatr, matrRow);

            end

            indexesArrfunc = @(ind)({indexesMatr(ind, :)});
            indexesArr = arrayfun(indexesArrfunc, 1:cellsCount);

            CACellCreation = @(CAindexes)SquareCACell(0, CAindexes, obj, handles.HexOrientationPanel.UserData);
            obj.Cells = arrayfun(CACellCreation, indexesArr);
        end

        function errStruct = CellsInitialization(obj, handles, errStruct)

            if handles.Z0SourcePathEdit.UserData
                errStruct = InitCellsWithFile(obj, handles, errStruct);
            else
                errStruct = InitCellsWithRandRange(obj, handles, errStruct);
                handles.Z0SourcePathEdit.String
            end

        end

        function errStruct = InitCellsWithRandRange(obj, handles, errStruct)

            aParam = (handles.DistributStartEdit.String);
            bParam = (handles.DistributStepEdit.String);
            cParam = (handles.DistributEndEdit.String);
            z0 = (handles.z0Edit.String);

            if isempty(aParam) || isempty(bParam) || isempty(cParam)
                errStruct.check = true;
                regexprep(errStruct.msg, ', $', '. ');
                errStruct.msg = strcat(errStruct.msg, ' Ќе задана начальна€ конфигураци€: неправильный формат параметров диапазона значений Z0 или точки z0; ');
                return;
            end

            switch handles.DistributionTypeMenu.Value
                case {1, 2}

                    if (isnan(str2num(aParam)) || isinf(str2num(aParam)) || isnan(str2num(bParam)) || isinf(str2num(bParam)) || isnan(str2num(cParam)) || isinf(str2num(cParam)))
                        errStruct.check = true;
                        regexprep(errStruct.msg, ', $', '. ');
                        errStruct.msg = strcat(errStruct.msg, ' Ќе задана начальна€ конфигураци€: неправильный формат параметров равномерного случайного диапазона значений Z0 или точки z0; ');
                    end

                case 3

                    if (str2double(aParam) >= str2double(bParam) || isempty(regexp(aParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(bParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(cParam, '^\d+(\.?)(?(1)\d+|)$')))
                        errStruct.check = true;
                        regexprep(errStruct.msg, ', $', '. ');
                        errStruct.msg = strcat(errStruct.msg, ' Ќе задана начальна€ конфигураци€: неправильный формат параметров случайного однородного диапазона значений Z0 или точки z0; ');
                    end

                case 4

                    if (str2double(bParam) <= 0 || isempty(regexp(aParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(bParam, '^\d+(\.?)(?(1)\d+|)$')) || isempty(regexp(cParam, '^\d+(\.?)(?(1)\d+|)$')))
                        errStruct.check = true;
                        regexprep(errStruct.msg, ', $', '. ');
                        errStruct.msg = strcat(errStruct.msg, ' Ќе задана начальна€ конфигураци€: неправильный формат параметров случайного нормального диапазона значений Z0 или точки z0; ');
                    end

            end

            if ~errStruct.check
                GenerateRandInitCellsVals(obj, str2double(aParam), str2double(bParam), str2double(cParam), str2double(z0), handles.DistributionTypeMenu.Value)
            end

        end

        function GenerateRandInitCellsVals(obj, a, b, c, z0, DistributType)

            cellsInxs = arrayfun(@(caCell)caCell.CAIndexes, obj.Cells, 'UniformOutput', false);
            cellCount = length(cellsInxs);
            n = obj.N;

            switch DistributType
                case 1
                    valuesArr = arrayfun(@(cellInxs) z0+a+b*cellInxs{1}(2)+c*cellInxs{1}(1), cellsInxs)';
                case 2
                    if string(class(obj.Cells(1))) == "HexagonCACell"
                        Ns = zeros(1,length(obj.Cells));
                        Ns(:) = n;
                        diffArr = arrayfun(@(CAcell,n) abs(CAcell.HexRingNum - n - 1), obj.Cells, Ns);
                        valuesArr = arrayfun(@(cellInxs, dif) z0 + a + dif*(c + b), cellsInxs, diffArr)';
                    else
                        dif = (n - 1) / 2;
                        valuesArr = arrayfun(@(cellInxs) z0 + a + b * abs(cellInxs{1}(1) - dif) + c * abs(cellInxs{1}(2) - dif), cellsInxs)';
                    end
                case 3
                    p1Arr = rand(cellCount, 1);
                    p2Arr = rand(cellCount, 1);

                    valuesArr = (z0 + a + (b - a) * p1Arr + 1i * c * (a + ((b - a) * p2Arr)))';
                case 4
                    p1Arr = arrayfun(@(cellInxs) 1/(b * sqrt(2 * pi))*exp(-(cellInxs{1}(1) - a)^2 / (2 * b^2)), cellsInxs);
                    p2Arr = arrayfun(@(cellInxs) 1/(b * sqrt(2 * pi))*exp(-(cellInxs{1}(1) - a)^2 / (2 * b^2)), cellsInxs);

                    valuesArr = arrayfun(@(p1, p2) z0+c*(p1 + 1i * p2), p1Arr, p2Arr)';
            end

            for ind = 1:length(obj.Cells)
                obj.Cells(ind).z0 = valuesArr(ind);
                obj.Cells(ind).ZPath = valuesArr(ind);
            end

        end

        function errStruct = InitCellsWithFile(obj, handles, errStruct)
            cellCount = length(obj.Cells);
            z0Arr = [];
            filePath = handles.Z0SourcePathEdit.String;

            try
                if ~isempty(regexp(filePath, '\.txt$'))
                    z0Size = [2, cellCount];
                    formatSpec = '%f %f\n';

                    file = fopen(filePath, 'r');
                    z0Arr = fscanf(file, formatSpec, z0Size);
                    fclose(file);

                end
                if ~isempty(regexp(filePath, '\.xlsx$')) || ~isempty(regexp(filePath, '\.xls$'))

                    z0Arr = xlsread(filePath, 1)';

                end

                if length(z0Arr(1, :)) < cellCount
                    i_love_MATLAB^2;
                end

                for ind = 1:cellCount
                    obj.Cells(ind).z0 = z0Arr(1, ind) + z0Arr(2, ind) * 1i;
                    obj.Cells(ind).ZPath = z0Arr(1, ind) + z0Arr(2, ind) * 1i;
                end
            catch
                errStruct.check = true;
                regexprep(errStruct.msg, ', $', '. ');
                errStruct.msg = strcat(errStruct.msg, ' Ќеверна€ структура файла с начальной конфигурацией  ј; ');
            end
        end

        function obj = Iteration(obj, calcParams)
            cellsCount = length(obj.Cells);
            persistent PrecisionParms;

            if isempty(PrecisionParms)
                PrecisionParms = [calcParams.InfVal, calcParams.EqualityVal];
            end

            func = @(caCell)UpdateCellNeighborsValues(obj, caCell);
            obj.Cells = arrayfun(func, obj.Cells);

            for ind = 1:cellsCount

                if all([length(obj.Cells(ind).CurrNeighbors) > 0, abs(obj.Cells(ind).ZPath(end)) < PrecisionParms(1)])
                    neibs = arrayfun(@(neib)neib.ZPath(end), obj.Cells(ind).CurrNeighbors);
                    oness = ones(1, length(obj.Cells(ind).CurrNeighbors));
                    oness(1:2:length(oness)) = -1;

                    func = CreateIteratedFuncForCell(obj, obj.Cells(ind));

                    obj.Cells(ind).ZPath = [obj.Cells(ind).ZPath, func(obj.Cells(ind).ZPath(end), neibs, oness)];

                    if ~(abs(obj.Cells(ind).ZPath(end) - obj.Cells(ind).ZPath(end -1)) < PrecisionParms(2))
                        obj.Cells(ind).Step = obj.Cells(ind).Step + 1;
                    end
                else
                    obj.Cells(ind).ZPath = [obj.Cells(ind).ZPath, obj.Cells(ind).ZPath(end)];
                end

            end

        end

        function NewCell = UpdateCellNeighborsValues(ca, caCell)

            if ~isempty(caCell.CurrNeighbors)

                neighborsIndxsMatr = [];

                for k = 1:length(caCell.CurrNeighbors)
                    neighborsIndxsMatr = [neighborsIndxsMatr; caCell.CurrNeighbors(k).CAIndexes];
                end

                caCell.CurrNeighbors = ca.Cells(find(arrayfun(@(neib) any(ismember(neib.CAIndexes == neighborsIndxsMatr, [1, 1], 'rows')), ca.Cells)));

            end

            NewCell = caCell;
        end

        function iteratedFunc = CreateIteratedFuncForCell(obj, CACell)

            iteratedFuncStr = obj.IteratedFuncStr;

            for k = 1:length(CACell.CurrNeighbors)
                iteratedFuncStr = strrep(iteratedFuncStr, strcat('z', num2str(k)), strcat('(', num2str(CACell.CurrNeighbors(k).ZPath(end)), ')'));
            end

            neiborsNotFound = regexp(iteratedFuncStr, 'z[1-9]+', 'match');

            if ~isempty(neiborsNotFound)
                iteratedFuncStr = regexprep(iteratedFuncStr, 'z[1-9]+', '(0)');
                warningStr = '';

                for k = 1:length(neiborsNotFound)
                    warningStr = strcat(warningStr, char(neiborsNotFound(k)), ';');
                end

                warningStr = regexprep(warningStr, ';$', '');
                warning(strcat(' cell with indexes', strcat(' ', num2str(CACell.CAIndexes), ' '), 'do not contains neighbors with values', strcat(' ', warningStr, ' '), 'which are declared in the iterated function'));
            end

            iteratedFuncStr = strrep(iteratedFuncStr, 'nc', strcat('(', num2str(length(CACell.CurrNeighbors)), ')'));

            iteratedFunc = str2func(iteratedFuncStr);

        end

        function check = IsContinue(obj)
            PrecisionParms = ModelingParams.GetSetPrecisionParms;

            func = @(caCell) isinf(caCell.ZPath(end)) || isnan(caCell.ZPath(end)) || abs(caCell.ZPath(end)) >= PrecisionParms(1);
            check = ~any(arrayfun(func, obj.Cells));
        end

        function [status] = GetModellingStatus(obj)
            status = IsContinue(obj);
        end

    end

    methods (Static)
        % метод get-set дл€ статических массива весов
        function [Weights] = GetSetWeights(weights)
            persistent weight_s;

            if nargin
                weight_s = weights;
            end

            Weights = weight_s;
        end
    end

end
