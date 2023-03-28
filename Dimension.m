classdef Dimension
    properties
        num_dimensions
        dimensions
    end

    methods
        function obj = Dimension(dims)
            if isempty(dims.Inport)
                dims = dims.Outport;
            else
                dims = dims.Inport;
            end
            obj.num_dimensions = length(dims);
            obj.dimensions = dims;
        end

        function str = print(obj)
            str = string(obj.num_dimensions);
            for i = 1:length(obj.dimensions)
                str = str + " " + string(obj.dimensions(i));
            end
        end
    end

    methods (Static)
        function eq = equals(d1, d2)
            eq = 0;
            if d1.num_dimensions ~= d2.num_dimensions
                return
            end
            for i = 1:length(d1)
                if d1(i) ~= d2(i)
                    return
                end
            end
            eq = 1;
        end
    end
end