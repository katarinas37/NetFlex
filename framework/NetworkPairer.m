classdef NetworkPairer < NetworkNode & handle
    % NetworkPairer: Matches state signals (xk) with corresponding control signals (uk)
    % to construct sk variables. Sends packets as soon as a match is found.
    %
    % See also: NetworkNode
    
    properties
        sampleTime double % Sample time
        awaitSeqNr uint32 % Sequence number to wait for
        taskName char % TrueTime task name
        bufferXk MsgBuffer % Buffer for sensor msgs
        bufferUk MsgBuffer % Buffer for control msgs
        bufferXkAndUk MsgBuffer % Buffer for paired msgs
    end
    
    methods
        function obj = NetworkPairer(outputCount, nextNode, nodeNr, sampleTime)
            % Constructor for NetworkPairer
            % sampleTime - Sample time
            
            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);
            obj.sampleTime = sampleTime;
            obj.taskName = ['pairerTaskNode', num2str(nodeNr)];
            obj.bufferXk = MsgBuffer();
            obj.bufferUk = MsgBuffer();
            obj.bufferXkAndUk = MsgBuffer();
            obj.awaitSeqNr = 0;
        end
        
        function [executionTime, obj] = pairerTask(obj, segment)
            % TrueTime task function
            switch segment
                case 1
                    receivedMsg = ttGetMsg();
                    if isempty(receivedMsg), executionTime = -1; return; end

                    if numel(receivedMsg.data) ~= 1
                        executionTime = obj.processSensorMsg(receivedMsg);
                    else
                        executionTime = obj.processControlMsg(receivedMsg);
                    end
                    
                case 2
                    executionTime = obj.sendTopMsg();
                    
                otherwise
                    error('This should never be reached');
            end
        end
        
        function executionTime = processSensorMsg(obj, receivedMsg)
            % Processes sensor msgs and stores them in bufferXk
            
            if abs(receivedMsg.lastTransmitTS(1) - receivedMsg.lastTransmitTS(2)) > 1e-4
                receivedMsg.data(:) = NaN;
            end
            
            transseqNr= round(receivedMsg.samplingTS / obj.sampleTime);
            element = BufferElement(transSeq, receivedMsg);
            obj.bufferXk.pushTop(element);

            % Check if a corresponding control msg exists
            index = find(obj.bufferUk.transmitTimes == transSeq, 1);
            
            if receivedMsg.samplingTS < 2 * obj.sampleTime
                % For x0 and x1, the corresponding uk signal is 0
                receivedMsg.data(3) = 0;
                obj.bufferXkAndUk.pushTop(BufferElement(transSeq, receivedMsg));
                obj.bufferXk.popTop();
            elseif ~isempty(index)
                % Matching uk found → Combine & send
                receivedMsg.data(3) = obj.bufferUk.elements{index}.data.data;
                obj.bufferXkAndUk.pushTop(BufferElement(transSeq, receivedMsg));
                obj.bufferXk.popTop();
                obj.bufferUk.elements(index) = [];
            end
            
            executionTime = 0;
        end
        
        function executionTime = processControlMsg(obj, receivedMsg)
            % Processes control msgs and stores them in bufferUk
            
            transseqNr= round(receivedMsg.lastTransmitTS(1) / obj.sampleTime);
            element = BufferElement(transSeq, receivedMsg);
            obj.bufferUk.pushTop(element);
            
            % Check if a corresponding sensor msg exists
            index = find(obj.bufferXk.transmitTimes == transSeq, 1);
            if isempty(index)
                executionTime = 0;
                return;
            end

            % Matching xk found → Combine & send
            newMsg = obj.bufferXk.elements{index}.data;
            newMsg.data(3) = element.data.data;
            obj.bufferXkAndUk.pushTop(BufferElement(transSeq, newMsg));
            obj.bufferUk.popTop();
            obj.bufferXk.elements(index) = [];

            executionTime = 0;
        end
        
        function executionTime = sendTopMsg(obj)
            % Sends the top element in bufferXkAndUk if available
            
            if obj.bufferXkAndUk.elementCount == 0
                executionTime = -1;
                return;
            end
            
            topElement = obj.bufferXkAndUk.top();
            if obj.nextnode ~= 0
                ttSendMsg(obj.nextnode, topElement.data, 80);
            end
            ttAnalogOutVec(1:obj.Nout, topElement.data.data);
            obj.bufferXkAndUk.popTop();

            executionTime = -1;
        end
        
        function init(obj)
            % Initializes TrueTime task and clears buffers
            
            obj.bufferXk.clear();
            obj.bufferUk.clear();
            obj.bufferXkAndUk.clear();
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1;
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.pairerTask);
            ttAttachNetworkHandler(obj.taskName);
        end
    end
end
