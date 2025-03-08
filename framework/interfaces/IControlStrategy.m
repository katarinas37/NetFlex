classdef (Abstract) IControlStrategy
    % IControlStrategy Abstract class for different control execution strategies.
    
    methods (Abstract)
        controlSignal = execute(obj, receivedMsg, delayedSignals, ncsPlant);
    end
end