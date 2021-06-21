classdef TestingScripts

    methods (Static)

        function test1()
            ca = struct;
            ca.FieldType = true;
            N = 5;
            Initializations.Z0RandRangeInit(0, 0, 0, 0, 0, N, ca)
        end

        function [isIntrnl, isIntrnlPlus, isCorner, isCornerAx, isEdge, isZero, isTrueCell, errorCellsInfo] = CheckNeighborsAndBorderType(CACell, n, fieldOrient, bordersType)

            isTrueCell = true;
            isIntrnl = false;
            isIntrnlPlus = false;
            isCorner = false;
            isCornerAx = false;
            isEdge = false;
            isZero = false;
            errorCellsInfo = {'+'};

            % тип границ (1-линия смерти, 2-замыкание границ, 3-закрытые границы )
            switch bordersType
                case 1
                    % статическая переменная типа поля (1-гексагональное, 0-квадратное)
                    if fieldOrient == 1

                        isEdge = length(CACell.CurrNeighbors) == 0 && (isequal(CACell.Indexes(1:2), [n - 1, n - 1]) || isequal(CACell.Indexes(1:2), [n - 1, 0]) || ((CACell.Indexes(1) == n - 1 && CACell.Indexes(2) < n - 1 && CACell.Indexes(2) > 0) || (CACell.Indexes(2) == n - 1 && CACell.Indexes(1) < n - 1 && CACell.Indexes(1) > 0)));

                        if isEdge
                            return;
                        end

                        if length(CACell.CurrNeighbors) == 6

                            %либо j=0 либо i=1
                            switch CACell.Indexes(3)

                                case 1
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 2;
                                    else
                                        neighborK = 3;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                case 2
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 3;
                                    else
                                        neighborK = 1;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);
                                case 3
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 1;
                                    else
                                        neighborK = 2;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                otherwise
                                    checkIntrnlDiffMatr = [[1, 0]; [1, 1]];
                                    isZero = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes(1:2) - CACell.Indexes(1:2)) == checkIntrnlDiffMatr, [1, 1], 'rows')), CACell.CurrNeighbors));

                            end

                            if isIntrnlPlus || isZero
                                return;
                            end

                            checkIntrnlDiffMatr = [[0, 1, 0]; [1, 0, 0]; [1, 1, 0]];
                            isIntrnl = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkIntrnlDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors));

                            if isIntrnl
                                return;
                            end

                        end
                    else
                        checkDiffMatr = [[0, 1, 0]; [1, 0, 0]];

                        if length(CACell.CurrNeighbors) > 0
                            isIntrnl = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 4 && (all(CACell.Indexes(1:2) < n - 1) && all(CACell.Indexes(1:2) > 0));
                        else
                            isEdge = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 0 && (any(CACell.Indexes(1:2) == n - 1) || any(CACell.Indexes(1:2) == 0));
                        end

                    end
                case 2
                    % статическая переменная типа поля (1-гексагональное, 0-квадратное)
                    if fieldOrient == 1
                        if length(CACell.CurrNeighbors) == 6

                            isCorner = (length(find(arrayfun(@(neighbor) isequal(CACell.Indexes(1:2) - neighbor.Indexes(1:2), [0, n - 1]), CACell.CurrNeighbors)))) == 3 && isequal(CACell.Indexes(1:2), [n - 1, n - 1]);

                            if isCorner
                                return;
                            end

                            isCornerAx = (length(find(arrayfun(@(neighbor) isequal(CACell.Indexes(1:2) - neighbor.Indexes(1:2), [0, -(n - 1)]), CACell.CurrNeighbors)))) == 3 && isequal(CACell.Indexes(1:2), [n - 1, 0]);

                            if isCornerAx
                                return;
                            end

                            isEdge = (length(find(arrayfun(@(neighbor) isequal((CACell.Indexes(1:2)-neighbor.Indexes(1:2)), [0, 0]) && CACell.Indexes(3) ~= neighbor.Indexes(3), CACell.CurrNeighbors)))) == 2 && ((CACell.Indexes(1) == n - 1 && CACell.Indexes(2) < n - 1 && CACell.Indexes(2) > 0) || (CACell.Indexes(2) == n - 1 && CACell.Indexes(1) < n - 1 && CACell.Indexes(1) > 0));

                            if isEdge
                                return;
                            end

                            %либо j=0 либо i=1
                            switch CACell.Indexes(3)

                                case 1
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 2;
                                    else
                                        neighborK = 3;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                case 2
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 3;
                                    else
                                        neighborK = 1;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);
                                case 3
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 1;
                                    else
                                        neighborK = 2;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                otherwise
                                    checkIntrnlDiffMatr = [[1, 0]; [1, 1]];
                                    isZero = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes(1:2) - CACell.Indexes(1:2)) == checkIntrnlDiffMatr, [1, 1], 'rows')), CACell.CurrNeighbors));

                            end

                            if isIntrnlPlus || isZero
                                return;
                            end

                            checkIntrnlDiffMatr = [[0, 1, 0]; [1, 0, 0]; [1, 1, 0]];
                            isIntrnl = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkIntrnlDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors));

                            if isIntrnl
                                return;
                            end

                        end

                        if (~any([isEdge, isCornerAx, isCorner, isIntrnlPlus, isZero, isIntrnl]))

                            errInf = strcat(strrep(num2str(CACell.Indexes), "  ", ""), "    ");
                            for i = 1:length(CACell.CurrNeighbors)
                                errInf = strcat(strrep(num2str(CACell.CurrNeighbors(i).Indexes), "  ", ""), "    ");
                            end
                            errorCellsInfo = {errInf};
                            isTrueCell = false;
                            return;
                        end

                    else
                        if length(CACell.CurrNeighbors) == 4

                            checkDiffMatr = [[0, 1, 0]; [1, 0, 0]; [0, n - 1, 0]; [n - 1, 0, 0]];
                            isTrueCell = length(find((arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors)))) == 4;

                            checkDiffMatr = [[0, 1, 0]; [1, 0, 0]; [0, n - 1, 0]; [n - 1, 0, 0]];
                            isIntrnl = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 4 && (all(CACell.Indexes(1:2) < n - 1) && all(CACell.Indexes(1:2) > 0));

                            if isTrueCell

                                checkDiffMatr = [[0, n - 1, 0]; [n - 1, 0, 0]];
                                isEdge = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes-CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 1 && ((any(CACell.Indexes(1:2) == n - 1) || any(CACell.Indexes(1:2) == 0)) && ~(all(CACell.Indexes(1:2) == n - 1) || all(CACell.Indexes(1:2) == 0) || abs(CACell.Indexes(1) - CACell.Indexes(2)) == n - 1));

                                isCorner = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 2 && (all(CACell.Indexes(1:2) == n - 1) || all(CACell.Indexes(1:2) == 0) || abs(CACell.Indexes(1) - CACell.Indexes(2)) == n - 1);

                            end

                        end
                    end
                case 3
                    % статическая переменная типа поля (1-гексагональное, 0-квадратное)
                    if fieldOrient == 1

                        isEdge = length(CACell.CurrNeighbors) == 4 && (((CACell.Indexes(1) == n - 1 && CACell.Indexes(2) < n - 1 && CACell.Indexes(2) > 0) || (CACell.Indexes(2) == n - 1 && CACell.Indexes(1) < n - 1 && CACell.Indexes(1) > 0)));

                        if isEdge
                            return;
                        end

                        isCorner = length(CACell.CurrNeighbors) == 3 && (isequal(CACell.Indexes(1:2), [n - 1, n - 1]) || isequal(CACell.Indexes(1:2), [n - 1, 0]));

                        if isCorner
                            return;
                        end

                        if length(CACell.CurrNeighbors) == 6

                            %либо j=0 либо i=1
                            switch CACell.Indexes(3)

                                case 1
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 2;
                                    else
                                        neighborK = 3;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                case 2
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 3;
                                    else
                                        neighborK = 1;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);
                                case 3
                                    neighborK = [];
                                    if CACell.Indexes(2) == 0
                                        neighborK = 1;
                                    else
                                        neighborK = 2;
                                    end
                                    isIntrnlPlus = any(arrayfun(@(neighbor) any((CACell.Indexes(2) - neighbor.Indexes(1)) == [-1, 0]) && any(abs(CACell.Indexes(1)-neighbor.Indexes(2)) == [1, 0]) && (neighbor.Indexes(3) == neighborK), CACell.CurrNeighbors)) && (CACell.Indexes(1) == 1 || CACell.Indexes(2) == 0);

                                otherwise
                                    checkIntrnlDiffMatr = [[1, 0]; [1, 1]];
                                    isZero = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes(1:2) - CACell.Indexes(1:2)) == checkIntrnlDiffMatr, [1, 1], 'rows')), CACell.CurrNeighbors));

                            end

                            if isIntrnlPlus || isZero
                                return;
                            end

                            checkIntrnlDiffMatr = [[0, 1, 0]; [1, 0, 0]; [1, 1, 0]];
                            isIntrnl = all(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkIntrnlDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors));

                            if isIntrnl
                                return;
                            end

                        end

                    else
                        checkDiffMatr = [[0, 1, 0]; [1, 0, 0]];

                        isIntrnl = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 4 && (all(CACell.Indexes(1:2) < n - 1) && all(CACell.Indexes(1:2) > 0));

                        isEdge = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes-CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 3 && ((any(CACell.Indexes(1:2) == n - 1) || any(CACell.Indexes(1:2) == 0)) && ~(all(CACell.Indexes(1:2) == n - 1) || all(CACell.Indexes(1:2) == 0) || abs(CACell.Indexes(1) - CACell.Indexes(2)) == n - 1));

                        isCorner = length(find(arrayfun(@(neighbor) any(ismember(abs(neighbor.Indexes - CACell.Indexes) == checkDiffMatr, [1, 1, 1], 'rows')), CACell.CurrNeighbors))) == 2 && (all(CACell.Indexes(1:2) == n - 1) || all(CACell.Indexes(1:2) == 0) || abs(CACell.Indexes(1) - CACell.Indexes(2)) == n - 1);
                    end

            end

        end

        function regexTesting()
            clear;
            clc;

            pattern = 'exp\(\s*i\s*\*\s*z\s*)';

            testStrs = [{'exp(i*z)'}, {'exp(i * z)'}, {'exp( i*z )'}, {'exp(i*z )'}, {'exp( i*z)'}, {'exp(  z  *  i  )'}];

            for ind = 1:length(testStrs)
                regexp(testStrs{ind}, pattern)
            end
        end

        function [z_eq] = CountZBaze(miu, z0)

            persistent funcStr
            persistent func

            if isempty(funcStr)
                funcStr = strcat('@(z)(', num2str(miu), ')* exp(i * z)');
                func = str2func(funcStr);
            end

            Fbase = func;

            mapz_zero = @(z) abs(Fbase(z)-z);
            mapz_zero_xy = @(z) mapz_zero(z(1)+i*z(2));
            [zeq, zer] = fminsearch(mapz_zero_xy, [real(z0), imag(z0)], optimset('TolX', 1e-9));
            z_eq = complex(zeq(1), zeq(2));
        end
        
        function drawBar()
            periods = xlsread('diagrams','I2:I76');
            nums = xlsread('diagrams','J2:J76');

            indxs = find(periods < 40);
            sortedPeriods = periods(indxs);
            sortedNums = nums(indxs);
            
            h = figure;
            h.Color = [1 1 1];
            b = bar(sortedPeriods,sortedNums,'BarWidth',1);
            ax = gca;
            ax.XGrid = 'off';
            ax.YGrid = 'on';
            xlabel('Уникальные периоды');
            ylabel('Количество');
        end

        function asyncTest()
            p = gcp();
            % To request multiple evaluations, use a loop.
            for idx = 1:10
                f(idx) = parfeval(p, @magic, 1, idx); % Square size determined by idx
            end
            % Collect the results as they become available.
            magicResults = cell(1, 10);
