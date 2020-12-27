classdef DataFormatting

    methods (Static)

        function [userFuncStrFormated, foundedNegbourCount, userFuncError] = PreUserImagFormatting(userFuncStr, contParms)

            userFuncError = false;
            userFuncStrFormated = userFuncStr;
            foundedNegbourCount = 0;

            try
                varNum = 0;
                varStr = '@(';

                if ~isempty(regexp(userFuncStr, 'z\D'))
                    varNum = varNum + 1;
                    varStr = strcat(varStr, 'z,');
                end

                if contains(userFuncStr, 'mu0')
                    userFuncStr = strrep(userFuncStr, 'mu0', 'Miu0');
                    varNum = varNum + 1;
                    varStr = strcat(varStr, 'Miu0,');
                end

                if ~isempty(regexp(userFuncStr, 'mu[^\di]'))
                    userFuncStr = strrep(userFuncStr, 'mu', 'Miu');
                    varNum = varNum + 1;
                    varStr = strcat(varStr, 'Miu,');
                end

                varStr = regexprep(varStr, ',$', '\)');

                neigborParamsCount = 0;
                neigborsWeightsCount = 0;

                userFuncStrTest = userFuncStr;

                if ~isempty(regexp(userFuncStr, 'z[1-9]+'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    neigborsStrs = regexp(userFuncStr, 'z[1-9]+', 'match');
                    neigborsIndxes = regexp(cell2mat(neigborsStrs), '[1-9]+', 'match');
                    neigborsWeightsCount = max(str2double(neigborsIndxes));

                    for k = 1:neigborsWeightsCount
                        userFuncStrTest = strrep(userFuncStrTest, strcat('z', num2str(k)), '(0)');
                    end

                end

                if ~isempty(regexp(userFuncStr, 'mu[1-9]+'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    neigborsWeightsStrs = regexp(userFuncStr, 'mu[1-9]+', 'match');
                    neigborsWeightsIndxes = regexp(cell2mat(neigborsWeightsStrs), '[1-9]+', 'match');
                    neigborsWeightsCount = max(str2double(neigborsWeightsIndxes));

                    for k = 1:neigborsWeightsCount
                        userFuncStrTest = strrep(userFuncStrTest, strcat('mu', num2str(k)), '(0)');
                    end

                end

                if ~isempty(regexp(userFuncStr, 'mui'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    userFuncStrTest = strrep(userFuncStrTest, 'mui', '(0)');
                end

                if ~isempty(regexp(userFuncStr, 'nc'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    userFuncStrTest = strrep(userFuncStrTest, 'nc', '(0)');
                end

                funcStr = strcat(varStr, userFuncStr);
                testFunc = str2func(strcat(varStr, userFuncStrTest));

                switch varNum
                    case 1

                        if isnan(testFunc(0))
                            i_love_MATLAB^2;
                        end

                    case 2

                        if isnan(testFunc(0, 0))
                            i_love_MATLAB^2;
                        end

                    case 3

                        if isnan(testFunc(0, 0, 0))
                            i_love_MATLAB^2;
                        end

                    otherwise
                        i_love_MATLAB^2;
                end

                funcStr = strrep(funcStr, '@(z)', '@(z)');

                funcStr = strrep(funcStr, '@(Miu)', '@(z)');
                funcStr = strrep(funcStr, '@(Miu0)', '@(z)');
                funcStr = strrep(funcStr, '@(Miu,Miu0)', '@(z)');

                funcStr = strrep(funcStr, '@(z,Miu)', '@(z)');
                funcStr = strrep(funcStr, '@(z,Miu0)', '@(z)');
                funcStr = strrep(funcStr, '@(z,Miu0,Miu)', '@(z)');

                userFuncStrFormated = funcStr;
                foundedNegbourCount = max([neigborParamsCount neigborsWeightsCount]);
            catch
                userFuncError = true;
            end

        end

        %замена в обоих функциях текста постоянных параметров на текст их значения
        function MakeCAFuncsWithNums(ca)
            thisCA = ca;

            MiuStr = strcat('(', num2str(thisCA.Miu));
            MiuStr = strcat(MiuStr, ')');
            Miu0Str = strcat('(', num2str(thisCA.Miu0));
            Miu0Str = strcat(Miu0Str, ')');
            baseFuncStr = strrep(func2str(thisCA.Base), 'Miu0', Miu0Str);
            baseFuncStr = strrep(baseFuncStr, 'Miu', MiuStr);

            lambdaFuncStr = strrep(func2str(thisCA.Lambda), 'Miu0', Miu0Str);
            lambdaFuncStr = strrep(lambdaFuncStr, 'Miu', MiuStr);

            zBStr = strcat('(', num2str(thisCA.Zbase));
            zBStr = strcat(zBStr, ')');
            lambdaFuncStr = strrep(lambdaFuncStr, 'Zbase', zBStr);

            baseFuncStr = strrep(baseFuncStr, 'mui', strcat('(', num2str(ca.Weights(end)), ')'));

            for k = 1:length(ca.Weights) - 1
                baseFuncStr = strrep(baseFuncStr, strcat('mu', num2str(k)), strcat('(', num2str(ca.Weights(k)), ')'));
            end

            baseFunc = str2func(baseFuncStr);
            lambdaFunc = str2func(lambdaFuncStr);

            CellularAutomat.GetSetFuncs(baseFunc, lambdaFunc);

        end

        function [customImag] = MakeCACustomImagWithNeighbors(customImagStr, CA_cell)

            for k = 1:length(CA_cell.CurrNeighbors)
                customImagStr = strrep(customImagStr, strcat('z', num2str(k)), strcat('(', num2str(CA_cell.CurrNeighbors(k).zPath(end)), ')'));
            end

            neiborsNotFound = regexp(customImagStr, 'z[1-9]+', 'match');

            if ~isempty(neiborsNotFound)
                customImagStr = regexprep(customImagStr, 'z[1-9]+', '(0)');
                warningStr = '';

                for k = 1:length(neiborsNotFound)
                    warningStr = strcat(warningStr, char(neiborsNotFound(k)), ';');
                end

                warningStr = regexprep(warningStr, ';$', '');
                warning(strcat(' cell with indexes', strcat(' ', num2str(CA_cell.Indexes), ' '), 'do not contains neighbors with values', strcat(' ', warningStr, ' '), 'which are declared in the iterated function'));
            end

            customImagStr = strrep(customImagStr, 'nc', strcat('(', num2str(length(CA_cell.CurrNeighbors)), ')'));

            %             neiborsWeightsNotFound = regexp(customImagStr, 'mu[1-9]+', 'match');
            %
            %             if ~isempty(neiborsWeightsNotFound)
            %                 customImagStr = regexprep(customImagStr, 'mu[1-9]+', '(0)');
            %                 warningStr = '';
            %
            %                 for k = 1:length(neiborsWeightsNotFound)
            %                     warningStr = strcat(warningStr, char(neiborsWeightsNotFound(k)), ';');
            %                 end
            %
            %                 warningStr = regexprep(warningStr, ';$', '');
            %                 warning(strcat(' cell with indexes', strcat(' ', num2str(CA_cell.Indexes), ' '), 'do not contains neighbors with weights', strcat(' ', warningStr, ' '), 'which are declared in the iterated function'));
            %             end

            customImag = str2func(customImagStr);

        end

        %метод создания окна и матрицы функций базы
        function [WindowParam ContParms z_eqArr] = MakeFuncsWithNumsForMultipleCalc(ca, contParms)
            [X, Y] = meshgrid(contParms.ReRangeWindow, contParms.ImRangeWindow);
            WindowParam = X + i * Y;
            z_eqArr = Inf(size(WindowParam));

            switch contParms.WindowParamName
                    % в случае окна по Z0
                case 'z0'

                    zBaseStr = strcat('(', num2str(ca.Zbase));
                    zBaseStr = strcat(zBaseStr, ')');

                    Miu0Str = strcat('(', num2str(ca.Miu0));
                    Miu0Str = strcat(Miu0Str, ')');

                    MiuStr = strcat('(', num2str(ca.Miu));
                    MiuStr = strcat(MiuStr, ')');

                    contParms.ImageFunc = str2func(strrep(func2str(contParms.ImageFunc), '@(Miu0,z,eq)', '@(z)'));
                    contParms.ImageFunc = str2func(strrep(func2str(contParms.ImageFunc), '@(Miu,z,eq)', '@(z)'));
                    contParms.ImageFunc = str2func(strrep(func2str(contParms.ImageFunc), '@(Miu,z)', '@(z)'));
                    baseFuncStr = strrep(func2str(contParms.ImageFunc), 'Miu0', Miu0Str);
                    baseFuncStr = strrep(baseFuncStr, 'Miu', MiuStr);
                    baseFuncStr = strrep(baseFuncStr, 'eq', zBaseStr);

                    % в случае окна по Мю
                case 'Miu'

                    baseFuncStr = func2str(contParms.ImageFunc);
                    baseFuncStr = strrep(baseFuncStr, '@(z)', '@(Miu,z,eq)');
                    baseFuncStr = strrep(baseFuncStr, '@(Miu,z)', '@(Miu,z,eq)');
                    baseFuncStr = strrep(baseFuncStr, '@(Miu0,z,eq)', '@(Miu,z,eq)');
                    contParms.ImageFunc = str2func(baseFuncStr);

                    Miu0Str = strcat('(', num2str(ca.Miu0));
                    Miu0Str = strcat(Miu0Str, ')');
                    baseFuncStr = strrep(baseFuncStr, 'Miu0', Miu0Str);

                    pureFuncStr = strrep(baseFuncStr, '@(Miu,z,eq)', '');

                    if contains(pureFuncStr, 'eq')
                        z0Arr = zeros(size(WindowParam));
                        %ControlParams.GetSetMultiCalcFunc(baseFuncStr);
                        z0Arr(:) = ControlParams.CountZBaze(contParms.WindowCenterValue, -3.5 + 0.5 * i);
                        z_eqArr = arrayfun(@ControlParams.CountZBaze, WindowParam, z0Arr);
                    end

                    % в случае окна по Мю0
                case 'Miu0'

                    baseFuncStr = func2str(contParms.ImageFunc);

                    baseFuncStr = strrep(baseFuncStr, '@(z)', '@(Miu0,z,eq)');
                    baseFuncStr = strrep(baseFuncStr, '@(Miu,z)', '@(Miu0,z,eq)');
                    baseFuncStr = strrep(baseFuncStr, '@(Miu,z,eq)', '@(Miu0,z,eq)');
                    contParms.ImageFunc = str2func(baseFuncStr);

                    MiuStr = strcat('(', num2str(ca.Miu));
                    MiuStr = strcat(MiuStr, ')');

                    zBaseStr = strcat('(', num2str(ca.Zbase));
                    zBaseStr = strcat(zBaseStr, ')');

                    baseFuncStr = regexprep(baseFuncStr, 'Miu(?!0)', MiuStr);
                    baseFuncStr = regexprep(baseFuncStr, 'Miu$', MiuStr);
                    baseFuncStr = regexprep(baseFuncStr, '(?<!,)eq', zBaseStr);

            end

            baseFuncStr = str2func(baseFuncStr);
            ControlParams.GetSetMultiCalcFunc(baseFuncStr);
            ContParms = contParms;
        end

    end

end
