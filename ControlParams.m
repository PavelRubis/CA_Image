classdef ControlParams%класс параметров управления и множественного элементарного расчета

    properties
        IterCount double {mustBeInteger, mustBePositive}%количество итераций
        SingleOrMultipleCalc logical%одиночный или множественный рассчет
        ReRangeWindow (1, :) double% массив действительных значений параметра "окна"
        ImRangeWindow (1, :) double% массив мнимых значений параметра "окна"
        WindowParamName (1, :) char% название параметра "окна"
        WindowCenterValue double% центральная точка окна
        SingleParams (1, 2) double% одиночные параметры мультирасчета
        IsReady2Start logical = false% задан ли КА
        ImageFunc function_handle% отображение для множественного расчета
        Lambda (1, :) char% множитель лямбда перед отображением exp(i*z)

        Periods (:, :) double% значения периодов
        LastIters (:, :) double% последняя итерация
    end

    methods

        function obj = ControlParams(iterCount, singleOrMultipleCalc, reRangeWindow, imRangeWindow, windowParamName, imageFunc, lambda)

            if nargin
                obj.IterCount = iterCount;
                obj.SingleOrMultipleCalc = singleOrMultipleCalc;
                obj.ReRangeWindow = reRangeWindow;
                obj.ImRangeWindow = imRangeWindow;
                obj.WindowParamName = windowParamName;
                obj.ImageFunc = imageFunc;
                obj.Lambda = lambda;
            end

        end

    end

    methods (Static)

        % метод get-set для статической переменной функции мультирасчета
        function out = GetSetMultiCalcFunc(func)
            persistent MultiCalcFunc;

            if nargin == 1
                MultiCalcFunc = func;
            end

            out = MultiCalcFunc;
        end

        % метод get-set для статической переменной порогов точности
        function out = GetSetPrecisionParms(parms)
            persistent PrecisionParms;

            if nargin == 1
                PrecisionParms = parms;
            end

            out = PrecisionParms;
        end

        % метод get-set для статической переменной максимального периода в мультирасчете
        function out = GetSetMaxPeriod(mp)
            persistent MaxPeriod;

            if nargin == 1
                MaxPeriod = mp;
            end

            out = MaxPeriod;
        end

        % метод get-set для статической переменной-флага пользовательского отображения
        function out = GetSetCustomImag(customBase)
            persistent CustomBase;

            if nargin == 1
                CustomBase = customBase;
            end

            out = CustomBase;
        end

        %метод мультирасчета
        function [z_New fStepLast fCodeNew iter period] = MakeMultipleCalcIter(windowParam, z_Old, z_Old_1, itersCount, zParam, z_eq)
            PrecisionParms = ControlParams.GetSetPrecisionParms;
            func = ControlParams.GetSetMultiCalcFunc;
            pointPath = nan(1, itersCount);
            pointPath(1) = z_Old;
            fStepLast = 1;

            while (fStepLast ~= itersCount)

                if log(z_Old) / (2.302585092994046) >= PrecisionParms(1) || abs(z_Old_1 - z_Old) < PrecisionParms(2)
                    break;
                else

                    if zParam
                        z_New = func(windowParam);
                    else
                        z_New = func(windowParam, z_Old, z_eq);
                    end

                    fStepLast = fStepLast + 1;
                end

                z_Old_1 = z_Old;
                z_Old = z_New;
                pointPath(fStepLast) = z_New;

                if zParam
                    windowParam = z_New;
                end

            end

            [fCodeNew iter period] = ControlParams.CheckConvergence(pointPath);

        end

        function [fCodeNew iter period] = CheckConvergence(pointPath)

            fCodeNew = [];
            PrecisionParms = ControlParams.GetSetPrecisionParms;
            MaxPeriod = ControlParams.GetSetMaxPeriod;

            pointPath = pointPath(find(~isnan(pointPath)));

            %уход в бесконечность
            if (log(pointPath(end)) / log(10) > PrecisionParms(1)) || isnan(pointPath(end)) || isinf(pointPath(end))%бесконечность
                fCodeNew = -1;
                iter = length(pointPath);
                period = 0;
                return;
            end

            %сходимость
            c = 3:length(pointPath);
            converg = abs(pointPath(c - 1) - pointPath(c)) <= PrecisionParms(2);

            if any(converg)
                iter = c(find(converg, 1, 'first'));
                fCodeNew = 1;
                period = 1;
                return;
            end

            %период и мб сходимость
            for n = 2:length(pointPath)

                q = min(n, MaxPeriod);
                qArr = 1:q - 1;
                r = abs(pointPath(n - qArr) - pointPath(n));

                if r(1) < PrecisionParms(2) || norm(r) < 2 * q * PrecisionParms(2)
                    iter = n - 1;
                    fCodeNew = 1;
                    period = 1;
                    return;
                else
                    [minR prd] = min(r);

                    if minR < PrecisionParms(2)
                        iter = n - prd;
                        fCodeNew = 3;
                        period = prd;
                        return;
                    end

                end

            end

            fCodeNew = 2;
            iter = length(pointPath);
            period = Inf;
        end

        function [z_eq] = CountZBaze(miu, z0)

            persistent func

            if isempty(func)
                func = @(z)(Miu) * exp(i * z);
            end

            MiuStr = num2str(miu);
            FbaseStr = strrep(func2str(func), 'Miu', MiuStr);
            Fbase = str2func(FbaseStr);

            mapz_zero = @(z) abs(Fbase(z) - z);
            %            mapz_zero=Fbase;
            mapz_zero_xy = @(z) mapz_zero(z(1) + i * z(2));
            [zeq, zer] = fminsearch(mapz_zero_xy, [real(z0) imag(z0)], optimset('TolX', 1e-9));
            z_eq = complex(zeq(1), zeq(2));
        end

    end

end
