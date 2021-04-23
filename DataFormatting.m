classdef DataFormatting

    methods (Static)

        function [userFuncStrFormated, foundedNegbourCount, userFuncError] = PreUserImagFormatting(userFuncStr, contParms)

            userFuncError = false;
            userFuncStrFormated = userFuncStr;
            foundedNegbourCount = 0;

            try
                varNum = 0;
                varStr = '@(';

                if ~isempty(regexp(userFuncStr, 'z\D')) || contParms.SingleOrMultipleCalc
                    varNum = varNum + 1;
                    varStr = strcat(varStr, 'z,');
                end

                if contains(userFuncStr, 'mu0')
                    userFuncStr = strrep(userFuncStr, 'mu0', 'Miu0');

                    if ~contParms.SingleOrMultipleCalc
                        varNum = varNum + 1;
                        varStr = strcat(varStr, 'Miu0,');
                    end

                end

                if ~isempty(regexp(userFuncStr, 'mu(?![\di])'))
                    userFuncStr = regexprep(userFuncStr, 'mu(?![\di])', 'Miu');

                    if ~contParms.SingleOrMultipleCalc
                        varNum = varNum + 1;
                        varStr = strcat(varStr, 'Miu,');
                    end

                end

                varStr = regexprep(varStr, ',$', '\)');

                neigborParamsCount = 0;
                neigborsWeightsCount = 0;

                userFuncStrTest = userFuncStr;

                if contParms.SingleOrMultipleCalc
                    userFuncStrTest = strrep(userFuncStrTest, 'Miu0', '(1)');
                    userFuncStrTest = strrep(userFuncStrTest, 'Miu', '(1)');
                end

                if ~isempty(regexp(userFuncStr, 'z[1-9]+'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    neigborsStrs = regexp(userFuncStr, 'z[1-9]+', 'match');
                    neigborsIndxes = regexp(cell2mat(neigborsStrs), '[1-9]+', 'match');
                    neigborsWeightsCount = max(str2double(neigborsIndxes));

                    for k = 1:neigborsWeightsCount
                        userFuncStrTest = strrep(userFuncStrTest, strcat('z', num2str(k)), '(1)');
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
                        userFuncStrTest = strrep(userFuncStrTest, strcat('mu', num2str(k)), '(1)');
                    end

                end

                if ~isempty(regexp(userFuncStr, 'mui'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    userFuncStrTest = strrep(userFuncStrTest, 'mui', '(1)');
                end

                if ~isempty(regexp(userFuncStr, 'nc'))

                    if ~contParms.SingleOrMultipleCalc
                        i_love_MATLAB^2;
                    end

                    userFuncStrTest = strrep(userFuncStrTest, 'nc', '(1)');
                end

                funcStr = strcat(varStr, userFuncStr);
                testFunc = str2func(strcat(varStr, userFuncStrTest));

                switch varNum
                    case 1

                        if isnan(testFunc(1))
                            i_love_MATLAB^2;
                        end

                    case 2

                        if isnan(testFunc(1, 1))
                            i_love_MATLAB^2;
                        end

                    case 3

                        if isnan(testFunc(1, 1, 1))
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

        %Р·Р°РјРµРЅР° РІ РѕР±РѕРёС… С„СѓРЅРєС†РёСЏС… С‚РµРєСЃС‚Р° РїРѕСЃС‚РѕСЏРЅРЅС‹С… РїР°СЂР°РјРµС‚СЂРѕРІ РЅР° С‚РµРєСЃС‚ РёС… Р·РЅР°С‡РµРЅРёСЏ
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

            baseFuncStr = strrep(baseFuncStr, 'mui', strcat('(', num2str(ca.Weights(1)), ')'));

            neighborsWeights = ca.Weights(2:end);

            for k = 1:length(neighborsWeights)
                baseFuncStr = strrep(baseFuncStr, strcat('mu', num2str(k)), strcat('(', num2str(neighborsWeights(k)), ')'));
            end

            baseFunc = str2func(baseFuncStr);
            lambdaFunc = str2func(lambdaFuncStr);

            CellularAutomat.GetSetFuncs(baseFunc, lambdaFunc);

        end

        function [customImag] = MakeCACustomImagWithNeighbors(customImagStr, CA_cell)

            for k = 1:length(CA_cell.CurrNeighbors)
                customImagStr = strrep(customImagStr, strcat('z', num2str(k)), strcat('(', num2str(CA_cell.CurrNeighbors(k).ZPath(end)), ')'));
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

            customImag = str2func(customImagStr);

        end

        %РјРµС‚РѕРґ СЃРѕР·РґР°РЅРёСЏ РѕРєРЅР° Рё РјР°С‚СЂРёС†С‹ С„СѓРЅРєС†РёР№ Р±Р°Р·С‹
        function [WindowParam ContParms z_eqArr] = MakeFuncsWithNumsForMultipleCalc(ca, contParms)
            [X, Y] = meshgrid(contParms.ReRangeWindow, contParms.ImRangeWindow);
            WindowParam = X + i * Y;
            z_eqArr = Inf(size(WindowParam));

            switch contParms.WindowParamName
                    % РІ СЃР»СѓС‡Р°Рµ РѕРєРЅР° РїРѕ Z0
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

                    % РІ СЃР»СѓС‡Р°Рµ РѕРєРЅР° РїРѕ РњСЋ
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

                    % РІ СЃР»СѓС‡Р°Рµ РѕРєРЅР° РїРѕ РњСЋ0
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

        %форматирование графика
        function PlotFormatting(contParms, ca, handles)

            titleStr = '';

            if ca.N == 1

                switch func2str(ca.Base)
                    case '@(z)(exp(i*z))'
                        titleStr = 'z\rightarrow\lambda\cdotexp(i\cdotz)';
                        titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                    case '@(z)(z^2+Miu)'
                        titleStr = 'z\rightarrow\lambda\cdotz^{2}+c';
                        titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                    case '@(z)Miu'
                        titleStr = 'z\rightarrow\lambda\cdot\mu';
                        titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                    otherwise
                        titleStr = func2str(ca.Base);
                        titleStr = strrep(titleStr, '@(z)', 'z\rightarrow');
                end

                titleStr = strrep(titleStr, 'Miu0', '\mu_{0}');
                titleStr = strrep(titleStr, 'Miu', '\mu');
                titleStr = strrep(titleStr, '*', '\cdot');

                titleStr = strcat(titleStr, ' ; z_{0}=', num2str(ca.Cells(1).z0));

                if contains(titleStr, 'eq')
                    titleStr = strrep(titleStr, 'eq', 'z^{*}');
                    titleStr = strcat(titleStr, ' ; z^{*}', num2str(ca.Cells(1).Zbase));
                end

                if isempty(ControlParams.GetSetCustomImag)
                    titleStr = strcat(titleStr, ' ; \mu=', num2str(ca.Miu), ' ; \mu_{0}=', num2str(ca.Miu0));
                else

                    if ~ControlParams.GetSetCustomImag
                        titleStr = strcat(titleStr, ' ; \mu=', num2str(ca.Miu), ' ; \mu_{0}=', num2str(ca.Miu0));
                    end

                end

                title(handles.CAField, strcat('\fontsize{16}', titleStr));
                handles.CAField.FontSize = 10;
            else

                if contParms.SingleOrMultipleCalc

                    switch func2str(ca.Base)
                        case '@(z)(exp(i*z))'
                            titleStr = 'z\rightarrow\lambda\cdotexp(i\cdotz)';
                        case '@(z)(z^2+Miu)'
                            titleStr = 'z\rightarrowz^{2}+\mu';
                        case '@(z)Miu'
                            titleStr = 'z\rightarrow\lambda\cdot\mu';
                        otherwise
                            titleStr = func2str(ca.Base);
                            titleStr = strrep(titleStr, '@(z)', 'z\rightarrow');
                    end

                    if isempty(ControlParams.GetSetCustomImag)

                        switch handles.LambdaMenu.Value
                            case 1
                                titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\Sigma_{k=1}^{n}\mu_{k}\cdotz_{k}^{t}');
                            case 2
                                titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu)\mid');
                            case 3
                                titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}(-1^{k})\cdotz_{k}^{t}\mid');
                            case 4
                                titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot( (1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu))');
                            case 5
                                titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                        end

                    else

                        if ~ControlParams.GetSetCustomImag

                            switch handles.LambdaMenu.Value
                                case 1
                                    titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\Sigma_{k=1}^{n}\mu_{k}\cdotz_{k}^{t}');
                                case 2
                                    titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu)\mid');
                                case 3
                                    titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot\mid(1/n)\cdot\Sigma_{k=1}^{n}(-1^{k})\cdotz_{k}^{t}\mid');
                                case 4
                                    titleStr = strcat(titleStr, ' ; \lambda=\mu+\mu_{0}\cdot( (1/n)\cdot\Sigma_{k=1}^{n}z_{k}^{t}-z^{*}(\mu) )');
                                case 5
                                    titleStr = strcat(titleStr, ' ; \lambda=\mu_{0}+\mu');
                            end

                        end

                    end

                    titleStr = strrep(titleStr, 'Miu0', '\mu_{0}');
                    titleStr = strrep(titleStr, 'Miu', '\mu');
                    titleStr = strrep(titleStr, '*', '\cdot');
                    titleStr = strcat(titleStr, ' ');

                    if contains(titleStr, '\mu_{0}')
                        titleStr = strcat(titleStr, ' ; \mu_{0}=', num2str(ca.Miu0));
                    end

                    if ~isempty(regexp(titleStr, '\\mu(?!_)'))
                        titleStr = strcat(titleStr, ' ; \mu=', num2str(ca.Miu));
                    end

                    if contains(titleStr, 'z^{\cdot}(\mu)')
                        titleStr = strrep(titleStr, 'z^{\cdot}(\mu)', 'z^{*}(\mu)');
                        titleStr = strcat(titleStr, ' ; z^{*}(\mu)=', num2str(ca.Zbase));
                    end

                    if ~isempty(regexp(titleStr, 'mui'))
                        titleStr = strrep(titleStr, 'mui', '\mu_{i}');
                    end

                    neigborsStrs = regexp(titleStr, 'z[1-9]+', 'match');

                    if ~isempty(neigborsStrs)
                        neigborsIndxes = regexp(cell2mat(neigborsStrs), '[1-9]+', 'match');
                        neigborsCount = max(str2double(neigborsIndxes));

                        for k = 1:neigborsCount
                            titleStr = strrep(titleStr, strcat('z', num2str(k)), strcat('z_{', num2str(k), '}'));
                        end

                    end

                    neigborsWeightsStrs = regexp(titleStr, 'mu[1-9]+', 'match');

                    if ~isempty(neigborsWeightsStrs)
                        neigborsWeightsIndxes = regexp(cell2mat(neigborsWeightsStrs), '[1-9]+', 'match');
                        neigborsWeightsCount = max(str2double(neigborsWeightsIndxes));

                        for k = 1:neigborsWeightsCount
                            titleStr = strrep(titleStr, strcat('mu', num2str(k)), strcat('\mu_{', num2str(k), '}'));
                        end

                    end

                    title(handles.CAField, strcat('\fontsize{16}', titleStr));
                else

                    if ~contParms.GetSetCustomImag
                        titleStr = strrep(func2str(contParms.ImageFunc), contParms.Lambda, '');
                        titleStr = strrep(titleStr, '(exp(i*z))', '\lambda\cdotexp(i*z)');
                        lambdaStr = contParms.Lambda;
                        lambdaStr(1) = [];
                        titleStr = strcat(titleStr, '  \lambda=', lambdaStr);
                    else
                        titleStr = func2str(contParms.ImageFunc);
                    end

                    titleStr = strrep(titleStr, '*', '\cdot');

                    switch contParms.WindowParamName
                        case 'z0'
                            titleStr = strrep(titleStr, '@(z)', 'z\rightarrow');
                            titleStr = strrep(titleStr, 'Miu0', '\mu_{0}');
                            titleStr = strrep(titleStr, 'Miu', '\mu');
                            xlabel('Re(z_{0})');
                            ylabel('Im(z_{0})');
                            titleStr = strcat(titleStr, '  z_{0_{cntr}}=');
                            titleStr = strcat(titleStr, num2str(complex(mean(contParms.ReRangeWindow), mean(contParms.ImRangeWindow))));
                            titleStr = strcat(titleStr, '  \mu=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(1)));
                            titleStr = strcat(titleStr, '  \mu_{0}=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(2)));
                        case 'Miu'
                            titleStr = strrep(titleStr, '@(Miu,z,eq)', 'z\rightarrow');
                            titleStr = strrep(titleStr, 'Miu0', '\mu_{0}');
                            titleStr = strrep(titleStr, 'Miu', '\mu');
                            titleStr = strcat(titleStr, '  \mu_{cntr}=');
                            titleStr = strcat(titleStr, num2str(complex(mean(contParms.ReRangeWindow), mean(contParms.ImRangeWindow))));
                            titleStr = strcat(titleStr, '  z_{0}=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(1)));
                            titleStr = strcat(titleStr, '  \mu_{0}=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(2)));
                            xlabelStr = 'Re(\mu)';

                            ylabelStr = 'Im(\mu)';

                            xlabel(xlabelStr);
                            ylabel(ylabelStr);
                        case 'Miu0'
                            titleStr = strrep(titleStr, '@(Miu0,z,eq)', 'z\rightarrow');
                            titleStr = strrep(titleStr, 'Miu0', '\mu_{0}');
                            titleStr = strrep(titleStr, 'Miu', '\mu');
                            titleStr = strcat(titleStr, '  \mu_{0_{cntr}}=');
                            titleStr = strcat(titleStr, num2str(complex(mean(contParms.ReRangeWindow), mean(contParms.ImRangeWindow))));
                            titleStr = strcat(titleStr, '  z_{0}=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(1)));
                            titleStr = strcat(titleStr, '  \mu=');
                            titleStr = strcat(titleStr, num2str(contParms.SingleParams(2)));

                            xlabelStr = 'Re(\mu_{0})';
                            ylabelStr = 'Im(\mu_{0})';

                            xlabel(xlabelStr);
                            ylabel(ylabelStr);

                    end

                    titleStr = strrep(titleStr, 'eq', 'z^{*}');

                    if contains(titleStr, 'z^{*}')
                        titleStr = strcat(titleStr, '  z^{*}=');
                        titleStr = strcat(titleStr, num2str(ca.Zbase));
                    end

                    title(handles.CAField, strcat('\fontsize{16}', titleStr));
                    handles.CAField.FontSize = 11;
                end

            end

        end

        function DrawNeighborhood(neighborhoodType)

            switch neighborhoodType
                    %8
                case 1
                    %центральная
                    xArrCenter = [0 1 1 0];
                    yArrCenter = [0 0 1 1];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(0.4, 0.5, 'i', 'FontSize', 16);

                    %юг
                    xArr1 = [0 1 1 0];
                    yArr1 = [-1 -1 0 0];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(0.4, -0.5, '1', 'FontSize', 16);

                    %юго-запад
                    xArr2 = [-1 0 0 -1];
                    yArr2 = [-1 -1 0 0];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(-0.6, -0.5, '2', 'FontSize', 16);

                    %запад
                    xArr3 = [-1 0 0 -1];
                    yArr3 = [0 0 1 1];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(-0.6, 0.5, '3', 'FontSize', 16);

                    %северо-запад
                    xArr4 = [-1 0 0 -1];
                    yArr4 = [1 1 2 2];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(-0.6, 1.5, '4', 'FontSize', 16);

                    %север
                    xArr5 = [0 1 1 0];
                    yArr5 = [1 1 2 2];

                    patch(xArr5, yArr5, [1 1 1]);
                    text(0.4, 1.5, '5', 'FontSize', 16);

                    %северо-восток
                    xArr6 = [1 2 2 1];
                    yArr6 = [1 1 2 2];

                    patch(xArr6, yArr6, [1 1 1]);
                    text(1.4, 1.5, '6', 'FontSize', 16);

                    %восток
                    xArr7 = [1 2 2 1];
                    yArr7 = [0 0 1 1];

                    patch(xArr7, yArr7, [1 1 1]);
                    text(1.4, 0.5, '7', 'FontSize', 16);

                    %юго-восток
                    xArr8 = [1 2 2 1];
                    yArr8 = [-1 -1 0 0];

                    patch(xArr8, yArr8, [1 1 1]);
                    text(1.4, -0.5, '8', 'FontSize', 16);

                    %4
                case 2
                    %центральная
                    xArrCenter = [0 1 1 0];
                    yArrCenter = [0 0 1 1];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(0.4, 0.5, 'i', 'FontSize', 16);

                    %снизу
                    xArr1 = [0 1 1 0];
                    yArr1 = [-1 -1 0 0];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(0.4, -0.5, '1', 'FontSize', 16);

                    %слева
                    xArr2 = [-1 0 0 -1];
                    yArr2 = [0 0 1 1];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(-0.6, 0.5, '2', 'FontSize', 16);

                    %сверху
                    xArr3 = [0 1 1 0];
                    yArr3 = [1 1 2 2];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(0.4, 1.5, '3', 'FontSize', 16);

                    %справа
                    xArr4 = [1 2 2 1];
                    yArr4 = [0 0 1 1];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(1.4, 0.5, '4', 'FontSize', 16);

                    %6
                case 3
                    %центральная
                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    xArrCenter = [0 0 + dx 0 + dx 0 0 - dx 0 - dx];
                    yArrCenter = [0 0 + dy 0 + 3 * dy 0 + 4 * dy 0 + 3 * dy 0 + dy];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(-dx / 4, 2 * dy, 'i', 'FontSize', 16);

                    %низ лево
                    xDiff = -(sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr1 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr1 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '1', 'FontSize', 16);

                    %лево
                    xDiff = -2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '2', 'FontSize', 16);

                    %верх лево
                    xDiff = -(sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr3 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr3 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr3, yArr3, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '3', 'FontSize', 16);

                    %верх право
                    xDiff = (sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr4 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr4 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr4, yArr4, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '4', 'FontSize', 16);

                    %право
                    xDiff = 2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr5 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr5 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr5, yArr5, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '5', 'FontSize', 16);

                    %низ право
                    xDiff = (sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr6 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr6 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr6, yArr6, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '6', 'FontSize', 16);

                    %3
                case 4
                    %центральная
                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    xArrCenter = [0 0 + dx 0 + dx 0 0 - dx 0 - dx];
                    yArrCenter = [0 0 + dy 0 + 3 * dy 0 + 4 * dy 0 + 3 * dy 0 + dy];

                    patch(xArrCenter, yArrCenter, [1 1 1]);
                    text(-dx / 4, 2 * dy, 'i', 'FontSize', 16);

                    %низ лево
                    xDiff = -(sqrt(3) / 2);
                    yDiff = -3/2;
                    xArr1 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr1 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr1, yArr1, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '1', 'FontSize', 16);

                    %верх лево
                    xDiff = -(sqrt(3) / 2);
                    yDiff = 3/2;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '2', 'FontSize', 16);

                    %право
                    xDiff = 2 * (sqrt(3) / 2);
                    yDiff = 0;
                    xArr2 = [xDiff xDiff + dx xDiff + dx xDiff xDiff - dx xDiff - dx];
                    yArr2 = [yDiff yDiff + dy yDiff + 3 * dy yDiff + 4 * dy yDiff + 3 * dy yDiff + dy];

                    patch(xArr2, yArr2, [1 1 1]);
                    text(xDiff + (-dx / 4), yDiff + (2 * dy), '3', 'FontSize', 16);

            end

        end

    end

end
