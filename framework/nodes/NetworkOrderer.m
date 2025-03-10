classdef NetworkOrderer < NetworkNode & handle
    % NetworkOrderer Reorders received packets and transmits them in sequence.
    %
    % This class buffers incoming messages and ensures they are transmitted 
    % in sequential order based on their assigned sequence number.
    %
    % Properties:
    %   - taskName (char) : Name of the TrueTime task.
    %   - sampleTime (double) : Sampling time.
    %   - awaitSeqNr (uint32) : Sequence number of the next expected message.
    %   - msgbuffer (MsgBuffer) : Buffer to store and manage incoming messages.
    %   - sentMsgDataHistory (double array) : History of sent message data.
    %   - sentMsgTimeHistory (double array) : History of sent message timestamps.
    %
    % Methods:
    %   - NetworkOrderer(outputCount, nextNode, nodeNr, sampleTime)
    %   - ordererTask(seg) : TrueTime task function handling message ordering.
    %   - enqueueMsg() : Stores incoming messages in the buffer.
    %   - sendTopMsg() : Sends the top message from the buffer if it is next in sequence.
    %   - init() : Initializes the TrueTime kernel and clears buffers.
    %
    % See also: NetworkNode, MsgBuffer
    
    properties
        taskName char % TrueTime task name
        sampleTime double % Sample time
        awaitSeqNr uint32 % seqNrnumber to wait for
        msgbuffer MsgBuffer % Buffer to store network messages
        sentMsgDataHistory double
        sentMsgTimeHistory double
    end
    
    methods
        function obj = NetworkOrderer(outputCount, nextNode, nodeNr, sampleTime)
            % NetworkOrderer Constructor for a network orderer node.
            %
            % Initializes an ordering node that buffers incoming messages and
            % ensures they are transmitted in sequence.
            %
            % Inputs:
            %   - outputCount (integer) : Number of outputs from this node.
            %   - nextNode (integer or vector) : Node(s) to which messages should be sent.
            %   - nodeNr (integer) : Unique identifier for this orderer node.
            %   - sampleTime (double) : Sampling time of the system.
            
            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);
            
            obj.generateTaskName(nodeNr);
            obj.sampleTime = sampleTime;
            obj.msgbuffer = MsgBuffer();
            obj.awaitSeqNr = 0;
            obj.sentMsgDataHistory = [];
            obj.sentMsgTimeHistory = [];
        end
        
        function [executionTime, obj] = ordererTask(obj, seg)
            % ordererTask TrueTime task function handling message ordering.
            %
            % This function is executed when the TrueTime kernel schedules the task.
            % It either enqueues new messages or sends the next message in sequence.
            %
            % Inputs:
            %   - seg (integer) : Specifies the execution segment.
            %
            % Outputs:
            %   - executionTime (double) : Indicates when the task should be executed again.

            switch seg
                case 1
                    executionTime = obj.enqueueMsg();                  
                case 2
                    executionTime = obj.sendTopMsg();                   
                otherwise
                    error('This should never be reached');
            end
        end
        
        function executionTime = enqueueMsg(obj)
            % enqueueMsg Handles incoming messages and stores them in the buffer.
            %
            % This method retrieves messages from the TrueTime network, assigns
            % them a transmission sequence number, and adds them to the buffer.
            % The buffer is then sorted to maintain message order.
            %
            % Outputs:
            %   - executionTime (double) : Returns 0 (immediate execution).

            rcvMsg = ttGetMsg();
            rcvMsg.nodeId = obj.nodeNr;
            transSeqNr= round(rcvMsg.samplingTS / obj.sampleTime);
            element = BufferElement(transSeqNr, rcvMsg);
            obj.msgbuffer.pushTop(element);
            obj.msgbuffer.sortBuffer();
            
            executionTime = 0;
        end
        
        function executionTime = sendTopMsg(obj)
            % sendTopMsg Sends the top element if it's next in the sequence.
            %
            % This method checks whether the message at the top of the buffer
            % has the expected sequence number. If so, it transmits the message.
            %
            % Outputs:
            %   - executionTime (double) : Indicates whether the task should continue.

            % If the buffer is empty, do nothing            
            if obj.msgbuffer.elementCount == 0
                executionTime = -1;
                return;
            end
            
            topElement = obj.msgbuffer.getTop();
            if obj.awaitSeqNr == topElement.transmitTime
                if obj.nextNode ~= 0
                    ttSendMsg(obj.nextNode, topElement.data, 80); % Send message (80 bits) to next node
                end
                obj.sentMsgDataHistory = [obj.sentMsgDataHistory,topElement.data.data];
                obj.sentMsgTimeHistory = [obj.sentMsgTimeHistory,ttCurrentTime()];
                ttAnalogOutVec(1:obj.nOut, topElement.data.data)
                obj.msgbuffer.popTop();
                obj.awaitSeqNr = obj.awaitSeqNr + 1;
                
                if(obj.msgbuffer.elementCount ~=0)
                            executionTime = 0;
                            ttSetNextSegment(2);
                 else
                            executionTime = -1;
                end
            else
                executionTime = -1;
            end
        end
        
        function init(obj)
            % init Initializes the TrueTime task and clears buffers.
            %
            % This method resets the sequence counter, clears the buffer,
            % and sets up the TrueTime task for handling message ordering.

            % Reset sequence number tracking            
            obj.awaitSeqNr = 0;
            obj.msgbuffer.clear();
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1;
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.ordererTask);
            ttAttachNetworkHandler(obj.taskName);
        end

        function generateTaskName(obj, nodeNr)
            % GenerateTaskName Sets the task name for the observer node.
            %
            % The task name is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier.
            
            obj.taskName = ['OrdererTaskNode', num2str(nodeNr)];
        end
    end
end