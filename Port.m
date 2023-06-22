classdef Port
    properties
        handle
        num
        port_type
        data_type
        dimensions

        skip_port = 0
        hsh
        hshpn
    end

    methods
        function obj = Port(handle, num, port_type)
            obj.handle = handle;
            obj.num = num;
            obj.port_type = port_type;

            
            obj.skip_port = Port.check_if_bus(handle);
            
            if ~obj.skip_port
                obj.dimensions = obj.get_dimensions(handle);
                obj.data_type = obj.get_datatype(handle);
                obj.hsh = obj.hash();
                obj.hshpn = obj.hashplusname();
            end
        end

        function is_special = is_special_port(obj)
            is_special = any(ismember(["ActionPort", "EnablePort", "TriggerPort"], obj.port_type));
        end

        function type = get_datatype(obj, handle)
            if Helper.data_types
                if is_special_port(obj)
                    type = obj.port_type;
                    %get Data Type of TriggerPort https://www.mathworks.com/help/simulink/slref/trigger.html    
                else
                    if Dimensions.is_bus(get_param(handle, 'CompiledPortDimensions'))
                        obj.skip_port = 1;
                        return
                    end
                    type = Port.get_type(get_param(handle,'CompiledPortDataTypes'));
                end
            else
                type = '';
            end
        end

        function dims = get_dimensions(obj, handle)
            if Helper.dimensions
                if is_special_port(obj)
                    if strcmp(obj.data_type, "ActionPort")
                        dims = Dimensions([]);
                    else
                        dims = Dimensions(get_param(handle, 'PortDimensions'));
                    end
    
                else
                    try
                        dims = Dimensions(get_param(handle, 'CompiledPortDimensions'));
                    catch
                        disp("")
                    end
                end
            else
                dims = Dimensions();
            end
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

        function hsh = hash(obj)
            if obj.is_special_port()
                hsh = obj.port_type;
            else
                hsh = obj.data_type;
            end
            hsh = hsh + Helper.third_level_divider + obj.dimensions.hash() + Helper.second_level_divider;
        end

        function hshpn = hashplusname(obj)
            hshpn = obj.hsh + get_param(obj.handle, 'Name');
        end
    end
    
    methods(Static)
        function ports = compute_ports(subsystem, search_string)
            ports = [];
            port_handles = Helper.find_ports(subsystem, search_string);
            
            for i = 1:length(port_handles)
                next_port = Port(port_handles(i), i, search_string);
                if next_port.skip_port
                    ports = -1;
                    return
                end
                ports = [ports next_port];
            end
            %port_copy = ports;
            %[ports, sortIDx] = Helper.sort_by_field(ports, 'hshpn');
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


        function is_bus = check_if_bus(handle)
            is_bus = 0;
            if Helper.dimensions && Dimensions.is_bus(get_param(handle, 'CompiledPortDimensions'))
                is_bus = 1;
            end
        end
    end
end