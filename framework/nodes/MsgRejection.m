classdef MsgRejection < NetworkNode
    % MSGREJECTION Implements a message rejection mechanism in a TrueTime network.
    %
    % This class acts as a message filter, ensuring that only the latest
    % received message (based on timestamp) is forwarded to the next node.
    %
    % Properties:
    %   - taskName (char)   : Name of the TrueTime task for message processing.
    %   - sentMsg (NetworkMsg) : Stores the most recent valid message to be sent.
    %   - inbox (array) : Stores all received messages (for debugging/logging).
    %   - inboxTime (array) : Stores timestamps corresponding to received messages.
    %
    % Methods:
    %   - MsgRejection(nextNode, nodeNr) : Constructor for the message rejection node.
    %   - evaluate(segment) : Processes incoming messages, forwarding only the latest.
    %   - init() : Initializes the TrueTime kernel and the message filtering mechanism.
    %   - generateTaskName(nodeNr) : Generates a unique task name for the node.
    %
    % See also: NetworkNode

    properties
        taskName      % Name of the TrueTime task for processing messages
        sentMsg    % Most recent valid message received
        inbox         % Stores all received messages (for debugging/logging)
        inboxTime    % TSs corresponding to received messages
    end

    methods
        function obj = MsgRejection(outputCount,nextNode, nodeNr)
            % MSGREJECTION Constructor for the message rejection node.
            %
            % Inputs:
            %   - nextNode (array) : Node numbers that should receive messages.
            %   - nodeNr (integer) : Unique identifier for this node in the network.
            obj@NetworkNode(outputCount,0,nextNode,nodeNr);

            obj.generateTaskName(nodeNr);            
            obj.sentMsg = [];
            obj.inbox = [];
            obj.inboxTime = [];
        end

        function init(obj)
            % Initializes the node, setting up the TrueTime kernel and task.
            %
            % This function:
            %   - Resets internal state variables.
            %   - Initializes the TrueTime kernel with deadline-monotonic scheduling.
            %   - Attaches a network handler to receive messages.
            
            obj.sentMsg = []; % newest message to be sent
            ttInitKernel('prioDM');   % deadline-monotonic scheduling
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName)
        end

        function [exectime, obj] = evaluate(obj, ~)
            % Processes incoming messages, forwarding only the most recent one.
            %
            % This function:
            %   - Retrieves the latest received message from the network.
            %   - Updates the stored message only if it is more recent.
            %   - Logs received messages for debugging purposes.
            %   - Sends the latest valid message to all connected nodes.

            % Retrieve the received message
            rcvMsg = ttGetMsg;  
            TS = ttCurrentTime;
      
            % Log received messages (for debugging)
            obj.inboxTime = [obj.inboxTime; TS];
            obj.inbox = [obj.inbox;rcvMsg.data];

            % Update sentMsg only if the received message is more recent
            if(isempty(obj.sentMsg) || rcvMsg.samplingTS > obj.sentMsg.samplingTS)
                obj.sentMsg = rcvMsg;
                obj.sentMsg.nodeId = obj.nodeNr;
            end

            % Forward the latest valid message to all connected nodes
            for nextNode = obj.nextNode(:)'
                if nextNode
                    ttSendMsg(nextNode, obj.sentMsg, 80);  % send message (80 bits) to node 2 (controller)
                end
            end

            % Output message data to an analog output (for visualization or logging)
            ttAnalogOutVec(1:numel(obj.sentMsg.data),obj.sentMsg.data);
            exectime = -1;
        end


        function generateTaskName(obj, nodeNr)
            % GeneratetaskName Sets the task name for the observer node.
            %
            % The task name is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier.
            
            obj.taskName = ['MsgRejectionTaskName', num2str(nodeNr)];
        end
    end
end


