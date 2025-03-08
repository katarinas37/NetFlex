classdef NetworkBuffer < VariableDelay
    % NetworkBuffer 
    % This class configures the TrueTime kernel to simulate a network buffer
    % that ensures a specified dispatch strategy.
    %
    % The buffer can operate in two modes:
    %   1. 'fixed'      - Applies a constant transmission delay.
    %   2. 'multirate'  - Divides the sampling period into multiple 
    %                     transmission intervals.    
    %
    % Properties:
    %   - dispatchStrategy (string) : Dispatch strategy ('fixed' or 'multirate')
    %   - fixedDelay (double)       : Fixed delay value (only for 'fixed' strategy)
    %   - numTransmissions (int32)  : Number of transmissions per period (only for 'multirate' strategy)
    %   - sampleTime                : Sample time of the system
    %
    % Methods:
    %   - NetworkBuffer(outputCount, nextNode, nodeNumber, sampleTime, dispatchStrategy, lastParam)
    %   - calculateTransmitTime(receivedMessage) : Computes message transmission time.
    %   - init() : Resets the buffer object.
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
            % NetworkBuffer Constructs an instance of this class.
            % Call parent constructor
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
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, receivedMsg) 
            % calculateTransmitTime Computes message transmission time.
            sentMsg = receivedMsg;

            currentTime = ttCurrentTime();
            switch obj.dispatchStrategy
                case 'fixed'
                    % Apply a constant delay
                    transmitTime = receivedMsg.samplingTS + obj.fixedDelay;

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

