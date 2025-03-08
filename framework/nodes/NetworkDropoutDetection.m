classdef NetworkDropoutDetection < VariableDelay
    % NetworkDropoutDetection Configures the TrueTime kernel for data loss
    % with implementation of the flag (e.g. Nan) when data is lost
    % Ensure the received node implements a mechanism to delay with a
    % chosen flag
    % 
    % Properties:
    %   - dataLoss (logical array) : Binary mask indicating which packets are dropped.
    %   - delayMax (double) : Maximum delay time for received messages.
    %
    % Methods:
    %   - NetworkDropoutDetection(outputCount, nextNode, nodeNumber, delayMax, dataLoss)
    %   - calculateTransmitTime(receivedMsg) : Determines the transmission time for a received message.
    %   - isMsgLost(seqNr) : Checks if a message is lost based on the dropout mask.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        dataLoss logical % Binary mask indicating which packets are dropped
        delayMax double  % Maximum delay time
    end
    
    methods
        function obj = NetworkDropoutDetection(outputCount, nextNode, nodeNumber, delayMax, dataLoss)
            % NetworkDropoutDetection Constructs an instance of this class.
            % dropoutMask - Binary array where 1 indicates successful transmission
            
            % Call parent constructor
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.delayMax = delayMax;
            obj.dataLoss = dataLoss;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, receivedMsg) 
            % calculateTransmitTime Determines the transmission time for a received message.
            
            currentTime = ttCurrentTime();
            sentMsg = receivedMsg;
            
            if obj.isMsgLost(receivedMsg.seqNr)
                transmitTime = receivedMsg.samplingTS + obj.delayMax - 1e-6;
                sentMsg.data = NaN; % Mark lost data with e.g. NaN
            else
                transmitTime = currentTime;
            end
            
            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
        function lost = isMsgLost(obj, seqNr)
            % Checks if a msg is lost based on the dropout mask
            lost = ~obj.dataLoss(seqNr);
        end
    end
end
