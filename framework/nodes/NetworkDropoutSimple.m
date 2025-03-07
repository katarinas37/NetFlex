classdef NetworkDropoutSimple < VariableDelay
    % NetworkDropoutSimple: Configures the TrueTime kernel for data loss handling.
    % 
    % Lost packets are assigned an excessively large delay to prevent their
    % transmission within the simulation timeframe.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        dropoutMask logical % Binary mask indicating which packets are dropped
    end
    
    methods
        function obj = NetworkDropoutSimple(nOut, nextNode, nodeNr, dropoutMask)
            % Constructor for NetworkDropoutSimple
            % dropoutMask - Binary array where 1 indicates successful transmission
            
            obj@VariableDelay(nOut, nextNode, nodeNr);
            obj.dropoutMask = dropoutMask;
        end
        
        function [transmitTime, sentMsg] = computeTransmitTime(obj, receivedMsg)
            % Determines the transmission time for a received msg
            
            sentMsg = receivedMsg;
            currentTime = ttCurrentTime();
            
            if obj.isMsgLost(receivedMsg.seq)
                transmitTime = currentTime + 1e5; % Assign a large delay for lost packets
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
        
        function init(obj)
            % Initializes the dropout simulation
            
            init@VariableDelay(obj);
        end
    end
end
