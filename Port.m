classdef Port
    properties
        handle
        num
        port_type
        data_type
        dimensions
        sample_time
        hsh
        hshpn

        is_special_port = 0;
        is_bus = 0
    end

    methods
        function obj = Port(port, num, port_type)
            obj.handle = port;
            obj.num = num;
            obj.port_type = port_type;

            obj.sample_time = obj.get_sample_time();

            
            obj = obj.check_if_bus();
            
            if ~obj.is_bus
                obj.is_special_port = any(ismember(["ActionPort", "EnablePort", "TriggerPort"], obj.port_type));
                obj.dimensions = obj.get_dimensions();
                obj.data_type = obj.get_datatype();
                obj.hsh = obj.hash();
                obj.hshpn = obj.hashplusname();
            end
        end

        function obj = check_if_bus(obj)
            if Helper.dimensions && Dimensions.is_bus(get_param(obj.handle, 'CompiledPortDimensions'))
                obj.handle = -1;
                obj.is_bus = 1;
            end
        end

        function sample_time = get_sample_time(obj)
            if Helper.sample_times
                sample_time = SampleTime(get_param(obj.handle, 'CompiledSampleTime'));
            else
                sample_time = SampleTime();
            end
        end

        function type = get_datatype(obj)
            if Helper.data_types
                if obj.is_special_port
                    type = obj.port_type;
                    %get Data Type of TriggerPort https://www.mathworks.com/help/simulink/slref/trigger.html    
                else
                    if Dimensions.is_bus(get_param(obj.handle, 'CompiledPortDimensions'))
                        obj.handle = -1;
                        return
                    end
                    type = Port.get_type(get_param(obj.handle,'CompiledPortDataTypes'));
                end
            else
                type = '';
            end
        end

        function dims = get_dimensions(obj)
            if Helper.dimensions
                if obj.is_special_port
                    if strcmp(obj.data_type, "ActionPort")
                        dims = Dimensions([]);
                    else
                        dims = Dimensions(get_param(obj.handle, 'PortDimensions'));
                    end
    
                else
                    try
                        dims = Dimensions(get_param(obj.handle, 'CompiledPortDimensions'));
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

        function str = print(obj)
            str = obj.hsh + " # " + sprintf('%0.13f', obj.handle) + " " + string(obj.num) + ":" + get_param(obj.handle, 'Name');
        end

        function hsh = hash(obj)
            hsh = obj.data_type + " " + obj.dimensions.print() + " # " + obj.sample_time.print();
        end

        function hshpn = hashplusname(obj)
            hshpn = obj.data_type + " " + obj.dimensions.print() + " # " + obj.sample_time.print() + get_param(obj.handle, 'Name');
        end
    end
    
    methods(Static)
        function [ports, sortIDx] = compute_ports(subsystem, search_string, ports)
            port_handles = Helper.find_ports(subsystem, search_string);
            
            for i = 1:length(port_handles)
                next_port = Port(port_handles(i), i, search_string);
                if next_port.handle == -1
                    ports = -1;
                    sortIDx = -1;
                    return
                end
                ports = [ports next_port];
            end
            [ports, sortIDx] = Helper.sort_by_field(ports, 'hshpn');
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