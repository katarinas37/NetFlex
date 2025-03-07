classdef NetworkOrderer < NetworkNode & handle
    % NetworkOrderer: Reorders received packets and transmits them in sequence.
    % 
    % See also: NetworkNode
    
    properties
        sampleTime double % Sample time
        awaitSeqNr uint32 % Seq number to wait for
        taskName char % TrueTime task name
        buffer MsgBuffer % Buffer to store network messages
    end
    
    methods
        function obj = NetworkOrderer(outputCount, nextNode, nodeNr, sampleTime)
            % Constructor for NetworkOrderer
            % sampleTime - Sample time
            
            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);
            obj.sampleTime = sampleTime;
            obj.taskName = ['ordererTaskNode', num2str(nodeNr)];
            obj.buffer = MsgBuffer();
            obj.awaitSeqNr = 0;
        end
        
        function [executionTime, obj] = ordererTask(obj, segment)
            % TrueTime task function
            switch segment
                case 1
                    executionTime = obj.enqueueMsg();
                    
                case 2
                    executionTime = obj.sendTopMsg();
                    
                otherwise
                    error('This should never be reached');
            end
        end
        
        function executionTime = enqueueMsg(obj)
            % Handles incoming messages and stores them in the buffer
            
            receivedMsg = ttGetMsg();
            transSeq = round(receivedMsg.sampleTS / obj.sampleTime);
            element = BufferElement(transSeq, receivedMsg);
            obj.buffer.pushTop(element);
            obj.buffer.sort();
            
            executionTime = 0;
        end
        
        function executionTime = sendTopMsg(obj)
            % Sends the top element if it's next in the sequence
            
            if obj.buffer.elementCount == 0
                executionTime = -1;
                return;
            end
            
            topElement = obj.buffer.top();
            if obj.awaitSeqNr == topElement.transmitTime
                if obj.nextnode ~= 0
                    ttSendMsg(obj.nextnode, topElement.data, 80); % Send message (80 bits) to next node
                end
                ttAnalogOutVec(1:obj.Nout, topElement.data.data);
                obj.buffer.popTop();
                obj.awaitSeqNr = obj.awaitSeqNr + 1;
                
                executionTime = (obj.buffer.elementCount ~= 0) * 1e-3;
                if executionTime > 0
                    ttSetNextSegment(2);
                end
            else
                executionTime = -1;
            end
        end
        
        function init(obj)
            % Initializes TrueTime task and clears buffers
            
            obj.awaitSeqNr = 0;
            obj.buffer.clear();
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1;
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.ordererTask);
            ttAttachNetworkHandler(obj.taskName);
        end
    end
end
