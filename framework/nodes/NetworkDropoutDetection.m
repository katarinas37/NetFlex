classdef NetworkDropoutDetection < VariableDelay
    % NetworkDropoutDetection Configures the TrueTime kernel for data loss.
    %
    % This class models packet dropouts by introducing a flag (e.g., NaN) when 
    % data is lost. It ensures that the receiving node implements a mechanism 
    % to handle flagged data appropriately.
    %
    % Properties:
    %   - dataLoss (logical array) : Binary mask indicating which packets are dropped.
    %   - delayMax (double) : Maximum delay time for received messages.
    %
    % Methods:
    %   - NetworkDropoutDetection(outputCount, nextNode, nodeNumber, delayMax, dataLoss)
    %   - calculateTransmitTime(rcvMsg) : Determines the transmission time for a received message.
    %   - isMsgLost(seqNr) : Checks if a message is lost based on the dropout mask.
    %
    % See also: VariableDelay, NetworkNode
    
    properties
        dataLoss logical % Binary mask indicating which packets are dropped
        delayMax double  % Maximum delay time
    end
    
    methods
        function obj = NetworkDropoutDetection(outputCount, nextNode, nodeNumber, delayMax, dataLoss)
          % NetworkDropoutDetection Constructor for dropout detection node.
            %
            % Initializes a dropout detection node that marks lost messages
            % and assigns a maximum delay when dropouts occur.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNumber (integer) : Unique identifier for this dropout node.
            %   - delayMax (double) : Maximum delay time before transmission.
            %   - dataLoss (logical array) : Binary mask indicating which packets are lost.

            % Call parent constructor (VariableDelay)
            obj@VariableDelay(outputCount, nextNode, nodeNumber);

            obj.delayMax = delayMax;
            obj.dataLoss = dataLoss;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, rcvMsg) 
            % calculateTransmitTime Determines the transmission time for a received message.
            %
            % If a message is lost, it is assigned a maximum delay (`delayMax`) and
            % flagged with `NaN` to indicate missing data.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Incoming network message.
            %
            % Outputs:
            %   - transmitTime (double) : Scheduled transmission time.
            %   - sentMsg (NetworkMsg) : Modified message with potential NaN marking.
            
            currentTime = ttCurrentTime();
            sentMsg = rcvMsg;
            
            if obj.isMsgLost(rcvMsg.seqNr)
                transmitTime = rcvMsg.samplingTS + obj.delayMax - 1e-6;
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
    end
end
