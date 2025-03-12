classdef StateFeedbackStrategy < IControlStrategy
    % StateFeedbackStrategy Implements a standard state feedback control strategy.
    %
    % This strategy applies a predefined state feedback gain matrix to compute 
    % the control signal based on the received system state.
    %
    % Methods:
    %   - StateFeedbackStrategy() : Constructor (no initialization needed).
    %   - execute(rcvMsg, controlParams, ncsPlant) : Computes the control signal.
    %
    % See also: IControlStrategy, NetworkNode
    methods
        function obj = StateFeedbackStrategy(~)
            % StateFeedbackStrategy Constructor for the control strategy.
            %
            % This constructor does not require any initialization, as the state 
            % feedback strategy is purely based on the received system state.
        end

        function [controlSignal,obj] = execute(obj, rcvMsg, controlParams, ncsPlant, ~)
            % execute Computes the control signal using state feedback.
            %
            % This method applies the predefined control gain matrix `k` to 
            % compute the control signal based on the received system state.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Received message containing system state.
            %   - controlParams (struct) : Control parameters containing the gain matrix.
            %   - ncsPlant (NcsPlant) : The networked control system plant.
            %
            % Outputs:
            %   - controlSignal (double) : Computed control input.
            %   - obj (StateFeedbackStrategy) : Strategy object (unchanged).

            % Validate that control gain matrix `k` has correct dimensions
            assert(isequal(size(controlParams.k), [ncsPlant.inputSize, ncsPlant.stateSize]), ...
                'Size of controlParams.k must be %d x %d', ncsPlant.inputSize, ncsPlant.stateSize);
            
            % Compute control signal using state feedback
            controlSignal = -controlParams.k * rcvMsg.data;
        end
    end
end