%             for idx = 1:10
%                 % fetchNext blocks until next results are available.
%                 [completedIdx, value] = fetchNext(f);
%                 magicResults{completedIdx} = value;
%                 fprintf('Got result with index: %d.\n', completedIdx);
%             end
            
            'hi im pasha'

        end
    end

end


% a=[];
%
% test=1;
% a=[a regexp('1','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$') ]
%
% test=-1;
% a=[a regexp('-1','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$') ]
%
% test=+1;
% a=[a regexp('+1','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=1i;
% a=[a regexp('1i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=+1i;
% a=[a regexp('+1i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=-1i;
% a=[a regexp('-1i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=1.5;
% a=[a regexp('1.5','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=+1.5;
% a=[a regexp('+1.5','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=-1.5i;
% a=[a regexp('-1.5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=-1i+1;
% a=[a regexp('-1i+1','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=+1+1i;
% a=[a regexp('+1+1i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=1+1.5i;
% a=[a regexp('1+1.5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=1.5+5i;
% a=[a regexp('1.5+5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=1.5+1.5i;
% a=[a regexp('1.5+1.5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=-1.5-1.5i;
% a=[a regexp('-1.5-1.5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=+1.5-1.5i;
% a=[a regexp('+1.5-1.5i','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=5i-1.5;
% a=[a regexp('5i-1.5','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% test=-5i-1.5;
% a=[a regexp('5i-1.5','^[-\+]?\d+(\.)?(?(1)\d+|)(i)?([-\+]\d+(\.)?((?<=\.)\d+|)(?(3)|i))?$')]
%
% all(a==1)


% Re=0:0.001:2;
% Im=0:0.001:2;
% Re=Re(randperm(length(Re)));
% Im=Im(randperm(length(Im)));
% compArr=arrayfun(@(re,im) complex(re,im),Re,Im);
% compArr=compArr';
% Im=Im';
% Re=Re';
%
% fieldType=true;
% N=5;
%
% coorditates=[];
% cellCount=0;
% formatSpec ='';
% if fieldType
%     cellCount=N*(N-1)*3;
%
%     i=1:N-1;
%     i=i';
%     i_old=i;
%     for c=1:(cellCount/(N-1))-1
%         i=[i;i_old];
%     end
%
%     j=ones(N*(N-1),1);
%     for c=0:N-1
%         j(1+((N-1)*c):(N-1)*(c+1),:)=c;
%     end
%     j_old=j;
%     j=[j;j_old];
%     j=[j;j_old];
%
%
%     k=ones(N*(N-1)*3,1);
%     k(1:(cellCount/3),:)=1;
%     k((cellCount/3)+1:(2*cellCount/3),:)=2;
%     k((2*cellCount/3)+1:cellCount,:)=3;
%
%     coorditates=[i j k];
%     coorditates=[[0 0 0];coorditates];
%     cellCount=cellCount+1;
%     coorditatesCells=arrayfun(@(i,j,k){[i j k]}, i',j',k');
%     formatSpec='%d %d %d %f %f\n';
% else
%     formatSpec='%d %d %f %f\n';
%     cellCount=N*N;
%     x=zeros(cellCount,1);
%     y=zeros(cellCount,1);
%
%     for i=0:N-1
%         x((i*N)+1:(i*N)+N+1)=i;
%     end
%     x=x(1:end-1);
%
%     for i=0:N-1
%         y(1+i:N:length(y))=i;
%     end
%     coorditates=[x y];
%     coorditatesCells=arrayfun(@(x,y){[x y 0]}, x',y');
% end
%
%
% Im=Im(1:cellCount,:);
% Re=Re(1:cellCount,:);
% Z0=[coorditates Re Im];
% Z0=Z0';
%
% fileID = fopen('sourceHex.txt', 'w');
% fprintf(fileID,formatSpec,Z0);
% fclose(fileID);
%
%
% M=[];
% fileID1 = fopen('sourceHex.txt', 'r');
% M=fscanf(fileID1,formatSpec,[4 cellCount]);%
% fclose(fileID1);
% M=M';
%
