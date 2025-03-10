classdef NetworkPairer < NetworkNode & handle
    % NetworkPairer Pairs messages from two different nodes based on specified rule.
    % Here, the data is paiered based on the same sequence number (see
    % awaitSeqNr) -> adaptation possible
    %
    % This class receives messages from two nodes, buffers them, and pairs them
    % The paired message is then sent to the next node in the network.
    %
    % Properties:
    %   - sampleTime (double) : Sample time of the system.
    %   - awaitSeqNr (uint32) : Sequence number currently being processed.
    %   - taskName (char) : Name of the TrueTime task.
    %   - msgBufferRcv1 (MsgBuffer) : Buffer for messages from the first node.
    %   - msgBufferRcv2 (MsgBuffer) : Buffer for messages from the second node.
    %   - msgBufferSend (MsgBuffer) : Buffer for paired messages.
    %   - nodeRcv1 : Reference to the first sending node.
    %   - nodeRcv2 : Reference to the second sending node.
    %   - nodeNrRcv1 (uint32) : Node number of the first sending node.
    %   - nodeNrRcv2 (uint32) : Node number of the second sending node.
    %
    % See also: NetworkNode
    
    properties
        sampleTime double % Sample time of the system.
        awaitSeqNr uint32 % Sequence number currently being processed.
        taskName char % Name of the TrueTime task.
        msgBufferRcv1 MsgBuffer % Buffer for messages from the first node.
        msgBufferRcv2 MsgBuffer % Buffer for messages from the second node.
        msgBufferSend MsgBuffer % Buffer for paired messages.
        nodeRcv1  % Reference to the first sending node.
        nodeRcv2  % Reference to the second sending node.
        nodeNrRcv1 uint32 % Node number of the first sending node.
        nodeNrRcv2 uint32 % Node number of the second sending node.
    end
    
    methods
        function obj = NetworkPairer(outputCount, nextNode, nodeNr, sampleTime, nodeRcv1, nodeRcv2)
            % NetworkPairer Constructor for the pairer node.
            %
            % Initializes message buffers, stores references to the sending nodes,
            % and assigns node numbers for message identification.
            
            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);
            obj.sampleTime = sampleTime;
            obj.generateSendTaskName(nodeNr);

            obj.msgBufferRcv1 = MsgBuffer();
            obj.msgBufferRcv2 = MsgBuffer();
            obj.msgBufferSend = MsgBuffer();
            obj.awaitSeqNr = [];

            obj.nodeRcv1 = nodeRcv1;
            obj.nodeRcv2 = nodeRcv2;
        
            obj.nodeNrRcv1 = obj.nodeRcv1.nodeNr;
            obj.nodeNrRcv2 = obj.nodeRcv2.nodeNr;
        end
        
        function [executionTime, obj] = execute(obj, segment)
            % TrueTime task function
            switch segment
                case 1
                    rcvMsg = ttGetMsg();

                    if rcvMsg.nodeId == obj.nodeNrRcv1
                        executionTime = obj.processMsgFromNode1(rcvMsg);
                    else
                        executionTime = obj.processMsgFromNode2(rcvMsg);
                    end

                case 2
                    executionTime = obj.sendTopPairedMsg();

                otherwise
                    error('This should never be reached');
            end
        end

        function executionTime = processMsgFromNode1(obj, rcvMsg) % SensorNode
            % implementation for sensor node
            obj.awaitSeqNr = rcvMsg.seqNr;
            element = BufferElement(obj.awaitSeqNr, rcvMsg);
            obj.msgBufferRcv1.pushTop(element);

            % Check if a corresponding control msg exists
            index = find(obj.msgBufferRcv2.transmitTimes == obj.awaitSeqNr);

            % if rcvMsg.samplingTS < obj.sampleTime
            %     % For x0, the corresponding uk signal is 0
            %     rcvMsg.data = [rcvMsg.data,zeros(1,obj.nodeRcv2.nOut)];
            %     obj.msgBufferSend.pushTop(BufferElement(awaitSeqNr, rcvMsg));
            %     obj.msgBufferRcv1.popTop();
            % elseif 
            if ~isempty(index)
                % Matching signal found → Combine & send
                sentMsg = rcvMsg;
                sentMsg.data= [rcvMsg.data,obj.msgBufferRcv2.elements{index}.data.data];
                sentMsg.data = [rcvMsg.seqNr,rcvMsg.seqNr,obj.msgBufferRcv2.elements{index}.data.data];
                sentMsg.lastTransmitTS = ttCurrentTime();
                sentMsg.nodeId = obj.nodeNr;
                obj.msgBufferSend.pushTop(BufferElement(obj.awaitSeqNr, sentMsg));
                obj.msgBufferRcv1.popTop();
                obj.msgBufferRcv2.elements(index) = [];
            end

            executionTime = 0;
        end
        
        function executionTime = processMsgFromNode2(obj, rcvMsg)
            % Processes control msgs and stores them in bufferUk
            obj.awaitSeqNr = rcvMsg.seqNr;
            element = BufferElement(obj.awaitSeqNr, rcvMsg);
            obj.msgBufferRcv2.pushTop(element);

            % Check if a corresponding sensor msg exists
            index = find(obj.msgBufferRcv1.transmitTimes ==obj.awaitSeqNr, 1);
            if isempty(index)
                executionTime = 0;
                return;
            end

            % Matching xk found → Combine & send
            sentMsg = rcvMsg;
            sentMsg.data = [obj.msgBufferRcv1.elements{index}.data.data, rcvMsg.data];
            sentMsg.lastTransmitTS = ttCurrentTime();
            sentMsg.nodeId = obj.nodeNr;
            sentMsg.seqNr = obj.msgBufferRcv1.elements{index}.data.seqNr;

            obj.msgBufferSend.pushTop(BufferElement(obj.awaitSeqNr, sentMsg));
            obj.msgBufferRcv2.popTop();
            obj.msgBufferRcv1.elements(index) = [];

            executionTime = 0;
        end

        function executionTime = sendTopPairedMsg(obj)
            % Sends the top element in msgBufferSend if available

            if obj.msgBufferSend.elementCount == 0
                executionTime = -1;
                return;
            end

            topElement = obj.msgBufferSend.getTop();
            if obj.nextNode ~= 0
                ttSendMsg(obj.nextNode, topElement.data, 80);
            end
            ttAnalogOutVec(1:obj.nOut, topElement.data.data);
            obj.msgBufferSend.popTop();

            executionTime = -1;
        end
        
        function init(obj)
            % Initializes TrueTime task and clears buffers
            
            obj.msgBufferRcv1.clear();
            obj.msgBufferRcv2.clear();
            obj.msgBufferSend.clear();
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1;
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.execute);
            ttAttachNetworkHandler(obj.taskName);
        end

        function generateSendTaskName(obj, nodeNr)
            % setTaskName Sets the task name for the Network Pairer node.
            obj.taskName = ['pairerTaskNode', num2str(nodeNr)];
        end
    end
end
