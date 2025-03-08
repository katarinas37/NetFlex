classdef NetworkDropoutSimple < VariableDelay
    % NetworkDropoutSimple Configures the TrueTime kernel for data loss handling.
    %
    % Lost packets are assigned an excessively large delay to prevent their
    % transmission within the simulation timeframe.
    %
    % Properties:
    %   - dataLoss (logical array) : Binary mask indicating which packets are dropped.
    %
    % Methods:
    %   - NetworkDropoutSimple(outputCount, nextNode, nodeNumber, dataLoss)
    %   - calculateTransmitTime(receivedMsg) : Determines the transmission time for a received message.
    %   - isMsgLost(seqNr) : Checks if a message is lost based on the dropout mask.
    %   - init() : Resets the dropout simulation.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        dataLoss logical % Binary mask indicating which packets are dropped
    end
    
    methods
        function obj = NetworkDropoutSimple(outputCount, nextNode, nodeNumber, dataLoss)
            % NetworkDropoutSimple Constructs an instance of this class.
            
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.dataLoss = dataLoss;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, receivedMsg)
            % Determines the transmission time for a received msg
            
            sentMsg = receivedMsg;
            currentTime = ttCurrentTime();
            
            if obj.isMsgLost(receivedMsg.seqNr)
                transmitTime = currentTime + 1e5; % Assign a large delay for lost packets
            else
                transmitTime = currentTime;
            end
            
            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
        function lost = isMsgLost(obj, seqNr)
            % Checks if a msg is lost based on the dataLoss vector
            lost = ~obj.dataLoss(seqNr);
        end
        
        function init(obj)
            % Initializes the dropout simulation
            
            init@VariableDelay(obj);
        end
    end
end
