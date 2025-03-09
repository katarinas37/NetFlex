classdef ExtendedStateFeedbackStrategy < IControlStrategy
    
    properties
        delayedControlSignals double % Delayed control signals
    end

    methods
        function obj = ExtendedStateFeedbackStrategy(ncsPlant)
            % Constructor for ExtendedStateFeedbackStrategy
            obj.delayedControlSignals = zeros(ncsPlant.delaySteps, 1);
        end

        function [controlSignal,obj] = execute(obj, rcvMsg, controlParams, ncsPlant, ~)
            % Simple control logic (e.g., just returning seq value)
            % Check if controlParams.k size is ncsPlant.n * ncsPlant.m
            assert(isequal(size(controlParams.k), [ncsPlant.inputSize, ncsPlant.stateSize + ncsPlant.delaySteps]), ...
                'Size of controlParams.k must be %d x %d', ncsPlant.inputSize, ncsPlant.stateSize + ncsPlant.delaySteps);

            % Construct lifted states
            liftedState = [rcvMsg.data(:); obj.delayedControlSignals];

            controlSignal = controlParams.k * liftedState;
            obj.delayedControlSignals = [controlSignal; obj.delayedControlSignals(1:end-1)];
        end
    end
end