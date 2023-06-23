classdef Interface
    properties
        inports = [];
        outports = [];
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
                obj.specialports = interface.specialports;
                obj.skip_interface = interface.skip_interface;
                obj.hsh = interface.hsh;
                return
            end
            obj.inports  = Port.compute_ports(subsystem, 'Inport');
            obj.outports = Port.compute_ports(subsystem, 'Outport');
            obj.specialports = [Port.compute_ports(subsystem, 'ActionPort'), Port.compute_ports(subsystem, 'EnablePort'), Port.compute_ports(subsystem, 'TriggerPort'), Port.compute_ports(subsystem, 'PMIOPort'), Port.compute_ports(subsystem, 'ResetPort')];

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

        function hash = unsorted_hash(obj)
            ip = obj.inports;
            op = obj.outports;
            sp = obj.specialports;
            ports = [Helper.get_hash(ip) Helper.get_hash(op) Helper.get_hash(sp)];
            hash = join(ports, Helper.first_level_divider);
        end

        function eq = is_equivalent(obj, other_obj)
            eq = strcmp(obj.hsh, other_obj.hsh);
        end

        function mapping = get_mapping(old, new)
            mapping = -1;
            if ~Helper.special_ports_equi(old.specialports, new.specialports)  || (~Helper.input_output_number_compability && (length(old.inports) ~= length(new.inports) || length(old.outports) ~= length(new.outports))) || (Helper.input_output_number_compability && (length(old.inports) < length(new.inports) || length(old.outports) > length(new.outports)))
                return
            end

            inmapping = Helper.get_one_mapping(new.inports, old.inports);
            outmapping = Helper.get_one_mapping(old.outports, new.outports);

            if isempty(inmapping) && ~isempty(old.inports) || isempty(outmapping) && ~isempty(new.outports)
                return
            end
            mapping = struct('inmapping', inmapping, 'outmapping', outmapping);
        end
    end


    methods (Static)
    end
end