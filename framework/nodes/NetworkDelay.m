classdef NetworkDelay < VariableDelay
    % NetworkDelay Configures the TrueTime kernel to act as a variable network delay.
    %
    % Properties:
    %   - delays (double array) : Vector of time delays for each received message.
    %
    % Methods:
    %   - NetworkDelay(outputCount, nextNode, nodeNumber, delayTimes)
    %   - calculateTransmitTime(receivedMessage) : Computes message transmission time.
    %   - init() : Resets the delay object.
    %
    % See also: VariableDelay, NetworkNode

    properties
        delays double % Vector of time delays for each received message
    end
    
    methods
        function obj = NetworkDelay(outputCount, nextNode, nodeNumber, delays)
            % NetworkDelay Constructs an instance of this class.
            %
            % Example:
            %   delay = NetworkDelay(1, 2, 3, [0.01, 0.02, 0.03]);
            
            % Call parent constructor
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.delays = delays;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, receivedMsg) 
            % calculateTransmitTime Computes message transmission time.
            %
            % Example:
            %   transmitTime = obj.calculateTransmitTime(receivedMessage);

            currentTime = ttCurrentTime();
            sentMsg = receivedMsg;
            transmitTime = obj.delays(receivedMsg.seqNr) + receivedMsg.lastTransmitTS(end);
        
            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
        function init(obj)
            % init Resets the delay object.
            init@VariableDelay(obj);
        end
    end
end
