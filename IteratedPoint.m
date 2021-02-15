classdef IteratedPoint < IIteratedObject

    properties
        IteratedFunc%function_handle;
        IteratedFuncStr%(1, :) char;
        InitState double = nan;
        StatePath (1, :) double;
        FuncParams%containers.Map;
        Fate double;
        LastIterNum double {mustBePositive, mustBeInteger};

        Step double {mustBePositive, mustBeInteger};
    end

    methods

        function [obj] = IteratedPoint()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];
            obj.InitState = nan;

        end

        function [obj] = Initialization(obj, handles)

            arguments
                obj IteratedPoint
                handles struct
            end

            obj = SetInitValueAndFuncParams(obj, handles);
            obj = GetIteratedFuncStr(obj, handles);
            [obj, errorStr] = CreateIteratedFunc(obj, handles);

            if isempty(obj)
                errordlg(errorStr, 'Ошибки ввода')
            end

        end

        function [obj] = SetInitValueAndFuncParams(obj, handles)

            probalyParamsNames = {'z0', 'mu0', 'mu'};
            probalyParamsValues = [];

            if (~isempty(regexp(handles.z0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.z0Edit.String)];

                obj.InitState = str2double(handles.z0Edit.String);
                obj.StatePath = obj.InitState;

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            if (~isempty(regexp(handles.Miu0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.Miu0Edit.String)];

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            if (~isempty(regexp(handles.MiuEdit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.MiuEdit.String)];

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            obj.FuncParams = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for ind = 1:length(probalyParamsNames)
                obj.FuncParams(probalyParamsNames{ind}) = probalyParamsValues(ind);
            end

        end

        function [obj] = GetIteratedFuncStr(obj, handles)

            funcStr = '';

            if ~handles.CustomIterFuncCB.Value

                switch handles.BaseImagMenu.Value
                    case 1
                        funcStr = strcat(funcStr, '@(z)(exp(i * z))');
                    case 2
                        funcStr = strcat(funcStr, '@(z)(z^2+mu)');
                    case 3
                        funcStr = strcat(funcStr, '@(z)(1)');

                end

                switch handles.LambdaMenu.Value

                    case 1
                        funcStr = strcat(funcStr, '*(mu+z)');
                    case 2
                        funcStr = strcat(funcStr, '*(mu+(mu0*abs(z-(eq))))');

                    case 3
                        funcStr = strcat(funcStr, '*(mu+(mu0*abs(z)))');

                    case 4
                        funcStr = strcat(funcStr, '*(mu+(mu0*(z-(eq))))');

                    case 5
                        funcStr = strcat(funcStr, '*(mu+mu0)');

                end

            else
                funcStr = strcat(funcStr, '@(z)', handles.UsersBaseImagEdit.String);
            end

            obj.IteratedFuncStr = funcStr;

        end

        function [obj, errorStr] = CreateIteratedFunc(obj, handles)

            errorCheck = false;

            errorStr = 'Ошибки в текстовых полях параметров: ';

            funcParamsNames = keys(obj.FuncParams);
            funcParamsValues = values(obj.FuncParams);

            if (isnan(funcParamsValues{1}))
                errorCheck = true;
                errorStr = strcat(errorStr, ' начальное значение точки z; ');
            end

            iteratedFuncStr = obj.IteratedFuncStr;
            testFuncStr = obj.IteratedFuncStr;

            for index = 1:length(obj.FuncParams)

                if contains(iteratedFuncStr, funcParamsNames(index))

                    if (~isnan(funcParamsValues{index}))
                        iteratedFuncStr = regexprep(iteratedFuncStr, strcat(funcParamsNames(index), '(?!\d)'), strcat('(', num2str(funcParamsValues{index}), ')'));
                        testFuncStr = regexprep(testFuncStr, strcat(funcParamsNames(index), '(?!\d)'), '(0)');
                    else
                        errorCheck = true;
                        errorStr = strcat(errorStr, funcParamsNames(index), '; ');
                    end

                end

            end

            if contains(testFuncStr, 'eq')

                zBase = IteratedPoint.calcZBase(obj.FuncParams('mu'));
                obj.FuncParams('z*') = zBase;

                iteratedFuncStr = regexprep(iteratedFuncStr, strcat('eq', '(?!\d)'), strcat('(', num2str(zBase), ')'));
                testFuncStr = regexprep(testFuncStr, strcat('eq', '(?!\d)'), '(0)');

            end

            try

                testFunc = str2func(testFuncStr);

                if any([isnan(testFunc(0)) isinf(testFunc(0))])
                    warning(cell2mat(strcat({'Entered iterated function '}, {strrep(obj.IteratedFuncStr, '@(z)', '')}, {' returns an NaN or Inf values in case of parameters equal to 0'})));
                end

                obj.IteratedFunc = str2func(iteratedFuncStr);

            catch
                errorCheck = true;
                errorStr = strcat(errorStr, ' Неправильный формат итерируемой функции; ');
            end

            if errorCheck
                obj = [];
            end

        end

        function [obj] = BeforeModeling(obj)

            arguments
                obj IteratedPoint
            end

            obj.Step = length(obj.StatePath) + 1;
            obj.StatePath = [obj.StatePath nan(1, ModelingParamsForPath.GetIterCount)];
        end

        function [obj] = AfterModeling(obj, handles)

            arguments
                obj IteratedPoint
                handles struct
            end

            GUIControlsOptions.GetSetUIControls(handles);
            GUIControlsOptions.SetIteratedPointVisualMenu();

        end

        function [obj] = Iteration(obj)

            arguments
                obj IteratedPoint
            end

            obj.StatePath(obj.Step) = obj.IteratedFunc(obj.StatePath(obj.Step - 1));
            obj.Step = obj.Step + 1;
            [obj] = CheckConvergence(obj);
        end

        function [obj] = CheckConvergence(obj)

            arguments
                obj IteratedPoint
            end

            PrecisionParms = ModelingParamsForPath.GetSetPrecisionParms;
            MaxPeriod = ModelingParamsForPath.GetSetMaxPeriod;

            pointPath = obj.StatePath(find(~isnan(obj.StatePath)));

            %уход в бесконечность
            if (log(pointPath(end)) / log(10) > PrecisionParms(1)) || isnan(pointPath(end)) || isinf(pointPath(end))
                obj.LastIterNum = length(pointPath);
                obj.Fate = 0;
                return;
            end

            %сходимость
            c = 3:length(pointPath);
            converg = abs(pointPath(c - 1) - pointPath(c)) <= PrecisionParms(2);

            if any(converg)
                obj.LastIterNum = c(find(converg, 1, 'first'));
                obj.Fate = 1;
                return;
            end

            %период и мб сходимость
            for n = 2:length(pointPath)

                q = min(n, MaxPeriod);
                qArr = 1:q - 1;
                r = abs(pointPath(n - qArr) - pointPath(n));

                if r(1) < PrecisionParms(2) || norm(r) < 2 * q * PrecisionParms(2)
                    obj.LastIterNum = n - 1;
                    obj.Fate = 1;
                    return;
                else
                    [minR prd] = min(r);

                    if minR < PrecisionParms(2)
                        obj.LastIterNum = n - prd;
                        obj.Fate = prd;
                        return;
                    end

                end

            end

            obj.LastIterNum = length(pointPath);
            obj.Fate = Inf;
        end

        function check = IsContinue(obj)
            check = obj.Fate == Inf;
        end

    end

    methods (Static)

        function zBase = calcZBase(mu)

            MiuStr = strcat('(', num2str(mu), ')');

            FbaseStr = '@(z)mu*(exp(i*z))';
            FbaseStr = strrep(FbaseStr, 'mu', MiuStr);

            Fbase = str2func(FbaseStr);

            mapz_zero = @(z) abs(Fbase(z) - z);
            z0 = -3.5 + 0.5 * i;
            mapz_zero_xy = @(z) mapz_zero(z(1) + i * z(2));
            [zeq, zer] = fminsearch(mapz_zero_xy, [real(z0) imag(z0)], optimset('TolX', 1e-9));

            zBase = complex(zeq(1), zeq(2));
        end

        function zBase = VisualPointCallBack(handles)
            obj = getappdata(handles.output, 'IIteratedObject');
            visOptions = PointPathVisualisationOptions.GetSetPointPathVisualisationOptions;

            if ~isempty(handles.CAField.Children)
                FormatAndPlotPath(visOptions, obj, handles);
            end

        end

    end

end
