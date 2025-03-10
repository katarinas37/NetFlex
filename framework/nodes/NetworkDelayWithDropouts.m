classdef NetworkDelayWithDropouts < VariableDelay
    % NetworkDelayWithDropouts Configures the TrueTime kernel to act as a variable network delay.
    %
    % This class models network-induced delays while accounting for packet dropouts.
    % The mechanism buffers received packets and determines the transmission time
    % based on consecutive data dropouts.
    %
    % Properties:
    %   - delays (double array) : Vector of time delays for each received message.
    %   - dataLoss (logical array) : Binary mask indicating which packets are dropped.
    %   - dataLossMax (integer) : Maximum number of consecutive data dropouts.
    %   - sampleTime (double) : Sample time of the system.
    %
    % Methods:
    %   - NetworkDelayWithDropouts(outputCount, nextNode, nodeNumber, sampleTime, delays, dataLoss, dataLossMax)
    %   - calculateTransmitTime(rcvMsg) : Computes the transmission time for received messages.
    %   - init() : Resets the delay object.
    
    properties
        delays double      % Vector of time delays for each received message
        dataLoss logical   % Binary mask indicating which packets are dropped
        dataLossMax  % Max nr of consecutive data dropouts
        sampleTime double % Sample time of the system
    end
    
    methods
        function obj = NetworkDelayWithDropouts(outputCount, nextNode, nodeNumber, sampleTime, delays, dataLoss, dataLossMax)
            % NetworkDelayWithDropouts Constructor for a network delay object with dropouts.
            %
            % Initializes the delay node with predefined delays and a dropout mask.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNumber (integer) : Unique identifier for this delay node.
            %   - sampleTime (double) : Sampling time of the system.
            %   - delays (double array) : Predefined delay values for each message.
            %   - dataLoss (logical array) : Binary mask indicating dropped packets (0 = lost, 1 = received).
            %   - dataLossMax (integer) : Maximum number of consecutive dropouts allowed.

            % Call parent constructor (VariableDelay)
            obj@VariableDelay(outputCount, nextNode, nodeNumber);
            obj.sampleTime = sampleTime;      
            obj.delays = delays;
            obj.dataLoss = dataLoss;
            obj.dataLossMax = dataLossMax;
        end
        
        function [transmitTime,sentMsg] = calculateTransmitTime(obj, rcvMsg) 
            % calculateTransmitTime Computes the message transmission time while handling dropouts.
            %
            % This method implements a buffering mechanism:
            % - The system sends a sequence of messages [u_k, u_(k-1), ..., u_(k-pAC)].
            % - If a necessary signal arrives, the whole vector is stored.
            % - If any dropout occurs in the sequence, a large delay (1e6) is assigned.
            
            % Instead of sending the entire message buffer at once, each packet is processed
            % individually. The algorithm iterates over a window of packets indexed by 
            % sequence numbers k, k+1, ..., k + dataLossMax.
            %
            % For each packet in the window:
            %   - If the packet is successfully received, its transmission
            %     time is computed based on the associated network delay, the last 
            %     transmission timestamp, and the sample time.
            %   - If the packet is lost (dataLoss(seqIndex) = 0), it is assigned an
            %     artificially large delay (1e6) to indicate it should not be transmitted.
            %
            % The final transmission time is determined as the **minimum** among all
            % computed values, ensuring that the earliest valid transmission time is used.
            
            currentTime = ttCurrentTime();
            sentMsg = rcvMsg;
            transmitTimes = zeros(1, obj.dataLossMax + 1);

            for k = 0:obj.dataLossMax
                seqIndex = rcvMsg.seqNr + k;

                if obj.dataLoss(seqIndex)  % If packet is successfully transmitted
                    transmitTimes(k + 1) = obj.delays(seqIndex) + rcvMsg.lastTransmitTS(end) + obj.sampleTime * k - 1e-6;
                else  % If packet is lost
                    transmitTimes(k + 1) = 1e6; % Assign large delay to lost packets
                end
            end
            transmitTime = min(transmitTimes);

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

