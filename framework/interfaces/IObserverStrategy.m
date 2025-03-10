classdef (Abstract) IObserverStrategy
    % IObserverStrategy Abstract class for different observer execution strategies.
    %
    % This interface defines the structure for all observer strategies in the 
    % networked control system. Any observer strategy that inherits from this 
    % class must implement the `execute` method.
    %
    % Methods:
    %   - execute(rcvMsg, delayedSignals, ncsPlant) : Computes the estimated system states.
    
    methods (Abstract)
         % execute Computes the estimated system states based on the received message.
        %
        % This method is an abstract definition that must be implemented in any subclass.
        %
        % Inputs:
        %   - rcvMsg (NetworkMsg) : Received network message containing system measurements.
        %   - delayedSignals (double array) : Past control signals or previous estimates for delay compensation.
        %   - ncsPlant (NcsPlant) : The networked control system plant.
        %
        % Outputs:
        %   - estimates (double array) : Estimated states of the system.

        estimates = execute(obj, rcvMsg, delayedSignals, ncsPlant);
    end
end