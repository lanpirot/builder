classdef SampleTime
    properties
        sample_start
        sample_diff
    end

    methods
        function obj = SampleTime(time)
            obj.sample_diff = time.Value(1);
            obj.sample_start = time.Value(2);
        end

        function str = print(obj)
            str = string(obj.sample_start) + " " + string(obj.sample_diff);
        end
    end

    methods(Static)
        function eq = equals(t1, t2)
            eq = t1.sample_start == t2.sample_start && t1.sample_diff == t2.sample_diff;
        end
    end
end