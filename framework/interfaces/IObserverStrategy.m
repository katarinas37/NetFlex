classdef (Abstract) IObserverStrategy
    % IControlStrategy Abstract class for different observer execution strategies.
    
    methods (Abstract)
        estimates = execute(obj, rcvMsg, delayedSignals, ncsPlant);
    end
end