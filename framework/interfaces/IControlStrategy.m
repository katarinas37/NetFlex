classdef (Abstract) IControlStrategy
    % IControlStrategy Abstract class for different control execution strategies.
    %
    % This interface defines the structure for all control strategies in the 
    % networked control system. Any control strategy that inherits from this 
    % class must implement the `execute` method.
    %
    % Methods:
    %   - execute(rcvMsg, delayedSignals, ncsPlant) : Computes the control signal.
      
    methods (Abstract)
        % execute Computes the control signal based on the received message and system state.
        %
        % This method is an abstract definition that must be implemented in any subclass.
        %
        % Inputs:
        %   - rcvMsg (NetworkMsg) : Received network message containing system state.
        %   - delayedSignals (double array) : Past control signals for delay compensation (if applicable).
        %   - ncsPlant (NcsPlant) : The networked control system plant.
        %
        % Outputs:
        %   - controlSignal (double) : Computed control input.

        controlSignal = execute(obj, rcvMsg, delayedSignals, ncsPlant);
    end
end