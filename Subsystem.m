classdef Subsystem
    properties
        handle
        model
        interface
    end
    
    methods
        function obj = Subsystem(model, subsystem)
            obj.handle = subsystem;
            obj.model = model;
            obj.interface = Interface(subsystem);
        end

        function hsh = hash(obj)
            hsh = obj.interface.hash();
        end
    end
end