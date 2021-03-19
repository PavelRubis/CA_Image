classdef IteratedMatrix < IIteratedObject

    properties
        IteratedFunc
        IteratedFuncStr
        ConstIteratedFuncStr
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

            [obj errStruct] = SetFuncParams(obj, handles, errStruct);
            [obj errStruct] = SetWindowOfValues(obj, handles, errStruct);
            obj = IteratedPoint.GetIteratedFuncStr(obj, handles);
            obj.ConstIteratedFuncStr = obj.IteratedFuncStr;
            [obj, errStruct] = CreateIteratedFunc(obj, errStruct);

            if errStruct.check
                obj = [];
            end

        end

        function obj = Iteration(obj, calcParams)
            windowOfValues = obj.WindowOfValues{1} + 1i * obj.WindowOfValues{2};
            len = size(windowOfValues);
            pointsCount = numel(windowOfValues);

            obj.PointsFates = zeros(len);
            obj.PointsSteps = zeros(len);
            pointsFates = obj.PointsFates;
            pointsSteps = obj.PointsSteps;

            if obj.IsIteratableWindowParam
                obj.IteratedFuncStr = strrep(obj.IteratedFuncStr, 'eq', strcat('(', num2str(IteratedMatrix.CountZBaze(obj.FuncParams('mu'), obj.WindowParam.Value)), ')'));
                obj.IteratedFunc = str2func(obj.IteratedFuncStr);

                parfor ind = 1:pointsCount
                    [pointsStep, pointsFate] = IterableWindowParamCalc(obj, windowOfValues(ind), calcParams);
                    pointsSteps(ind) = pointsStep;
                    pointsFates(ind) = pointsFate;
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
                    z_eq(:) = IteratedMatrix.CountZBaze(obj.FuncParams('mu'), obj.FuncParams('z0'));
                end

                obj.IteratedFunc = str2func(obj.IteratedFuncStr);

                parfor ind = 1:pointsCount
                    [pointsStep, pointsFate] = NonIterableWindowParamCalc(obj, initVal, windowOfValues(ind), z_eq(ind), calcParams);
                    pointsSteps(ind) = pointsStep;
                    pointsFates(ind) = pointsFate;
                end

            end

            obj.PointsFates = pointsFates;
            obj.PointsSteps = pointsSteps;
        end

        function [step, fate] = IterableWindowParamCalc(obj, initVal, calcParams)

            itersCount = calcParams.IterCount;
            pointPath = nan(1, itersCount);
            pointPath(1) = initVal;
            pointVal2ItersBack = inf;

            for step = 2:itersCount + 1

                if log(pointPath(step - 1)) / (2.302585092994046) >= calcParams.InfVal || abs(pointPath(step - 1) - pointVal2ItersBack) < calcParams.EqualityVal
                    break;
                else
                    pointPath(step) = obj.IteratedFunc(pointPath(step - 1));
                    pointVal2ItersBack = pointPath(step - 1);
                end

            end

            fate = IteratedMatrix.CheckFate(pointPath, calcParams);

        end

        function [step, fate] = NonIterableWindowParamCalc(obj, initVal, windowParamVal, z_eq, calcParams)

            itersCount = calcParams.IterCount;
            pointPath = nan(1, itersCount);
            pointPath(1) = initVal;
            pointVal2ItersBack = inf;

            for step = 2:itersCount + 1

                if log(pointPath(step - 1)) / (2.302585092994046) >= calcParams.InfVal || abs(pointPath(step - 1) - pointVal2ItersBack) < calcParams.EqualityVal
                    break;
                else
                    pointPath(step) = obj.IteratedFunc(pointPath(step - 1), windowParamVal, z_eq);
                    pointVal2ItersBack = pointPath(step - 1);
                end

            end

            fate = IteratedMatrix.CheckFate(pointPath, calcParams);

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
                    strcat(errStruct.msg, probalyParamsNames{ind}, ' ;');
                end

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
                ReStep = (ReDelta * 2) / str2double(handles.ParamRePointsEdit.String);
                ImStep = (ImDelta * 2) / str2double(handles.ParamImPointsEdit.String);
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

        function [Fate] = CheckFate(pointPath, calcParams)

            MaxPeriod = calcParams.MaxPeriod;
            pointPath = pointPath(find(~isnan(pointPath)));

            %уход в бесконечность
            if (log(pointPath(end)) / log(10) > calcParams.InfVal) || isnan(pointPath(end)) || isinf(pointPath(end))
                Fate = 0;
                return;
            end

            %сходимость
            c = 3:length(pointPath);
            converg = abs(pointPath(c - 1) - pointPath(c)) <= calcParams.EqualityVal;

            if any(converg)
                Fate = 1;
                return;
            end

            %период и мб сходимость
            for n = 2:length(pointPath)

                q = min(n, MaxPeriod);
                qArr = 1:q - 1;
                r = abs(pointPath(n - qArr) - pointPath(n));

                if r(1) < calcParams.EqualityVal || norm(r) < 2 * q * calcParams.EqualityVal
                    Fate = 1;
                    return;
                else
                    [minR prd] = min(r);

                    if minR < calcParams.EqualityVal
                        Fate = prd;
                        return;
                    end

                end

            end

            Fate = Inf;
        end

    end

end
