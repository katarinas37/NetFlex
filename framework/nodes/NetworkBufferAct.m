classdef NetworkBufferAct < NetworkNode & handle
    % NetworkBufferAct Implements an active network buffer with scheduled transmission.
    %
    % This class models a network buffer that temporarily stores incoming messages 
    % and transmits them at predefined intervals. Unlike a traditional network buffer 
    % (which transmits only when receiving new messages), this implementation ensures 
    % that a packet is sent **at the beginning of each sampling period**, even if 
    % no new message has arrived.
    %
    % This is crucial for control strategies requiring explicit state and input pairing.
    %
    % Properties:
    %   - msgBuffer (MsgBuffer) : Buffer storing messages waiting to be transmitted.
    %   - sendTaskName (char) : Name of the TrueTime task handling message sending.
    %   - delayTaskName (char) : Name of the TrueTime task handling delay processing.
    %   - sampleTime (double) : Sampling time of the system.
    %
    % Methods:
    %   - NetworkBufferAct(nOut, nextNode, nodeNr, sampleTime) : Constructor.
    %   - init() : Initializes the TrueTime kernel and creates necessary tasks.
    %   - delay_code(seg) : Handles new messages and schedules their transmission.
    %   - send_code(seg) : Sends messages when their scheduled transmission time arrives.
    %   - calculateTransmitTime() : Computes the next valid transmission time.
    %   - generateSendTaskName(nodeNr) : Generates unique task names for TrueTime tasks.
    %
    % See also: NetworkNode, MsgBuffer, BufferElement

    properties
        msgBuffer MsgBuffer % Buffer to store messages waiting for transmission.
        sendTaskName char % Name of the TrueTime task handling message sending.
        delayTaskName char % Name of the TrueTime task handling delay processing.
        sampleTime double % Sampling time of the system.    end
    end
    
    methods
        function obj = NetworkBufferAct(nOut, nextNode, nodeNr,sampleTime)
            % NetworkBufferAct Constructor for the active network buffer.
            % 
            % Initializes the buffer and assigns task names for handling delay 
            % processing and message sending.
            % 
            % Inputs:
            %   - nOut (integer) : Number of output signals.
            %   - nextNode (integer) : Identifier of the next node in the network.
            %   - nodeNr (integer) : Unique identifier for this buffer node.
            %   - sampleTime (double) : Sampling period of the system.

            % Call the parent class constructor (NetworkNode)
            obj@NetworkNode(nOut,0,nextNode,nodeNr);

            obj.generateSendTaskName(nodeNr);
            obj.sampleTime = sampleTime;
            obj.msgBuffer = MsgBuffer();
        end
        
        function [exectime, obj] = delay_code(obj, seg)
            % delay_code Processes incoming messages and schedules their transmission.
            %
            % This function is triggered when a new message arrives. It calculates 
            % the appropriate transmission time and schedules a task to send the message.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for this task.

            switch seg
                case 1
                    % Get the new message
                    rcvMsg = ttGetMsg;
                    if(~isa(rcvMsg, 'NetworkMsg'))
                        error('Network Buffer (new) can only deal with NetworkMsg objects')
                    end
                    % Compute the transmit times
                    transmitTime = obj.calculateTransmitTime();
                    rcvMsg.lastTransmitTS = [rcvMsg.lastTransmitTS(end),transmitTime];
                    rcvMsg.seqNr = ceil(ttCurrentTime/obj.sampleTime)+1;                        try
                    ttKillJob(obj.sendTaskName);
                    
                    catch
                        warning('send_delayed_task: Problem killing send_delay job')
                    end
                    % insert actual packet at the beginning of the buffer
                    element = BufferElement(transmitTime,rcvMsg);
                    obj.msgBuffer.pushTop(element);
                    
                    %Create new send job for the new packet
                    ttCreateJob(obj.sendTaskName);
                    exectime = -1;
            end
        end
        
        function [exectime, obj] = send_code(obj, seg)
            % send_code Waits for the next transmission time and sends messages.
            %
            % This function handles message transmission at scheduled intervals. 
            % It waits until the next valid transmit time and then sends the stored 
            % message to the next node.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for this task.
            switch seg
                case 1
                    if obj.msgBuffer.elementCount
                        wakeUpTime = obj.msgBuffer.getTop().transmitTime; 
                    else % fullfilled only at the beginning 
                        % start sending data at t = sampleTime  (= u1, gets paired with x1)
                        wakeUpTime = obj.sampleTime+1e-9;  
                        samplingTS = obj.sampleTime;
                        lastTransmitTS = samplingTS;
                        data = 0;
                        seqNr = 2;
                        sentMsg = NetworkMsg(samplingTS, lastTransmitTS, data, seqNr, obj.nodeNr);
                        element = BufferElement(ttCurrentTime,sentMsg);
                        obj.msgBuffer.pushTop(element);
                    end
                    ttSleepUntil(wakeUpTime);
                    exectime = 0;
                case 2
                    %If the transmit time has not been reached, go to sleep again
                    if obj.msgBuffer.getTop().transmitTime - ttCurrentTime >1e-8
                        ttSetNextSegment(1);
                    end
                    exectime = 0;
                case 3
                    %the transmit time has ben reached -> send the message to the nextNode
                    % get data
                    sentMsg = obj.msgBuffer.getTop().data;  % original
                    sentMsg.seqNr = round(sentMsg.lastTransmitTS(end)/obj.sampleTime+1); % change!!
                    
                    for nextNode = obj.nextNode
                        if(nextNode ~= 0)
                            ttSendMsg(nextNode, sentMsg, 80); % Send message (80 bits) to next node 5 (actuator)
                        end
                    end
                    ttAnalogOutVec(1:obj.nOut,sentMsg.data);
                    % schedule next job
                    ttCreateJob(obj.sendTaskName);
                    obj.msgBuffer.clear();
                    sentMsg_new = sentMsg;
                    transmitTime = sentMsg.lastTransmitTS(end)+obj.sampleTime;
                    sentMsg_new.lastTransmitTS = [sentMsg.lastTransmitTS(1),transmitTime];
                    element = BufferElement(transmitTime,sentMsg_new);
                    obj.msgBuffer.pushTop(element);
                    exectime = -1;
            end
            
        end
        
        function transmitTime = calculateTransmitTime(obj) 
            currenttime = ttCurrentTime();
            transmitTime = ceil(currenttime/obj.sampleTime)*obj.sampleTime;
            if(currenttime > transmitTime)
                error('This should not happen (fixed_tau too small), currenttime: %.3f, transmitTime: %.3f',currenttime, transmitTime)
            end
        end

        function init(obj)
            %init function creates the send and delay tasks.
            
            % clear the buffer
            obj.msgBuffer.clear;
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM') % deadline-monotonic scheduling
            
            % Sporadic network delay task, activated by arriving network message
            deadline = 0.1;     % maxinal time for calc
            ttCreateTask(obj.delayTaskName, deadline, obj.taskWrapperName, @obj.delay_code);
            ttAttachNetworkHandler(obj.delayTaskName)
            
            deadline = 0.1;     % maxinal time for calc
            ttCreateTask(obj.sendTaskName, deadline, obj.taskWrapperName, @obj.send_code);
            ttCreateJob(obj.sendTaskName);
        end        

        function generateSendTaskName(obj, nodeNr)
            % GenerateTaskName Sets the task name for the network buffer node.
            %
            % The task names is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier.

            obj.sendTaskName = ['SendTaskNode', num2str(nodeNr)];
            obj.delayTaskName = ['DelayTaskNode', num2str(nodeNr)];
        end
    end
end

