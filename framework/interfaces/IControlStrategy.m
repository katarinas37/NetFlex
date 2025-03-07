classdef (Abstract) IControlStrategy
    % IControlStrategy Abstract class for different control execution strategies.
    
    methods (Abstract)
        controlSignal = execute(obj, rxData, delayedSignals, ncsPlant);
    end
end