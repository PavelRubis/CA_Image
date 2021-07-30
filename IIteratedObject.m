classdef (Abstract, HandleCompatible) IIteratedObject % абстрактный итерированный объект

    properties (Abstract)
        % итерированна€ функци€
        IteratedFunc
        % словарь параметров итерированной функции
        FuncParams
        % строка итерированной функцией, в которую вставл€ютс€ параметры
        IteratedFuncStr
    end

    methods (Abstract)
        % итераци€ эволюции объекта
        [obj] = Iteration(obj)
        % фактический конструктор
        [obj] = Initialization(obj, handles)
        % проверка: продолжать ли текущий этап моделировани€
        [status] = GetModellingStatus(obj);
    end

end
