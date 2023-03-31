classdef Interface
    properties
        inports = [];
        outports = [];
        has_busses = 0;
        empty_interface = 0;
    end
    methods
        function obj = Interface(subsystem)
            obj.inports = Port.compute_ports(subsystem, 'Inport', obj.inports);
            obj.outports = Port.compute_ports(subsystem, 'Outport', obj.outports);
            if isfloat(obj.inports) && ~isempty(obj.inports) && obj.inports == -1 || isfloat(obj.outports) && ~isempty(obj.outports) && obj.outports == -1
                obj.has_busses = 1;
            end
            if length(obj.inports) + length(obj.outports) == 0
                obj.empty_interface = 1;
            end
        end

        function obj = update_busses(obj)
            % tmp_inports = [];
            % for i = 1:length(obj.inports)
            %     tmp_inports = [tmp_inports obj.inports(i).update_bus(obj.model)];
            % end
            % obj.inports = helper.sort_by_field(tmp_inports, 'hsh');
            % tmp_outports = [];
            % for i = 1:length(obj.outports)
            %     tmp_outports = [tmp_outports obj.outports(i).update_bus(obj.model)];
            % end
            % obj.outports = helper.sort_by_field(tmp_outports, 'hsh');
        end

        function str = print(obj)
            str = sprintf('%0.13f', obj.handle) + " " + get_param(obj.handle, 'Name') + newline;
            if obj.has_busses
                str = str + "Subsystem has busses as inputs or outputs" + newline;
                return
            end
            for i = 1:length(obj.inports)            
                str = str + obj.inports(i).print() + newline;
            end
            if obj.empty_interface
                str = str + "Subsystem has empty interface" + newline;
            else
                str = str + "=======================" + newline;
            end
            for i = 1:length(obj.outports)            
                str = str + obj.outports(i).print() + newline;
            end
        end

        function hash = hash(obj)
            hash = "";
            for i = 1:length(obj.inports)            
                hash = hash + obj.inports(i).hsh + ";";
            end
            if ~obj.empty_interface
                hash = hash + "==";
            end
            for i = 1:length(obj.outports)            
                hash = hash + obj.outports(i).hsh + ";";
            end
        end

        function eq = same_as(obj, other_obj)
            eq = strcmp(obj.hash(), other_obj.hash());
        end
    end


    methods (Static)
    end
end