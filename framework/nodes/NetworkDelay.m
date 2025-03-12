classdef NetworkDelay < VariableDelay
    % NetworkDelay Configures the TrueTime kernel to act as a variable network delay.
    %
    % This class models a variable network delay, where each received message 
    % experiences a predefined time delay before transmission. The delays are 
    % stored in a vector and assigned based on the message sequence number.
    %
    % Properties:
    %   - delays (double array) : Vector of time delays for each received message.
    %
    % Methods:
    %   - NetworkDelay(outputCount, nextNode, nodeNr, delayTimes)
    %   - calculateTransmitTime(receivedMessage) : Computes message transmission time.
    %   - init() : Resets the delay object.
    %
    % See also: VariableDelay, NetworkNode

    properties
        delays double % Vector of time delays for each received message
    end
    
    methods
        function obj = NetworkDelay(outputCount, nextNode, nodeNr, delays)
            % NetworkDelay Constructor for the network delay object.
            %
            % Initializes a network delay node in the TrueTime simulation.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNr (integer) : Unique identifier for this delay node.
            %   - delays (double array) : Predefined delay values for each message sequence.

            % Call parent constructor (VariableDelay)
            obj@VariableDelay(outputCount, nextNode, nodeNr);
            obj.delays = delays;
        end
        
        function [transmitTime, sentMsg] = calculateTransmitTime(obj, rcvMsg) 
            % calculateTransmitTime Computes the transmission time for a received message.
            %
            % This method determines when a message should be transmitted based on its 
            % assigned delay value. The delay is selected from the `delays` vector 
            % using the message's sequence number.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Incoming network message.
            %
            % Outputs:
            %   - transmitTime (double) : Scheduled time for message transmission.
            %   - sentMsg (NetworkMsg) : Copy of the received message.

            currentTime = ttCurrentTime();
            sentMsg = rcvMsg;
            transmitTime = obj.delays(rcvMsg.seqNr) + rcvMsg.lastTransmitTS(end);
            % Sanity check: Ensure transmitTime is not in the past
            if currentTime > transmitTime
                error('Invalid transmitTime: currentTime: %.3f, transmitTime: %.3f', currentTime, transmitTime);
            end
        end
        
        function init(obj)
            % init Resets the delay object.
            %
            % This method calls the parent class (VariableDelay) initializer to 
            % reset any stored state.
            
            init@VariableDelay(obj);
        end
    end
end
