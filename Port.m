classdef Port
    properties
        handle
        num
        type
        dimensions
        sample_time
        hsh
    end

    methods
        function obj = Port(port, num)
            if Dimensions.is_bus(get_param(port, 'CompiledPortDimensions'))
                obj.handle = -1;
                return
            end


            obj.handle = port;
            obj.num = num;


            obj.dimensions = Dimensions(get_param(port, 'CompiledPortDimensions'));
            % if length(obj.dimensions.dimensions) > 1
            %     disp(obj.dimensions.print())
            %     disp(get_param(port, 'CompiledSampleTime'))
            %     if height(get_param(port, 'CompiledSampleTime')) > 1
            %         disp("")
            %     end
            %     disp(get_param(port,'CompiledPortDataTypes'))
            %     disp("")
            % end

            obj.sample_time = SampleTime(get_param(port, 'CompiledSampleTime'));
            obj.type = Port.get_type(get_param(port,'CompiledPortDataTypes'));
            obj.hsh = obj.hash();
        end

        function obj = update_bus(obj, model)
            % if length(obj.dimensions.dimensions) > 1
            %     tmp_obj = obj;
            %     obj = [];
            %     tmp_dims = tmp_obj.dimension.dimensions(2:end);
            %     be = Simulink.Bus.createObject(model, tmp_obj.handle);
            %     i = 1;
            %     while ~isempty(tmp_dims)
            %         new_dims = tmp_dims(1:tmp_dims(1)+1);
            %         tmp_dims = tmp_dims(tmp_dims(1)+2:end);
            %         new_type = be.elemAttributes(i).Attribute.DataType;
            % 
            % 
            %         obj = [obj Port()];
            %         i = i+1;
            %     end
            % end
        end

        function str = print(obj)
            str = obj.hsh + " # " + sprintf('%0.13f', obj.handle) + " " + string(obj.num) + ":" + get_param(obj.handle, 'Name');
        end

        function hsh = hash(obj)
            hsh = obj.type + " " + obj.dimensions.print() + " # " + obj.sample_time.print();
        end
    end
    
    methods(Static)
        function eq = equals(p1, p2)
            eq = p1.type == p2.type && Dimensions.equals(p1.dimension, p2.dimension) && SampleTime.equals(p1.sample_time, p2.sample_time);
        end

        function ports = compute_ports(subsystem, search_string, ports)
            port_handles = find_system(subsystem, 'FindAll','On', 'LookUnderMasks','on', 'SearchDepth',1, 'BlockType',search_string);
            for i = 1:length(port_handles)
                next_port = Port(port_handles(i), i);
                if next_port.handle == -1
                    ports = -1;
                    return
                end
                ports = [ports next_port];
            end
            ports = helper.sort_by_field(ports, 'hsh');
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