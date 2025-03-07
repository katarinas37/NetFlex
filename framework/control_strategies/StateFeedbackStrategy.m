classdef StateFeedbackStrategy < IControlStrategy
    
    methods
        function controlSignal = execute(~, rxData, controlParams, ncsPlant, ~)
            % Simple control logic (e.g., just returning seq value)
            % Check if controlParams.k size is ncsPlant.n * ncsPlant.m
            assert(isequal(size(controlParams.k), [ncsPlant.inputSize, ncsPlant.stateSize]), ...
                'Size of controlParams.k must be %d x %d', ncsPlant.inputSize, ncsPlant.stateSize);
            controlSignal = controlParams.k * rxData.data.';
        end
    end
end