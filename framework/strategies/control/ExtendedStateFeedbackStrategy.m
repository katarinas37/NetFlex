classdef ExtendedStateFeedbackStrategy < IControlStrategy
    % ExtendedStateFeedbackStrategy Implements a state feedback control strategy
    % with extended state variables including delayed control signals.
    %
    % This strategy constructs a **lifted state** representation by appending 
    % past control signals to the current state. The controller then applies 
    % a feedback gain to compute the control signal.
    %
    % Properties:
    %   - delayedControlSignals (double array) : Stores past control signals for delay compensation.
    %
    % Methods:
    %   - ExtendedStateFeedbackStrategy(ncsPlant) : Constructor.
    %   - execute(rcvMsg, controlParams, ncsPlant) : Computes the control signal.
    %
    % See also: IControlStrategy, NetworkNode    
    properties
        delayedControlSignals double % Delayed control signals
    end

    methods
        function obj = ExtendedStateFeedbackStrategy(ncsPlant)
            % ExtendedStateFeedbackStrategy Constructor for the control strategy.
            %
            % Initializes the delayed control signal buffer based on the delay steps 
            % of the networked control system.
            %
            % Inputs:
            %   - ncsPlant (NcsPlant) : The networked control system plant.
            %
            % Example usage:
            %   controlStrategy = ExtendedStateFeedbackStrategy(ncsPlant);
            
            % Initialize buffer for past control signals (set to zero initially)
            obj.delayedControlSignals = zeros(ncsPlant.delaySteps, 1);
        end

        function [controlSignal,obj] = execute(obj, rcvMsg, controlParams, ncsPlant, ~)
            % execute Computes the control signal based on the received state.
            %
            % This method constructs a **lifted state** that includes both the 
            % current system state and past control signals. It then applies 
            % the predefined control gain to compute the control output.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Received message containing system state.
            %   - controlParams (struct) : Control parameters containing the gain matrix.
            %   - ncsPlant (NcsPlant) : The networked control system plant.
            %
            % Outputs:
            %   - controlSignal (double) : Computed control input.
            %   - obj (ExtendedStateFeedbackStrategy) : Updated object with new delayed control signals.
            %
            % Example usage:
            %   controlSignal = controlStrategy.execute(rcvMsg, controlParams, ncsPlant);

            % Validate that control gain matrix `k` has correct dimensions
            assert(isequal(size(controlParams.k), [ncsPlant.inputSize, ncsPlant.stateSize + ncsPlant.delaySteps]), ...
                'Size of controlParams.k must be %d x %d', ncsPlant.inputSize, ncsPlant.stateSize + ncsPlant.delaySteps);

            % Compute the control signal using the feedback gain
            liftedState = [rcvMsg.data(:); obj.delayedControlSignals];

            controlSignal = controlParams.k * liftedState;
            obj.delayedControlSignals = [controlSignal; obj.delayedControlSignals(1:end-1)];
        end
    end
end