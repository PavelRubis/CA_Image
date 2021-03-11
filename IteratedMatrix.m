classdef IteratedMatrix < IIteratedObject

    properties
        IteratedFunc
        IteratedFuncStr
        FuncParams

        PointsWindow (:, :) IteratedPoint
        WindowOfValues (:, :) double
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

            arguments
                obj IteratedPoint
                handles struct
            end

            errStruct.check = false;
            errStruct.msg = 'Ошибки в текстовых полях параметров: ';

            [obj errStruct] = SetFuncParams(obj, handles, errStruct);
            [obj errStruct] = SetWindowOfValues(obj, handles, errStruct);
            obj = IteratedPoint.GetIteratedFuncStr(obj, handles);
            [obj, errStruct] = CheckIteratedFunc(obj, errStruct);

            if ~errStruct.check
                obj = CreatePointsWindow(obj);
            else
                obj = [];
            end

        end

        function obj = CreatePointsWindow(obj)

            if obj.IsIteratableWindowParam
                obj.PointsWindow = arrayfun(@(initVal, windowParamVal) CreatePoint(obj, initVal, windowParamVal), obj.WindowOfValues, obj.WindowOfValues, 'UniformOutput', false);
            else
                obj.PointsWindow = arrayfun(@(windowParamVal) CreatePoint(obj, obj.FuncParams('z0'), windowParamVal), obj.WindowOfValues, 'UniformOutput', false);
            end

        end

        function point = CreatePoint(obj, initVal, windowParamValue)

            point = IteratedPoint();
            point.InitState = initVal;
            point.StatePath = initVal;
            point.IteratedFuncStr = obj.IteratedFuncStr;
            point.FuncParams = obj.FuncParams;

            funcParamsNames = keys(point.FuncParams);
            funcParamsValues = values(point.FuncParams);

            for index = 1:length(point.FuncParams)

                if (funcParamsNames(index) ~= obj.WindowParam.Name)
                    point.IteratedFuncStr = regexprep(point.IteratedFuncStr, strcat(funcParamsNames(index), '(?!\d)'), strcat('(', num2str(funcParamsValues{index}), ')'));
                else
                    point.IteratedFuncStr = regexprep(point.IteratedFuncStr, strcat(funcParamsNames(index), '(?!\d)'), strcat('(', num2str(windowParamValue), ')'));
                end

            end

            point.IteratedFunc = str2func(point.IteratedFuncStr);

        end

        function [obj errStruct] = SetFuncParams(obj, handles, errStruct)

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

                if ~isnan(probalyParamsValues(ind))
                    obj.FuncParams(probalyParamsNames{ind}) = probalyParamsValues(ind);
                else
                    errStruct.check = true;
                    strcat(errStruct.msg, probalyParamsNames{ind}, ' ;');
                end

            end

            obj.WindowParam.Name = handles.ParamNameMenu.String;
            obj.WindowParam.Value = obj.FuncParams(obj.WindowParam.Name);

            if (obj.WindowParam.Name == 'z0')
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
                ReCenter = real(str2double(CenterPointStr));
                ImCenter = imag(str2double(CenterPointStr));

                [X, Y] = meshgrid((ReCenter - ReDelta):ReStep:(ReCenter + ReDelta), (ImCenter - ImDelta):ImStep:(ImCenter + ImDelta));
                obj.WindowOfValues = X + i * Y;
            end

        end

        function [obj, errStruct] = CheckIteratedFunc(obj, errStruct)

            funcParamsNames = keys(obj.FuncParams);

            testFuncStr = obj.IteratedFuncStr;

            for index = 1:length(obj.FuncParams)

                if contains(iteratedFuncStr, funcParamsNames(index))
                    testFuncStr = regexprep(testFuncStr, strcat(funcParamsNames(index), '(?!\d)'), '(0)');
                end

            end

            try

                testFunc = str2func(testFuncStr);

                if any([isnan(testFunc(0)) isinf(testFunc(0))])
                    warning(cell2mat(strcat({'Entered iterated function '}, {strrep(obj.IteratedFuncStr, '@(z)', '')}, {' returns an NaN or Inf values in case of parameters equal to 0'})));
                end

            catch
                errStruct.check = true;
                errStruct.msg = strcat(errStruct.msg, ' Неправильный формат итерируемой функции; ');
            end

        end

        function [obj] = Iteration(obj)
        end

    end

end
