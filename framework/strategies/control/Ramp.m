classdef Ramp < IControlStrategy
    % Ramp Implements a simple increasing strategy for debugging.
    %
    % This control strategy assigns a control signal equal to the sequence number 
    % of the received message. Since sequence numbers increase over time, this 
    % allows tracking how late a signal was sent.
    %
    % Useful for debugging because:
    %   - Higher control signal values indicate later transmissions.
    %   - Provides a simple increasing reference to observe delays in the system.
    %
    % Methods:
    %   - Ramp() : Constructor (no initialization needed).
    %   - execute(rcvMessage, ~, ~, ~) : Assigns control signal based on sequence number.
    
    methods
        function obj = Ramp(~)
            % Ramp Constructor for the simple ramp strategy.
            %
            % This constructor does not require any initialization, as the ramp 
            % strategy directly assigns control values based on sequence numbers.
        end

        function [controlSignal,obj] = execute(obj, rcvMessage, ~, ~, ~)
            % execute Assigns control signal based on message sequence number.
            %
            % This method returns the sequence number of the received message as
            % the control signal. This makes it useful for debugging network delays
            % since later messages will have larger control signal values.
            %
            % Inputs:
            %   - rcvMessage (NetworkMsg) : Received message containing system data.
            %
            % Outputs:
            %   - controlSignal (double) : Assigned control signal (equal to sequence number).
            %   - obj (Ramp) : Unchanged object (no internal state).
             
            controlSignal = rcvMessage.seqNr;
        end
    end
end