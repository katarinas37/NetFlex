classdef SimpleControlStrategy < IControlStrategy
    % SimpleControl Implements a basic control strategy.
    
    methods
        function controlSignal = execute(~, rxData, ~)
            % Simple control logic (e.g., just returning seq value)
            controlSignal = rxData.seq;
        end
    end
end