classdef Interface
    properties
        handle
        inports = {};
        outports = {};
    end
    methods
        function obj = Interface(subsystem)
            obj.handle = subsystem;

            inputs = find_system(subsystem, 'FindAll','On', 'LookUnderMasks', 'on', 'SearchDepth',1, 'BlockType','Inport');
            outputs = find_system(subsystem, 'FindAll','On', 'LookUnderMasks', 'on', 'SearchDepth',1, 'BlockType','Outport');
            for i = 1:length(inputs)
                obj.inports{end + 1} = Port(inputs(i), i);
            end
            for i = 1:length(outputs)
                obj.outports{end + 1} = Port(outputs(i), i);
            end
        end

        function print(obj)
            disp(sprintf('%0.13f', obj.handle) + " " + get_param(obj.handle, 'Name'))
            for i = 1:length(obj.inports)            
                disp(obj.inports{i}.print())
            end
            disp("=======================")
            for i = 1:length(obj.outports)            
                disp(obj.outports{i}.print())
            end
        end

        function hash = hash(obj)
            hash = "";
        end
    end
    methods (Static)
        function eq = equals(i1, i2)
            eq = length(i1.inports) == length(i2.inports) && length(i1.outports) == length(i2.outports);
            if ~eq
                return
            end
            for i = 1:length(i1.inports)
                if ~Port.equals(i1.inports{i}, i2.inports{i})
                    eq = 0;
                    return
                end
            end
            for i = 1:length(i1.outports)
                if ~Port.equals(i1.outports{i}, i2.outports{i})
                    eq = 0;
                    return
                end
            end
        end
    end
end