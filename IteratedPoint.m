classdef IteratedPoint < IIteratedObject & handle % ������ ������������� �������

    properties

        % ������������� �������
        IteratedFunc
        % ������ ������������� ��������, � ������� ����������� ���������
        IteratedFuncStr
        % ��������� �������� ������������� ��������
        InitState double = nan;
        % �������� ������������� �������� �� ������ ��������
        StatePath (1, :) double;
        % ������� ���������� ������������� �������
        FuncParams
        % "������" ������������� �������
        Fate double = Inf;
        % ��������, �� ������� ���� ���������� "������"
        LastIterNum double {mustBePositive, mustBeInteger};
        % �������� �������� ������� ����� �������������
        Step double {mustBePositive, mustBeInteger};

    end

    methods

        % ����������� ������� � ������
        function [obj] = IteratedPoint()

            obj.IteratedFunc = @(z)nan;
            obj.IteratedFuncStr = '@(z)nan';
            obj.FuncParams = [];
            obj.InitState = nan;

        end

        % ����������� �����������
        function [obj] = Initialization(obj, handles)

            obj = SetInitValueAndFuncParams(obj, handles);
            obj = GetIteratedFuncStr(obj, handles);
            [obj, errorStr] = CreateIteratedFunc(obj, handles);
            
            errStruct = struct;
            errStruct.check = isempty(errorStr);
            errStruct.msg = errorStr;
            setappdata(handles.output, 'errStruct', errStruct);
        end

        % ��������� ������������� ������� �� GUI - ���������
        function [obj] = GetIteratedFuncStr(obj, handles)

            funcStr = '';

            if ~handles.PointCustomIterFuncCB.Value

                switch handles.PointBaseImagMenu.Value
                    case 1
                        funcStr = strcat(funcStr, '@(z)(exp(i * z))');
                    case 2
                        funcStr = strcat(funcStr, '@(z)(z^2+mu)');
                    case 3
                        funcStr = strcat(funcStr, '@(z)(1)');

                end

                switch handles.PointLambdaMenu.Value

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
                funcStr = strcat(funcStr, '@(z)', handles.PointUsersBaseImagEdit.String);
            end

            obj.IteratedFuncStr = funcStr;

        end

        % ��������� ���������� ��������� � ���������� ������������� �������
        function [obj] = SetInitValueAndFuncParams(obj, handles)

            probalyParamsNames = {'z0', 'mu0', 'mu'};
            probalyParamsValues = [];

            if (~isempty(regexp(handles.Pointz0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.Pointz0Edit.String)];

                obj.InitState = str2double(handles.Pointz0Edit.String);
                obj.StatePath = obj.InitState;

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            if (~isempty(regexp(handles.PointMiu0Edit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.PointMiu0Edit.String)];

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            if (~isempty(regexp(handles.PointMiuEdit.String, '^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')))

                probalyParamsValues = [probalyParamsValues str2double(handles.PointMiuEdit.String)];

            else
                probalyParamsValues = [probalyParamsValues nan];
            end

            obj.FuncParams = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for ind = 1:length(probalyParamsNames)
                obj.FuncParams(probalyParamsNames{ind}) = probalyParamsValues(ind);
            end

        end

        % ��������� ������������� ������� � ������� �������� �������� ����������
        function [obj, errorStr] = CreateIteratedFunc(obj, handles)

            errorCheck = false;

            errorStr = '������ � ��������� ����� ����������: ';

            funcParamsNames = keys(obj.FuncParams);
            funcParamsValues = values(obj.FuncParams);

            if (isnan(funcParamsValues{1}))
                errorCheck = true;
                errorStr = strcat(errorStr, ' ��������� �������� ����� z; ');
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
                errorStr = strcat(errorStr, ' ������������ ������ ����������� �������; ');
            end

            if errorCheck
                obj = [];
            end

        end

        % ��������� ������ ��� ����������� ModelingParamsForPath.GetIterCount �������� ������� ����� ��������������
        function [obj] = BeforeModeling(obj)

            obj.Step = length(obj.StatePath) + 1;
            obj.StatePath = [obj.StatePath nan(1, ModelingParamsForPath.GetIterCount)];
        end

        % �������� �������� ������������� �������
        function [obj] = Iteration(obj, calcParams)

            obj.StatePath(obj.Step) = obj.IteratedFunc(obj.StatePath(obj.Step - 1));
            obj.Step = obj.Step + 1;
            [obj] = CheckConvergence(obj, calcParams);
            
        end

        % �������� �� ���������� �����-���� "������" (0-���� � �������������, 1-����������, >1-�������������, inf-����)
        function [obj] = CheckConvergence(obj, calcParams)

            PrecisionParms = [calcParams.InfVal calcParams.EqualityVal];
            MaxPeriod = calcParams.MaxPeriod;

            pointPath = obj.StatePath(find(~isnan(obj.StatePath)));

            %���� � �������������
            if (abs(pointPath(end)) > PrecisionParms(1)) || isnan(pointPath(end)) || isinf(pointPath(end))
                obj.LastIterNum = length(pointPath);
                obj.Fate = 0;
                return;
            end

            %����������
            c = 3:length(pointPath);
            converg = abs(pointPath(c - 1) - pointPath(c)) <= PrecisionParms(2);

            if any(converg)
                obj.LastIterNum = c(find(converg, 1, 'first'));
                obj.Fate = 1;
                return;
            end
            
            Q = 10;
            %������ � �� ����������
            for n = 2:length(pointPath)

                q = min(n, MaxPeriod);
                qArr = 1:q - 1;
                r = abs(pointPath(n - qArr) - pointPath(n));

                [r_min, s_min] = min(r);
                if r_min < calcParams.EqualityVal && s_min == 1
                    obj.LastIterNum = n - 1;
                    obj.Fate = 1;
                    return;
                end

                if r_min < calcParams.EqualityVal
                    r_max = max(r(1:s_min));
                    if  r_max / r_min > Q
                         obj.LastIterNum = n;
                         obj.Fate = s_min;
                        return;
                    else
                        obj.LastIterNum = n - 1;
                        obj.Fate = 1;
                        return;
                    end
                end

            end

            obj.LastIterNum = length(pointPath);
            obj.Fate = Inf;
        end

        % ��������: ���� "������" �������� - ����������� �������� ����� �������������
        function check = IsContinue(obj)
            check = (obj.Fate == Inf);
        end

        % 
        function [status] = GetModellingStatus(obj)
            status = true;
            
            if isinf(obj.Fate)
                return;
            end

            temp = ModelingParamsForPath.GetSetPrecisionParms;
            newPrecisionParms = struct;
            newPrecisionParms.InfVal = temp(1);
            newPrecisionParms.EqualityVal = temp(2);
            newPrecisionParms.MaxPeriod = ModelingParamsForPath.GetSetMaxPeriod;

            oldFate = obj.Fate;
            [obj] = CheckConvergence(obj, newPrecisionParms);
            
            if obj.Fate == oldFate
                status = false;
                return;
            end
            obj.Fate = oldFate;

        end

    end

    methods (Static)

        % ������ ��������� z* (���� �� ������� � �������� ��������� �������) �� ������ ��������� mu � ���������� ��������� z0
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

    end

end
