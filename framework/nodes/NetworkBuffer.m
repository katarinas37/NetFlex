classdef NetworkBuffer < VariableDelay
    % NetworkBuffer sets up a network buffer in the TrueTime framework.
    %
    % This class configures a network buffer that ensures a specified dispatch strategy.
    % Messages are stored in the buffer and dispatched based on either a fixed delay
    % or a multi-rate transmission scheme.
    %
    % The buffer operates in one of two modes:
    %   1. 'fixed'      - Applies a constant transmission delay.
    %   2. 'multirate'  - Divides the sampling period into multiple transmission intervals.
    %
    % Properties:
    %   - dispatchStrategy (string)  : Dispatch strategy ('fixed' or 'multirate').
    %   - fixedDelay (double)        : Fixed delay value (used only in 'fixed' mode).
    %   - numTransmissions (int32)   : Number of transmissions per period (used only in 'multirate' mode).
    %   - sampleTime (double)        : Sample time of the system.
    %
    % Methods:
    %   - NetworkBuffer(outputCount, nextNode, nodeNumber, sampleTime, dispatchStrategy, lastParam)
    %   - calculateTransmitTime(rcvMessage) : Computes message transmission time.
    %
    % See also: VariableDelay, NetworkNode

    properties
        dispatchStrategy  % Dispatch strategy ('fixed' or 'multirate')
        fixedDelay        % Fixed delay value (only for 'fixed' strategy)
        numTransmissions  % Number of transmissions per period (only for 'multirate' strategy)
        sampleTime        % Sample time of the system
    end
    
    methods
        function obj = NetworkBuffer(outputCount, nextNode, nodeNumber, sampleTime, dispatchStrategy, lastParam)
            % NetworkBuffer Constructor for the network buffer object.
            %
            % This constructor initializes a network buffer that manages message
            % dispatching based on a predefined strategy.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNumber (integer) : Unique identifier for this buffer node.
            %   - sampleTime (double) : Sampling time of the system.
            %   - dispatchStrategy (string) : Message dispatch strategy ('fixed' or 'multirate').
            %   - lastParam (double or int32) : Fixed delay for 'fixed' mode or number of transmissions for 'multirate' mode.

            % Call parent constructor (VariableDelay)
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            
            obj.sampleTime = sampleTime;
            obj.dispatchStrategy = dispatchStrategy;

            % Handle different strategies
            switch dispatchStrategy
                case 'fixed'
                    obj.fixedDelay = lastParam; % Assign fixed delay
                    obj.numTransmissions = [];  % Not used in 'fixed' mode
                    
                case 'multirate'
                    obj.numTransmissions = lastParam; % Number of updates per period
                    obj.fixedDelay = []; % Not used in 'multirate' mode
                    
                otherwise
                    error('Invalid dispatch strategy. Use "fixed" or "multirate".'); % extension possible
            end
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, rcvMsg) 
            % calculateTransmitTime Computes message transmission time.
            %
            % Determines when a message should be sent based on the selected dispatch strategy.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Incoming network message.
            %
            % Outputs:
            %   - transmitTime (double) : Scheduled time for message transmission.
            %   - sentMsg (NetworkMsg) : Copy of the received message.
            
            sentMsg = rcvMsg;

            currentTime = ttCurrentTime();
            switch obj.dispatchStrategy
                case 'fixed'
                    % Apply a constant delay
                    transmitTime = rcvMsg.samplingTS + obj.fixedDelay;

                case 'multirate'
                    % Divide period into numTransmissions intervals
                    subperiod = obj.sampleTime / obj.numTransmissions;
                    transmitTime = ceil(currentTime / subperiod) * subperiod;

                otherwise
                    error('Invalid dispatch strategy. Use "fixed" or "multirate".');
            end

            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
    end
end

