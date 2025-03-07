classdef NetworkDropoutDetection < VariableDelay
    % NetworkDropoutDetection: Configures the TrueTime kernel for network buffering with constant delay.
    %
    % This class ensures that messages experience a constant delay unless they are lost.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        tauMax double % Maximum delay time
        dropoutMask logical % Binary mask indicating which packets are dropped
    end
    
    methods
        function obj = NetworkDropoutDetection(nOut, nextNode, nodeNr, tauMax, dropoutMask)
            % Constructor for NetworkDropoutDetection
            % dropoutMask - Binary array where 1 indicates successful transmission
            
            obj@VariableDelay(nOut, nextNode, nodeNr);
            obj.tauMax = tauMax;
            obj.dropoutMask = dropoutMask;
        end
        
        function [transmitTime, sentMsg] = computeTransmitTime(obj, receivedMsg)
            % Determines the transmission time for a received msg
            
            currentTime = ttCurrentTime();
            sentMsg = receivedMsg;
            
            if obj.isMsgLost(receivedMsg.seq)
                transmitTime = receivedMsg.sampleTS + obj.tauMax - 1e-6;
                sentMsg.data = NaN; % Mark lost data
            else
                transmitTime = currentTime;
            end
            
            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
        function lost = isMsgLost(obj, seq)
            % Checks if a msg is lost based on the dropout mask
            lost = ~obj.dropoutMask(seq);
        end
    end
end
