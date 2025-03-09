classdef StateFeedbackStrategy < IControlStrategy

    methods
        function obj = StateFeedbackStrategy(~)
        end
        function [controlSignal,obj] = execute(obj, rcvMsg, controlParams, ncsPlant, ~)
            % Simple control logic (e.g., just returning seq value)
            % Check if controlParams.k size is ncsPlant.n * ncsPlant.m
            assert(isequal(size(controlParams.k), [ncsPlant.inputSize, ncsPlant.stateSize]), ...
                'Size of controlParams.k must be %d x %d', ncsPlant.inputSize, ncsPlant.stateSize);
            
            controlSignal = controlParams.k * rcvMsg.data.';
        end
    end
end