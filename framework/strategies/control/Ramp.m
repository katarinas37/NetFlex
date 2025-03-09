classdef Ramp < IControlStrategy
    % SimpleControl Implements a basic control strategy.
    
    methods
        function obj = Ramp(~)
        end

        function [controlSignal,obj] = execute(obj, rcvMessage, ~, ~, ~)
            % Simple control logic (e.g., just returning seq value)
            controlSignal = rcvMessage.seqNr;
        end
    end
end