classdef NetworkDelay < VariableDelay
    % NetworkDelay Configures the TrueTime kernel to act as a variable network delay.
    %
    % Properties:
    %   - delayTimes (double array) : Vector of time delays for each received message.
    %
    % Methods:
    %   - NetworkDelay(outputCount, nextNode, nodeNumber, delayTimes)
    %   - calculateTransmitTime(receivedMessage) : Computes message transmission time.
    %   - init() : Resets the delay object.

    properties
        delayTimes double % Vector of time delays for each received message
    end
    
    methods
        function obj = NetworkDelay(outputCount, nextNode, nodeNumber, delayTimes)
            % NetworkDelay Constructs an instance of this class.
            %
            % Example:
            %   delay = NetworkDelay(1, 2, 3, [0.01, 0.02, 0.03]);
            
            % Call parent constructor
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.delayTimes = delayTimes;
        end
        
        function transmitTime = calculateTransmitTime(obj, receivedMessage) 
            % calculateTransmitTime Computes message transmission time.
            %
            % Example:
            %   transmitTime = obj.calculateTransmitTime(receivedMessage);
            
            ttCurrentTime();
            transmitTime = obj.delayTimes(receivedMessage.seq) + receivedMessage.lastTransmitTimestamp(end);
        end
        
        function init(obj)
            % init Resets the delay object.
            init@VariableDelay(obj);
        end
    end
end
