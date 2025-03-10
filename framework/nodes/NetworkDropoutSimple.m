classdef NetworkDropoutSimple < VariableDelay
    % NetworkDropoutSimple Configures the TrueTime kernel for data loss handling.
    %
    % This class models packet dropouts by assigning an excessively large delay
    % (1e5) to lost packets, effectively preventing their transmission within
    % the simulation timeframe.
    %
    % Properties:
    %   - dataLoss (logical array) : Binary mask indicating which packets are dropped.
    %
    % Methods:
    %   - NetworkDropoutSimple(outputCount, nextNode, nodeNumber, dataLoss)
    %   - calculateTransmitTime(rcvMsg) : Determines the transmission time for a received message.
    %   - isMsgLost(seqNr) : Checks if a message is lost based on the dropout mask.
    %   - init() : Resets the dropout simulation.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        dataLoss logical % Binary mask indicating which packets are dropped
    end
    
    methods
        function obj = NetworkDropoutSimple(outputCount, nextNode, nodeNumber, dataLoss)
            % NetworkDropoutSimple Constructor for dropout handling node.
            %
            % Initializes a dropout simulation where lost messages are assigned a 
            % large delay to prevent their transmission.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNumber (integer) : Unique identifier for this dropout node.
            %   - dataLoss (logical array) : Binary mask indicating which packets are lost.

            % Call parent constructor (VariableDelay)            
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.dataLoss = dataLoss;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, rcvMsg)
            % calculateTransmitTime Determines the transmission time for a received message.
            %
            % If a message is lost, it is assigned an excessively large delay (1e5)
            % to prevent it from being sent within the simulation timeframe.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Incoming network message.
            %
            % Outputs:
            %   - transmitTime (double) : Scheduled transmission time.
            %   - sentMsg (NetworkMsg) : Copy of the received message.

            sentMsg = rcvMsg;
            currentTime = ttCurrentTime();
            
            if obj.isMsgLost(rcvMsg.seqNr)
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
            % isMsgLost Checks if a message is lost based on the dropout mask.
            %
            % This function determines whether a given message (identified by its sequence number)
            % was dropped based on the predefined `dataLoss` mask.
            %
            % Inputs:
            %   - seqNr (integer) : Sequence number of the message.
            %
            % Outputs:
            %   - lost (logical) : Returns `true` if the message is lost, otherwise `false`.
            
            lost = ~obj.dataLoss(seqNr);
        end
        
        function init(obj)
            % init Resets the dropout simulation.
            %
            % This method calls the parent class (VariableDelay) initializer to 
            % reset any stored state.

            init@VariableDelay(obj);
        end
    end
end
