classdef (Abstract) IControlStrategy
    % IControlStrategy Abstract class for different control execution strategies.
    
    methods (Abstract)
        controlSignal = execute(obj, rcvMsg, delayedSignals, ncsPlant);
    end
end