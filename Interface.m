classdef Interface
    properties
        handle
        inports = [];
        outports = [];
    end
    methods
        function obj = Interface(model, subsystem)
            obj.handle = subsystem;

            inputs = find_system(subsystem, 'FindAll','On', 'LookUnderMasks','on', 'SearchDepth',1, 'BlockType','Inport');
            outputs = find_system(subsystem, 'FindAll','On', 'LookUnderMasks','on', 'SearchDepth',1, 'BlockType','Outport');
            for i = 1:length(inputs)
                obj.inports = [obj.inports Port(inputs(i), i)];
            end
            obj.inports = helper.sort_by_field(obj.inports, 'hsh');
            for i = 1:length(outputs)
                obj.outports = [obj.outports Port(outputs(i), i)];
            end
            obj.outports = helper.sort_by_field(obj.outports, 'hsh');
        end

        function obj = update_busses(obj)
            if strcmp(get_param(obj.handle, 'Name'), 'Subsystem')
                disp("")
            end
            tmp_inports = [];
            for i = 1:length(obj.inports)
                tmp_inports = [tmp_inports obj.inports(i).update_bus()];
            end
            obj.inports = helper.sort_by_field(tmp_inports, 'hsh');
            tmp_outports = [];
            for i = 1:length(obj.outports)
                tmp_outports = [tmp_outports obj.outports(i).update_bus()];
            end
            obj.outports = helper.sort_by_field(tmp_outports, 'hsh');
        end

        function str = print(obj)
            str = sprintf('%0.13f', obj.handle) + " " + get_param(obj.handle, 'Name') + newline;
            for i = 1:length(obj.inports)            
                str = str + obj.inports(i).print() + newline;
            end
            str = str + "=======================" + newline;
            for i = 1:length(obj.outports)            
                str = str + obj.outports(i).print() + newline;
            end
        end

        function hash = hash(obj)
            hash = "";
            for i = 1:length(obj.inports)            
                hash = hash + obj.inports(i).hsh;
            end
            hash = hash + "==";
            for i = 1:length(obj.outports)            
                hash = hash + obj.outports(i).hsh;
            end
        end
    end


    methods (Static)
        function eq = equals(i1, i2)
            eq = length(i1.inports) == length(i2.inports) && length(i1.outports) == length(i2.outports);
            if ~eq
                return
            end
            for i = 1:length(i1.inports)
                if ~Port.equals(i1.inports(i), i2.inports(i))
                    eq = 0;
                    return
                end
            end
            for i = 1:length(i1.outports)
                if ~Port.equals(i1.outports(i), i2.outports(i))
                    eq = 0;
                    return
                end
            end
        end
    end
end