classdef Port
    properties
        handle
        num
        type
        dimension
        sample_time
        hsh
    end

    methods
        function obj = Port(port, num)
            obj.handle = port;
            obj.num = num;
            obj.sample_time = SampleTime(Simulink.Block.getSampleTimes(port));
            obj.type = Port.get_type(get_param(port,'CompiledPortDataTypes'));
            obj.dimension = Dimension(get_param(port, 'CompiledPortDimensions'));
            obj.hsh = obj.hash();
        end

        function obj = update_bus(obj)
            disp("")
        end

        function str = print(obj)
            str = obj.hsh + " # " + sprintf('%0.13f', obj.handle) + " " + string(obj.num) + ":" + get_param(obj.handle, 'Name');
        end

        function hsh = hash(obj)
            hsh = obj.type + " " + obj.dimension.print() + " # " + obj.sample_time.print();
        end
    end
    
    methods(Static)
        function eq = equals(p1, p2)
            eq = p1.type == p2.type && Dimension.equals(p1.dimension, p2.dimension) && SampleTime.equals(p1.sample_time, p2.sample_time);
        end

        function type = get_type(type_field)
            if length(type_field.Inport) + length(type_field.Outport) ~= 1
                dips("a")
            end
            if length(type_field.Inport) == 1
                type = type_field.Inport{1};
                return
            end
            type = type_field.Outport{1};
        end
    end
end