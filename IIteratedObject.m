classdef (Abstract, HandleCompatible) IIteratedObject % ����������� ������������� ������

    properties (Abstract)
        % ������������� �������
        IteratedFunc
        % ������� ���������� ������������� �������
        FuncParams
        % ������ ������������� ��������, � ������� ����������� ���������
        IteratedFuncStr
    end

    methods (Abstract)
        % �������� �������� �������
        [obj] = Iteration(obj)
        % ����������� �����������
        [obj] = Initialization(obj, handles)
        % ��������: ���������� �� ������� ���� �������������
        [status] = GetModellingStatus(obj);
    end

end
