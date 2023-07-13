classdef Port
    properties
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
            obj.num = num;
            obj.port_type = port_type;

            
            obj.skip_port = Port.check_if_bus(handle);
            
            if ~obj.skip_port
                obj.data_type = obj.get_datatype(handle);
                obj.dimensions = obj.get_dimensions(handle);
                obj.hsh = obj.hash();
                obj.hshpn = obj.hashplusname(handle);
            end
        end

        function is_special = is_special_port(obj)
            is_special = any(ismember(["ActionPort", "EnablePort", "TriggerPort", "PMIOPort", "ResetPort"], obj.port_type));
        end

        function type = get_datatype(obj, handle)
            if Helper.data_types
                if is_special_port(obj)
                    switch obj.port_type
                        case 'TriggerPort'
                            type = get_param(handle, 'OutputDataType');
                            %https://www.mathworks.com/help/simulink/slref/trigger.html
                        case 'PMIOPort'
                            type = Port.handle_pmio_port(handle, obj.num);
                        case 'ResetPort'
                            disp("")
                        otherwise
                            type = obj.port_type;
                    end
                    return
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
                    if strcmp(obj.port_type, "ActionPort") ||strcmp(obj.port_type, "PMIOPort")
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

        function hsh = hash(obj)
            if obj.is_special_port()
                hsh = obj.port_type;
            else
                hsh = obj.data_type;
            end
            hsh = hsh + Helper.third_level_divider + obj.dimensions.hash() + Helper.second_level_divider;
        end

        function hshpn = hashplusname(obj, handle)
            hshpn = obj.hsh + get_param(handle, 'Name');
        end
    end
    
    methods(Static)
        function type = handle_pmio_port(handle, num)
            parent = get_param(handle, 'parent');
            pc = get_param(parent, 'PortConnectivity');
            for i = 1:length(pc)
                port = pc(i);
                if startsWith(port.Type, 'LConn') || startsWith(port.Type, 'RConn')
                    num = num - 1;
                end
                if ~num
                    type = port.Type;
                    return
                end
            end
        end

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
            params = get_param(handle,'DialogParameters');
            if isfield(params, 'IsBusElementPort')
                is_bus = 1;
            end
            if Helper.dimensions && Dimensions.is_bus(get_param(handle, 'CompiledPortDimensions'))
                is_bus = 1;
            end
        end
    end
end