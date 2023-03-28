classdef Dimensions
    properties
        dimensions = {};
    end

    methods
        function obj = Dimensions(dims)
            if isempty(dims.Inport)
                dims = dims.Outport;
            else
                dims = dims.Inport;
            end
            if dims(1) < 0
                dims = dims(2:end);
            end
            i = 0;
            while ~isempty(dims)
                di = dims(1);
                obj.dimensions{end + 1} = dims(2:dims(1)+1);

                i = i+1;
                dims = dims(dims(1) + 2:end);
            end
        end

        function str = print(obj)
            str = "";
            for i = 1:length(obj.dimensions)
                str = str + " " + join(string(obj.dimensions{i}), ",");
            end
        end
    end

    methods (Static)
        function ibu = is_bus(dims)
            if isempty(dims.Inport)
                dims = dims.Outport;
            else
                dims = dims.Inport;
            end
            ibu = dims(1) < 0;
        end

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