classdef Ramp < IControlStrategy
    % SimpleControl Implements a basic control strategy.
    
    methods
        function controlSignal = execute(~, receivedMsg, ~, ~)
            % Simple control logic (e.g., just returning seqNrvalue)
            controlSignal = receivedMsg.seqNr;
        end
    end
end