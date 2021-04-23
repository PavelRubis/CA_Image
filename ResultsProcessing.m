classdef ResultsProcessing
    %����� ��������� ����������� �������������
    properties
        IsSaveData logical = 0% ��������� �� ����������
        isSaveCA logical = 0% ��������� �� ��
        isDuplicateFig logical = 0% ��������� �� ������
        Filename (1, :) char = []
        ResPath (1, :) char% ���� � ����������� �����������
        CellsValuesFileFormat logical% ������ ����� ��� ������ �������� ����� (1-txt,0-xls)
        FigureFileFormat {mustBeInteger, mustBeInRange(FigureFileFormat, [1, 3])}% ������ �������� ����
    end

    methods
        %�����������
        function obj = ResultsProcessing(resPath, cellsValuesFileFormat, figureFileFormat)

            if nargin
                obj.ResPath = resPath;
                obj.CellsValuesFileFormat = cellsValuesFileFormat;
                obj.FigureFileFormat = figureFileFormat;
            end

        end

        %����� ���������� �����������
        function resproc = SaveRes(obj, ca, graphics, contParms, Res)

            if contParms.SingleOrMultipleCalc

                if obj.isSaveCA

                    if length(ca.Cells) == 1
                        PrecisionParms = ModelingParams.GetSetPrecisionParms;
                        lastIter = 1;

                        if isempty(obj.Filename)
                            obj.Filename = strcat('\Modeling-', datestr(clock));
                            obj.Filename = strcat(obj.Filename, '-N-1-Path.txt');
                            obj.Filename = strrep(obj.Filename, ':', '-');
                            obj.Filename = strcat(obj.ResPath, obj.Filename);

                            fileID = fopen(obj.Filename, 'a');
                            fprintf(fileID, strcat('��������� ������������� ��-', datestr(clock)));
                            fprintf(fileID, '\n\n����� N=1');
                            fprintf(fileID, strcat('\n������� �����������: ', func2str(ca.Base)));

                            if ~ControlParams.GetSetCustomImag
                                fprintf(fileID, strcat('\n������ ������: ', func2str(ca.Lambda)));
                            end

                            fprintf(fileID, strcat('\n\n\n������������ ������=', num2str(ControlParams.GetSetMaxPeriod), ';����� �������������=', num2str(PrecisionParms(1)), ';����� ����������=', num2str(PrecisionParms(2))));
                            fprintf(fileID, strcat('\nz0=', num2str(ca.Cells(1).z0), '\nmu=', num2str(ca.Miu), '\nmu0=', num2str(ca.Miu0)));

                            fprintf(fileID, '\n���������� �������� T=%f\n', length(Res) - 1);

                            switch contParms.Periods
                                case 0
                                    fprintf(fileID, '\n\n����: �������� � ������������� ����������\n');
                                case 1
                                    fprintf(fileID, '\n\n����: ���������� � ���������� ����������\n');
                                case inf
                                    fprintf(fileID, '\n\n����: ��������� ����������\n');
                                otherwise
                                    fprintf(fileID, strcat('\n\n����: ���������� � ��������: ', num2str(contParms.Periods), '\n'));
                            end

                            fprintf(fileID, 'Re\tIm\tFate\tlength\n');
                            fclose(fileID);

                            dlmwrite(obj.Filename, [real(ca.Cells(1).ZPath(1)) imag(ca.Cells(1).ZPath(end)) contParms.Periods contParms.LastIters], '-append', 'delimiter', '\t');

                            fileID = fopen(obj.Filename, 'a');
                            fprintf(fileID, '\n\n����������:\n');
                            fprintf(fileID, 'iter\tRe\tIm\n');
                            fclose(fileID);
                        else
                            %8,12 15 17
                            txtCell = txt2Cell(obj);
                            lastIter = str2double(regexp(txtCell{end-2},'^\d+\s','match'));
                            
                            txtCell{8} = strcat('������������ ������ = ', num2str(ControlParams.GetSetMaxPeriod), ' ; ����� ������������� = ', num2str(PrecisionParms(1)), ' ; ����� ���������� = ', num2str(PrecisionParms(2)));
                            txtCell{12} = strcat('���������� �������� T=', num2str(length(Res) - 1));

                            finishStr = '';

                            switch contParms.Periods
                                case 0
                                    finishStr = '�������� � ������������� ����������';
                                case 1
                                    finishStr = '���������� � ���������� ����������';
                                case inf
                                    finishStr = '��������� ����������';
                                otherwise
                                    finishStr = strcat('���������� � ��������: ', num2str(contParms.Periods));
                            end

                            txtCell{15} = strcat('����: ', finishStr);
                            txtCell{17} = cell2mat(strcat({num2str(real(ca.Cells(1).ZPath(end)))}, {'	'}, {num2str(imag(ca.Cells(1).ZPath(end)))}, {'	'}, {num2str(contParms.Periods)}, {'	'}, {num2str(contParms.LastIters)}));

                            cell2Txt(obj, txtCell);
                        end

                        iters = lastIter:(lastIter-1) + length(Res(1, :));
                        iters = iters';
                        Res = Res';
                        Res = [iters Res];
                        dlmwrite(obj.Filename, Res, '-append', 'delimiter', '\t', 'precision', 7);
                        dlmwrite(obj.Filename, ' ', '-append');
                    else
                        ConfFileName = strcat('\Modeling-', datestr(clock));
                        ConfFileName = strcat(ConfFileName, '-CA.txt');
                        ConfFileName = strrep(ConfFileName, ':', '-');
                        ConfFileName = strcat(obj.ResPath, ConfFileName);

                        fileID = fopen(ConfFileName, 'w');
                        fprintf(fileID, strcat('��������� ������������� ��-', datestr(clock)));
                        fprintf(fileID, '\n\n������������ ��:\n\n');

                        if ca.FieldType
                            fprintf(fileID, '��� ������� ����: ��������������\n');
                        else
                            fprintf(fileID, '��� ������� ����: ����������\n');
                        end

                        switch ca.BordersType
                            case 1
                                fprintf(fileID, '��� ������ ����: "����� ������"\n');
                            case 2
                                fprintf(fileID, '��� ������ ����: ��������� ������\n');
                            case 3
                                fprintf(fileID, '��� ������ ����: �������� �������\n');
                        end

                        fprintf(fileID, '����� N=%d\n', ca.N);

                        fprintf(fileID, strcat('������� �����������: ', func2str(ca.Base)));
                        fprintf(fileID, strcat('\n����������� ��������� ������: ', func2str(ca.Lambda)));
                        fprintf(fileID, '\n�������� ��=%f %fi\n', real(ca.Miu), imag(ca.Miu));
                        fprintf(fileID, '�������� ��0=%f %fi\n', real(ca.Miu0), imag(ca.Miu0));
                        fprintf(fileID, '�������� Iter=%f\n\n\n', contParms.IterCount - 1);
                        fprintf(fileID, '������������ Z0:\n\n');
                        fclose(fileID);

                        Z = [];

                        for j = 1:length(ca.Cells)
                            idx = cast(ca.Cells(j).Indexes, 'double');
                            Z = [Z; [idx real(ca.Cells(j).z0) imag(ca.Cells(j).z0)]];
                        end

                        dlmwrite(ConfFileName, 'x	y	k	Re	Im', '-append', 'delimiter', '');
                        dlmwrite(ConfFileName, Z, '-append', 'delimiter', '\t', 'precision', 7);

                        fileID = fopen(ConfFileName, 'a');
                        fprintf(fileID, '\n\n');
                        fprintf(fileID, '�������� ����� �� �������� Iter=%f\n\n', contParms.IterCount - 1);
                        fclose(fileID);

                        Z = [];

                        for j = 1:length(ca.Cells)
                            idx = cast(ca.Cells(j).Indexes, 'double');
                            Z = [Z; [idx real(ca.Cells(j).ZPath(end)) imag(ca.Cells(j).ZPath(end))]];
                        end

                        dlmwrite(ConfFileName, 'x	y	k	Re	Im', '-append', 'delimiter', '');
                        dlmwrite(ConfFileName, Z, '-append', 'delimiter', '\t', 'precision', 7);
                    end

                end

            else

                if obj.isSaveCA
                    ConfFileName = strcat('\MultiCalc-', datestr(clock));
                    ConfFileName = strcat(ConfFileName, '.txt');
                    ConfFileName = strrep(ConfFileName, ':', '-');
                    ConfFileName = strcat(obj.ResPath, ConfFileName);

                    fileID = fopen(ConfFileName, 'w');
                    fprintf(fileID, strcat('������������� ������������� ��- ', datestr(clock)));

                    fprintf(fileID, strcat('\n\n�����������: ', func2str(contParms.ImageFunc)));

                    PrecisionParms = ModelingParams.GetSetPrecisionParms;

                    fprintf(fileID, strcat('\n\n\n������������ ������=', num2str(ControlParams.GetSetMaxPeriod), '\n����� �������������=', num2str(10^PrecisionParms(1)), '\n����� ����������=', num2str(PrecisionParms(2))));

                    switch contParms.WindowParamName
                        case 'z0'
                            fprintf(fileID, strcat('\nz0=', num2str(complex(mean(contParms.ReRangeWindow), mean(contParms.ImRangeWindow))), '\nmu=', num2str(ca.Miu), '\nmu0=', num2str(ca.Miu0)));
                        otherwise
                            fprintf(fileID, strcat('\nz0=', num2str(contParms.SingleParams(1)), '\nmu=', num2str(ca.Miu), '\nmu0=', num2str(ca.Miu0)));
                    end

                    fprintf(fileID, '\n���������� �������� T=%f\n', length(Res) - 1);

                    fprintf(fileID, strcat('\n�������� ����: ', contParms.WindowParamName));
                    fprintf(fileID, '\n�������� ��������� ����: ');

                    paramStart = complex(contParms.ReRangeWindow(1), contParms.ImRangeWindow(1));
                    paramStep = complex(contParms.ReRangeWindow(2) - contParms.ReRangeWindow(1), contParms.ImRangeWindow(2) - contParms.ImRangeWindow(1));
                    paramEnd = complex(contParms.ReRangeWindow(end), contParms.ImRangeWindow(end));

                    paramStartSrt = strcat(num2str(paramStart), ' : ');
                    paramEndSrt = strcat(' : ', num2str(paramEnd));
                    paramSrt = strcat(paramStartSrt, num2str(paramStep));
                    paramSrt = strcat(paramSrt, paramEndSrt);
                    fprintf(fileID, strcat(paramSrt, '\n\n'));
                    fclose(fileID);
                    dlmwrite(ConfFileName, 'Re	Im	Fate	length', '-append', 'delimiter', '');

                    [X, Y] = meshgrid(contParms.ReRangeWindow, contParms.ImRangeWindow);
                    WindowParam = X + i * Y;
                    len = size(WindowParam);
                    resArr = cell(len);
                    resArr = arrayfun(@(re, im, p, n){[re im p n]}, real(WindowParam), imag(WindowParam), contParms.Periods, contParms.LastIters);

                    resArr = cell2mat(resArr);
                    resLen = size(resArr);

                    resArrNew = zeros(len(1) * len(2), 4);
                    c = 0;

                    for j = 1:4:resLen(2)
                        resArrNew(c * resLen(1) + 1:resLen(1) * (c + 1), :) = resArr(:, j:j + 3);
                        c = c + 1;
                    end

                    dlmwrite(ConfFileName, resArrNew, '-append', 'delimiter', '\t');

                end

            end

            if obj.isDuplicateFig

                fig = graphics.Axs;

                if obj.FigureFileFormat == 1
                    h = figure;
                    set(h, 'units', 'normalized', 'outerposition', [0 0 1 1])
                    colormap(graphics.Clrmp);
                    h.CurrentAxes = copyobj([fig graphics.Clrbr], h);
                    h.Visible = 'on';
                else
                    set(fig, 'Units', 'pixel');
                    pos = fig.Position;
                    marg = 40;

                    if contParms.SingleOrMultipleCalc
                        rect = [-2 * marg, -marg, pos(3) + 2.5 * marg, pos(4) + 2 * marg];
                    else
                        rect = [-2 * marg, -1.5 * marg, pos(3) + 4.5 * marg, pos(4) + 2.5 * marg];
                    end

                    photo = getframe(fig, rect);
                    [photo, cmp] = frame2im(photo);
                    photoName = strcat(obj.ResPath, '\CAField');

                    switch obj.FigureFileFormat
                        case 2
                            imwrite(photo, jet(256), strcat(photoName, '.png'));
                        case 3
                            imwrite(photo, strcat(photoName, '.jpg'), 'jpg', 'Quality', 100);
                    end

                    set(fig, 'Units', 'normalized');
                end

            end

            resproc = obj;
        end

        function [filename] = SaveParms(obj, ca, contParms, param)
            ConfFileName = strcat('\Modeling-Params-', datestr(clock));
            ConfFileName = strcat(ConfFileName, '.txt');
            ConfFileName = strrep(ConfFileName, ':', '-');
            ConfFileName = strcat(obj.ResPath, ConfFileName);

            if contParms.SingleOrMultipleCalc
                fileID = fopen(ConfFileName, 'w');
                fprintf(fileID, '1\n');
                fprintf(fileID, strcat(num2str(ca.FieldType), '\n'));
                fprintf(fileID, strcat(num2str(ca.BordersType), '\n'));
                fprintf(fileID, strcat(num2str(ResultsProcessing.GetSetCellOrient), '\n'));
                fprintf(fileID, strcat(num2str(ca.N), '\n'));
                fprintf(fileID, strcat(func2str(ca.Base), '\n'));
                fprintf(fileID, strcat(func2str(ca.Lambda), '\n'));

                fprintf(fileID, strcat(num2str(ca.Zbase), '\n'));
                fprintf(fileID, strcat(num2str(ca.Miu0), '\n'));
                fprintf(fileID, strcat(num2str(ca.Miu), '\n'));

                if ~ischar(param) && param ~= 0
                    fprintf(fileID, strcat(num2str(param), '\n'));
                    paramStart = complex(contParms.ReRangeWindow(1), contParms.ImRangeWindow(1));
                    paramStep = (contParms.ReRangeWindow(2) - contParms.ReRangeWindow(1));
                    paramEnd = complex(contParms.ReRangeWindow(end), contParms.ImRangeWindow(end));

                    paramStartSrt = strcat(num2str(paramStart), ' :');
                    paramEndSrt = strcat(' :', num2str(paramEnd));
                    paramSrt = strcat(paramStartSrt, num2str(paramStep));
                    paramSrt = strcat(paramSrt, paramEndSrt);

                    fprintf(fileID, strcat(paramSrt, '\n'));
                    fclose(fileID);
                else

                    if ca.N ~= 1
                        fclose(fileID);
                        dlmwrite(ConfFileName, param, '-append', 'delimiter', '');
                    else
                        fprintf(fileID, strcat(num2str(ControlParams.GetSetMaxPeriod), '\n'));
                        fclose(fileID);
                    end

                end

                fileID = fopen(ConfFileName, 'a');
                PrecisionParms = ModelingParams.GetSetPrecisionParms;
                fprintf(fileID, strcat(num2str(PrecisionParms(1)), '\n'));
                fprintf(fileID, strcat(num2str(PrecisionParms(2)), '\n'));
                fclose(fileID);

            else
                fileID = fopen(ConfFileName, 'w');
                fprintf(fileID, '0\n');
                fprintf(fileID, strcat(num2str(ca.Zbase), '\n'));
                fprintf(fileID, strcat(func2str(contParms.ImageFunc), '\n'));
                fprintf(fileID, strcat(num2str(contParms.SingleParams(1)), '\n'));
                fprintf(fileID, strcat(num2str(contParms.SingleParams(2)), '\n'));
                fprintf(fileID, strcat(num2str(contParms.WindowParamName), '\n'));

                paramStart = complex(contParms.ReRangeWindow(1), contParms.ImRangeWindow(1));
                paramStep = complex(contParms.ReRangeWindow(2) - contParms.ReRangeWindow(1), contParms.ImRangeWindow(2) - contParms.ImRangeWindow(1));
                paramEnd = complex(contParms.ReRangeWindow(end), contParms.ImRangeWindow(end));

                paramStartSrt = strcat(num2str(paramStart), ' :');
                paramEndSrt = strcat(' :', num2str(paramEnd));
                paramSrt = strcat(paramStartSrt, num2str(paramStep));
                paramSrt = strcat(paramSrt, paramEndSrt);
                fprintf(fileID, strcat(paramSrt, '\n'));
                PrecisionParms = ModelingParams.GetSetPrecisionParms;
                mp = ControlParams.GetSetMaxPeriod;

                fprintf(fileID, strcat(num2str(PrecisionParms(1)), '\n'));
                fprintf(fileID, strcat(num2str(PrecisionParms(2)), '\n'));
                fprintf(fileID, strcat(num2str(mp), '\n'));
                fclose(fileID);
            end

            filename = ConfFileName;
        end

        function A = txt2Cell(obj)
            fileID = fopen(obj.Filename, 'r');
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

        function cell2Txt(obj, A)
            fileID = fopen(obj.Filename, 'w');

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

    end

    methods (Static)
        %%
        % ����� get-set ��� ������� �������� ������� (ColorMap) � �� ������ ����� ������ ����� ��������� colorbar ���� �� (VisualiseData)
        function [vData clrMap] = GetSetVisualizationSettings(settingS)
            persistent colorMap;
            persistent visualiseData;

            if nargin
                visualiseData = cell2mat(settingS(1));
                colorMap = cell2mat(settingS(2));
            end

            vData = visualiseData;
            clrMap = colorMap;
        end
        %%
        % ����� get-set ��� ������� �������� ������� (ColorMap) � ���� ������������ ���������� ����� (VisualiseData)
        function [vData clrMap] = GetSetPointsVisualizationSettings(settingS)
            persistent colorMap;
            persistent visualiseData;

            if nargin
                visualiseData = cell2mat(settingS(1));
                colorMap = cell2mat(settingS(2));
            end

            vData = visualiseData;
            clrMap = colorMap;
        end

        %%
        % ����� get-set ��� ����������� ���������� ���������� ������ (0-�� ������(�������), 1-������������, 2-��������������)
        function out = GetSetCellOrient(Cellorient)
            persistent CellOrientation;

            if nargin
                CellOrientation = Cellorient;
            end

            out = CellOrientation;
        end

        % ����� get-set ��� ����������� ���������� ���� ���� (1-��������������, 0-����������)
        function out = GetSetFieldOrient(Fieldorient)
            persistent FieldOrientation;

            if nargin
                FieldOrientation = Fieldorient;
            end

            out = FieldOrientation;
        end

        %%
        %����� ��������� ������ ��
        function out = DrawCell(CA_cell)

            if ResultsProcessing.GetSetFieldOrient

                if ResultsProcessing.GetSetCellOrient == 1
                    %% ��������� ������������� ��������� � �������������� ����
                    i = cast(CA_cell.Indexes(1, 1), 'double');
                    j = cast(CA_cell.Indexes(1, 2), 'double');
                    k = cast(CA_cell.Indexes(1, 3), 'double');
                    x0 = 0;
                    y0 = 0;

                    switch k

                        case 1

                            switch compareInt32(i, j)
                                case - 1
                                    y0 = -3/2 * (j - i);
                                case 0
                                    y0 = 0;
                                case 1
                                    y0 = 3/2 * (i - j);
                            end

                            x0 = (i + j) * sqrt(3) / 2;

                        case 2
                            x0 = -sqrt(3) / 2 * (i + (i - j));
                            y0 = 3/2 * j;

                        case 3
                            x0 = -sqrt(3) / 2 * (j + (j - i));
                            y0 = -3/2 * i;

                    end

                    dx = sqrt(3) / 2;
                    dy = 1/2;

                    x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                    y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                    patch(x_arr, y_arr, [CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ���������
                    %%
                else
                    %% ��������� ��������������� ��������� � �������������� ����
                    i = cast(CA_cell.Indexes(1, 1), 'double');
                    j = cast(CA_cell.Indexes(1, 2), 'double');
                    k = cast(CA_cell.Indexes(1, 3), 'double');
                    x0 = 0;
                    y0 = 0;

                    %                    %������ ������� ���������� ������������ ����
                    %                    switch k
                    %
                    %                        case 1
                    %                            y0=-sqrt(3)/2*(i+j);
                    %                            x0=3/2*(i-j);
                    %
                    %                        case 2
                    %                            y0=sqrt(3)/2*(i-(j-i));
                    %                            x0=3/2*j;
                    %
                    %                        case 3
                    %                            y0=sqrt(3)/2*(j-(i-j));
                    %                            x0=-3/2*(j-(j-i));
                    %
                    %                    end

                    %������ ������� ���������� ������������ ����
                    switch k

                        case 1

                            switch compareInt32(i, j)
                                case - 1
                                    x0 = -3/2 * (j - i);
                                case 0
                                    x0 = 0;
                                case 1
                                    x0 = 3/2 * (i - j);
                            end

                            y0 = (i + j) * sqrt(3) / 2;

                        case 2
                            y0 = -sqrt(3) / 2 * (i + (i - j));
                            x0 = 3/2 * j;

                        case 3
                            y0 = -sqrt(3) / 2 * (j + (j - i));
                            x0 = -3/2 * i;

                    end

                    dy = sqrt(3) / 2;
                    dx = 1/2;

                    x_arr = [x0 x0 + dx x0 x0 - (2 * dx) x0 - (3 * dx) x0 - (2 * dx)];
                    y_arr = [y0 y0 + dy y0 + 2 * (dy) y0 + 2 * (dy) y0 + dy y0];

                    patch(x_arr, y_arr, [CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ���������
                    %%
                end

            else

                switch ResultsProcessing.GetSetCellOrient

                    case 0
                        %% ��������� �������� � ���������� ����
                        x_arr = [CA_cell.Indexes(2) CA_cell.Indexes(2) + 1 CA_cell.Indexes(2) + 1 CA_cell.Indexes(2)];
                        y_arr = [(CA_cell.Indexes(1)) (CA_cell.Indexes(1)) (CA_cell.Indexes(1)) + 1 (CA_cell.Indexes(1)) + 1];

                        patch(x_arr, y_arr, [CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ��������
                        %%
                    case 1
                        %% ��������� ������������� ��������� � ���������� ����
                        x0 = cast(CA_cell.Indexes(1, 1), 'double'); % ���������� ���������� �� ��� x
                        y0 = cast(CA_cell.Indexes(1, 2), 'double'); % ���������� ���������� �� ��� y

                        %������ ����� ����� ��������� �� ������
                        if (x0)
                            x0 = x0 + (x0 * sqrt(3) - x0);
                        end

                        if (y0)

                            if mod(y0, 2)
                                x0 = x0 + sqrt(3) / 2;
                            end

                            y0 = y0 + (y0 * 1/2);
                        end

                        dx = sqrt(3) / 2;
                        dy = 1/2;

                        x_arr = [x0 x0 + dx x0 + dx x0 x0 - dx x0 - dx];
                        y_arr = [y0 y0 + dy y0 + 3 * dy y0 + 4 * dy y0 + 3 * dy y0 + dy];

                        patch(x_arr, y_arr, [CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ���������
                        %%
                    case 2
                        %% ��������� ��������������� ��������� � ���������� ����
                        x0 = cast(CA_cell.Indexes(1, 1), 'double'); % ���������� ���������� �� ��� x
                        y0 = cast(CA_cell.Indexes(1, 2), 'double'); % ���������� ���������� �� ��� y

                        %������ ����� ����� ��������� �� ������
                        if (y0)
                            y0 = y0 + (y0 * sqrt(3) - y0);
                        end

                        if (x0)

                            if mod(x0, 2)
                                y0 = y0 + sqrt(3) / 2;
                            end

                            x0 = x0 + (x0 * 1/2);
                        end

                        dy = sqrt(3) / 2;
                        dx = 1/2;

                        x_arr = [x0 x0 + dx x0 x0 - (2 * dx) x0 - (3 * dx) x0 - (2 * dx)];
                        y_arr = [y0 y0 + dy y0 + 2 * (dy) y0 + 2 * (dy) y0 + dy y0];

                        patch(x_arr, y_arr, [CA_cell.Color(1) CA_cell.Color(2) CA_cell.Color(3)]); % ��������� ���������
                        %%
                end

            end

            out = CA_cell;
        end

    end

end

function mustBeInRange(a, b)

    if any(a(:) < b(1)) || any(a(:) > b(2))
        error(['Value assigned to Color property is not in range ', ...
                num2str(b(1)), '...', num2str(b(2))])
    end

end

function res = compareInt32(a, b)

    if a > b
        res = 1;
    else

        if a < b
            res = -1;
        else
            res = 0;
        end

    end

end

function out = ComplexModule(compNum)
    out = sqrt(real(compNum) * real(compNum) + imag(compNum) * imag(compNum));
end
