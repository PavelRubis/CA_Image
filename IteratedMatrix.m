classdef IteratedMatrix < IIteratedObject

    properties
        IteratedFunc
        IteratedFuncStr
        ConstIteratedFuncStr (1, :) char
        FuncParams

        PointsFates
        PointsSteps

        WindowOfValues
        WindowParam struct
        IsIteratableWindowParam logical = false

    end

    methods

        function [obj] = IteratedMatrix()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];

        end

        function [obj] = Initialization(obj, handles)

            errStruct.check = false;
            errStruct.msg = 'Ошибки в текстовых полях параметров: ';
            setappdata(handles.output, 'errStruct', errStruct);

            [obj errStruct] = SetFuncParams(obj, handles, errStruct);
            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
                return
            end
            [obj errStruct] = SetWindowOfValues(obj, handles, errStruct);
            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
                return
            end

            obj = IteratedPoint.GetIteratedFuncStr(obj, handles);
            obj.ConstIteratedFuncStr = obj.IteratedFuncStr;
            
            [obj, errStruct] = CreateIteratedFunc(obj, errStruct);

            if errStruct.check
                obj = [];
                setappdata(handles.output, 'errStruct', errStruct);
            end

        end

        function obj = Iteration(obj, calcParams, wb)
            windowOfValues = obj.WindowOfValues{1} + 1i * obj.WindowOfValues{2};
            len = size(windowOfValues);
            pointsCount = numel(windowOfValues);

            obj.PointsFates = zeros(len);
            obj.PointsSteps = zeros(len);
            pointsFates = obj.PointsFates;
            pointsSteps = obj.PointsSteps;

            IteratedMatrix.parforWaitbar(wb, pointsCount);
            DQ = parallel.pool.DataQueue;
            afterEach(DQ, @IteratedMatrix.parforWaitbar);

            wbStep = ceil(pointsCount / 20);

            if obj.IsIteratableWindowParam
                obj.FuncParams('z*') = IteratedMatrix.CountZBaze(str2double(obj.FuncParams('mu')), obj.WindowParam.Value);
                obj.IteratedFuncStr = strrep(obj.IteratedFuncStr, 'eq', strcat('(', num2str(IteratedMatrix.CountZBaze(str2double(obj.FuncParams('mu')), obj.WindowParam.Value)), ')'));
                obj.IteratedFunc = str2func(obj.IteratedFuncStr);

                parfor ind = 1:pointsCount
                    [pointsStep, pointsFate] = IterableWindowParamCalc(obj, windowOfValues(ind), calcParams);

                    pointsSteps(ind) = pointsStep;
                    pointsFates(ind) = pointsFate;

                    if mod(ind, wbStep) == 0
                        send(DQ, []);
                    end

                end

            else
                initVal = str2double(obj.FuncParams('z0'));
                z_eq = zeros(len);

                if string(obj.WindowParam.Name) == "mu"

                    parfor ind = 1:pointsCount
                        eq_ind = IteratedMatrix.CountZBaze(windowOfValues(ind), initVal);
                        z_eq(ind) = eq_ind;
                    end

                else
                    obj.FuncParams('z*') = IteratedMatrix.CountZBaze(str2double(obj.FuncParams('mu')), initVal);
                    z_eq(:) = IteratedMatrix.CountZBaze(str2double(obj.FuncParams('mu')), initVal);
                end

                obj.IteratedFunc = str2func(obj.IteratedFuncStr);

                parfor ind = 1:pointsCount
                    [pointsStep, pointsFate] = NonIterableWindowParamCalc(obj, initVal, windowOfValues(ind), z_eq(ind), calcParams);

                    pointsSteps(ind) = pointsStep;
                    pointsFates(ind) = pointsFate;
                    
                    if mod(ind, wbStep) == 0
                        send(DQ, []);
                    end
                    
                end

            end

            obj.PointsFates = pointsFates;
            obj.PointsSteps = pointsSteps;
            delete(wb);
        end

        function [status] = GetModellingStatus(obj)
            status = true;
        end

        function [step, fate] = IterableWindowParamCalc(obj, initVal, calcParams)

            itersCount = calcParams.IterCount;
            infVal = calcParams.InfVal;
            equalityVal = calcParams.EqualityVal;
            iteratedFunc = obj.IteratedFunc;

            pointPath = nan(1, itersCount);
            pointPath(1) = initVal;
            pointVal2ItersBack = inf;

            for ind = 2:itersCount + 1

                if abs(pointPath(ind - 1)) >= infVal || abs(pointPath(ind - 1) - pointVal2ItersBack) < equalityVal
                    break;
                else
                    pointPath(ind) = iteratedFunc(pointPath(ind - 1));
                    pointVal2ItersBack = pointPath(ind - 1);
                end

            end

            [fate, step] = IteratedMatrix.CheckFate(pointPath, calcParams);

        end

        function [step, fate] = NonIterableWindowParamCalc(obj, initVal, windowParamVal, z_eq, calcParams)

            itersCount = calcParams.IterCount;
            infVal = calcParams.InfVal;
            equalityVal = calcParams.EqualityVal;
            iteratedFunc = obj.IteratedFunc;

            pointPath = nan(1, itersCount);
            pointPath(1) = initVal;
            pointVal2ItersBack = inf;

            for step = 2:itersCount + 1

                if abs(pointPath(step - 1)) >= infVal || abs(pointPath(step - 1) - pointVal2ItersBack) < equalityVal
                    break;
                else
                    pointPath(step) = iteratedFunc(pointPath(step - 1), windowParamVal, z_eq);
                    pointVal2ItersBack = pointPath(step - 1);
                end

            end

            [fate, step] = IteratedMatrix.CheckFate(pointPath, calcParams);

        end

        function [obj errStruct] = SetFuncParams(obj, handles, errStruct)

            probalyParamsNames = {'z0', 'mu0', 'mu'};
            probalyParamsValues = [];

            if (~isempty(regexp(handles.z0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues {handles.z0Edit.String}];

            else
                probalyParamsValues = [probalyParamsValues {'nan'}];
            end

            if (~isempty(regexp(handles.Miu0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues {handles.Miu0Edit.String}];

            else
                probalyParamsValues = [probalyParamsValues {'nan'}];
            end

            if (~isempty(regexp(handles.MiuEdit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues {handles.MiuEdit.String}];

            else
                probalyParamsValues = [probalyParamsValues {'nan'}];
            end

            obj.FuncParams = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for ind = 1:length(probalyParamsNames)

                if ~isnan(str2double(probalyParamsValues{ind}))
                    obj.FuncParams(probalyParamsNames{ind}) = probalyParamsValues{ind};
                else
                    errStruct.check = true;
                    errStruct.msg = strcat(errStruct.msg, probalyParamsNames{ind}, ' ;');
                end

            end
            
            if errStruct.check
                return;
            end

            obj.WindowParam = struct;

            switch handles.ParamNameMenu.Value
                case 1
                    obj.WindowParam.Name = 'z0';
                case 2
                    obj.WindowParam.Name = 'mu';
                case 3
                    obj.WindowParam.Name = 'mu0';
            end

            obj.WindowParam.Value = obj.FuncParams(obj.WindowParam.Name);

            if (string(obj.WindowParam.Name) == "z0")
                obj.IsIteratableWindowParam = true;
            end

        end

        function [obj errStruct] = SetWindowOfValues(obj, handles, errStruct)

            if isempty(regexp(handles.ParamReDeltaEdit.String, '^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamImDeltaEdit.String, '^\d+(?<dot>\.?)(?(dot)\d+|)$')) || isempty(regexp(handles.ParamRePointsEdit.String, '^\d+$')) || isempty(regexp(handles.ParamImPointsEdit.String, '^\d+$'))
                errStruct.check = true;
                errStruct.msg = strcat(errStruct.msg, ' Неправильный формат диапазона параметра "окна"; ');
                return;
            end

            if (~isnan(obj.WindowParam.Value))
                ReDelta = str2double(handles.ParamReDeltaEdit.String);
                ImDelta = str2double(handles.ParamImDeltaEdit.String);
                ReStep = ReDelta / str2double(handles.ParamRePointsEdit.String);
                ImStep = ImDelta / str2double(handles.ParamImPointsEdit.String);
                ReCenter = real(str2double(obj.WindowParam.Value));
                ImCenter = imag(str2double(obj.WindowParam.Value));

                [X, Y] = meshgrid((ReCenter - ReDelta):ReStep:(ReCenter + ReDelta), (ImCenter - ImDelta):ImStep:(ImCenter + ImDelta));
                obj.WindowOfValues = [{X}, {Y}];
            end

        end

        function [obj, errStruct] = CreateIteratedFunc(obj, errStruct)

            funcParamsNames = keys(obj.FuncParams);
            funcParamsValues = values(obj.FuncParams);

            testFuncStr = obj.IteratedFuncStr;

            for index = 1:length(obj.FuncParams)

                if string(funcParamsNames(index)) ~= "z0"

                    if string(funcParamsNames(index)) ~= string(obj.WindowParam.Name)
                        obj.IteratedFuncStr = regexprep(obj.IteratedFuncStr, strcat(funcParamsNames(index), '(?!\d)'), strcat('(', num2str(funcParamsValues{index}), ')'));
                    end

                    testFuncStr = regexprep(testFuncStr, strcat(funcParamsNames(index), '(?!\d)'), '(0)');
                end

            end

            testFuncStr = strrep(testFuncStr, 'eq', '(0)');

            try

                testFunc = str2func(testFuncStr);

                if any([isnan(testFunc(0)) isinf(testFunc(0))])
                    warning(cell2mat(strcat({'Entered iterated function '}, {strrep(obj.IteratedFuncStr, '@(z)', '')}, {' returns an NaN or Inf values in case of parameters equal to 0'})));
                end

            catch
                errStruct.check = true;
                errStruct.msg = strcat(errStruct.msg, ' Неправильный формат итерируемой функции; ');
                return;
            end

            if ~obj.IsIteratableWindowParam
                obj.IteratedFuncStr = strrep(obj.IteratedFuncStr, '@(z', strcat('@(z', ',', obj.WindowParam.Name));
                paramsSubStr = obj.IteratedFuncStr(1:find(obj.IteratedFuncStr == ')', 1, 'first'));
                newParamsSubStr = paramsSubStr(1:end - 1);
                newParamsSubStr = strcat(newParamsSubStr, ',eq)');
                obj.IteratedFuncStr = strrep(obj.IteratedFuncStr, paramsSubStr, newParamsSubStr);
            end

        end

    end

    methods (Static)

        function [z_eq] = CountZBaze(miu, z0)

            persistent funcStr
            persistent func

            if isempty(funcStr)
                funcStr = strcat('@(z)(', num2str(miu), ')* exp(i * z)');
                func = str2func(funcStr);
            end

            Fbase = func;

            mapz_zero = @(z) abs(Fbase(z) - z);
            mapz_zero_xy = @(z) mapz_zero(z(1) + i * z(2));
            [zeq, zer] = fminsearch(mapz_zero_xy, [real(z0) imag(z0)], optimset('TolX', 1e-9));
            z_eq = complex(zeq(1), zeq(2));
        end

        function [Fate, Step] = CheckFate(pointPath, calcParams)

            MaxPeriod = calcParams.MaxPeriod;
            pointPath = pointPath(find(~isnan(pointPath)));

            %уход в бесконечность
            if (abs(pointPath(end)) > calcParams.InfVal) || isnan(pointPath(end)) || isinf(pointPath(end))
                Step = length(pointPath);
                Fate = 0;
                return;
            end
            
            %сходимость
            c = 3:length(pointPath);
            converg = abs(pointPath(c - 1) - pointPath(c)) <= calcParams.EqualityVal;

            if any(converg)
                Step = c(find(converg, 1, 'first'));
                Fate = 1;
                return;
            end

            Q = 10;
            %период и мб сходимость
            for n = 2:length(pointPath)

                q = min(n, MaxPeriod);
                qArr = 1:q - 1;
                r = abs(pointPath(n - qArr) - pointPath(n));

                [r_min, s_min] = min(r);
                if r_min < calcParams.EqualityVal && s_min == 1
                    Step = n - 1;
                    Fate = 1;
                    return;
                end

                if r_min < calcParams.EqualityVal
                    r_max = max(r(1:s_min));
                    if  r_max / r_min > Q
                        Step = n;
                        Fate = s_min;
                        return;
                    else
                        Step = n - 1;
                        Fate = 1;
                        return;
                    end
                end

            end

            Step = length(pointPath);
            Fate = Inf;
        end

        function parforWaitbar(waitbarHandle, iterations)
            persistent count h N;

            if ~isempty(waitbarHandle)
                count = 0;
                h = waitbarHandle;
                N = iterations;
            else
                count = count + ceil(N / 20);
                waitbar(count / N, h, 'Выполняется расчет...', 'WindowStyle', 'modal');
            end

        end

    end

end
