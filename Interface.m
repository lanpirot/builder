classdef Interface
    properties
        inports = [];
        outports = [];
        mapping = struct;
        specialports = [];
        skip_interface = 0;
        hsh
    end
    methods
        function obj = Interface(subsystem)
            if isstruct(subsystem)% getting called from ModelBuilder
                interface = subsystem;
                obj.inports = interface.inports;%for more detail Port() each port
                obj.outports = interface.outports;
                obj.mapping = interface.mapping;
                obj.specialports = interface.specialports;
                obj.skip_interface = interface.skip_interface;
                obj.hsh = interface.hsh;
                return
            end
            [obj.inports, obj.mapping.in_mapping]  = Port.compute_ports(subsystem, 'Inport');
            [obj.outports, obj.mapping.out_mapping] = Port.compute_ports(subsystem, 'Outport');
            obj.specialports = [Port.compute_ports(subsystem, 'ActionPort'), Port.compute_ports(subsystem, 'EnablePort'), Port.compute_ports(subsystem, 'TriggerPort')];

            if isfloat(obj.inports) && ~isempty(obj.inports) && obj.inports == -1 || isfloat(obj.outports) && ~isempty(obj.outports) && obj.outports == -1
                obj.skip_interface = 1;
            else
                obj.hsh = obj.hash();
            end
        end

        function obj = update_busses(obj)
            % tmp_inports = [];
            % for i = 1:length(obj.inports)
            %     tmp_inports = [tmp_inports obj.inports(i).update_bus(obj.model)];
            % end
            % obj.inports = Helper.sort_by_field(tmp_inports, 'hsh');
            % tmp_outports = [];
            % for i = 1:length(obj.outports)
            %     tmp_outports = [tmp_outports obj.outports(i).update_bus(obj.model)];
            % end
            % obj.outports = Helper.sort_by_field(tmp_outports, 'hsh');
        end

        function hash = hash(obj)
            ip = Helper.sort_by_field(obj.inports, 'hsh');
            op = Helper.sort_by_field(obj.outports, 'hsh');
            sp = Helper.sort_by_field(obj.specialports, 'hsh');
            ports = [Helper.get_hash(ip) Helper.get_hash(op) Helper.get_hash(sp)];
            hash = join(ports, Helper.first_level_divider);
        end

        function eq = is_equivalent(obj, other_obj)
            eq = strcmp(obj.hsh, other_obj.hsh);
        end
    end


    methods (Static)
    end
end