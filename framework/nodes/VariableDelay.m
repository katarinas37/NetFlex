classdef VariableDelay < NetworkNode & handle
    % VariableDelay Abstract class implementing a variable delay node.
    % In the abstract method calculateTransmitTime, the transmit time of each message is set.
    % The node transmits each message at the set transmit time to the next nodes.
    %
    % Properties:
    %   - messageBuffer (MsgBuffer) : Buffer storing messages for future transmission.
    %   - sendTaskName (string) : Name of the send task.
    %   - delayTaskName (string) : Name of the delay task.
    %
    % Methods:
    %   - VariableDelay(outputCount, nextNode, nodeNumber)
    %   - calculateTransmitTime(receivedMessage) : Abstract method to compute message transmit time.
    %   - delayCode(segment) : Processes incoming messages and schedules their transmission.
    %   - sendCode(segment) : Sends messages at the scheduled transmit time.
    %   - init() : Initializes the TrueTime kernel and delay tasks.

    properties
        messageBuffer MsgBuffer % Buffer to store messages scheduled for future transmission
        sendTaskName char % Task name of the send task
        delayTaskName char % Task name of the delay task
    end
    
    methods (Abstract)
        transmitTime = calculateTransmitTime(obj, receivedMessage) % Computes transmit time for each message
    end
    
    methods
        function obj = VariableDelay(outputCount, nextNode, nodeNumber)
            % VariableDelay Constructs a variable delay network node.
            %
            % Example:
            %   delayNode = VariableDelay(1, [2,3], 4);
            
            % Call parent constructor
            obj@NetworkNode(outputCount, 0, nextNode, nodeNumber);
            obj.generateSendTaskName(nodeNumber);
            obj.generateDelayTaskName(nodeNumber);
            obj.messageBuffer = MsgBuffer();
        end
        
        function [executionTime, obj] = delayCode(obj, seg)
            % delayCode Processes incoming messages and schedules their transmission.
            
            switch seg
                case 1
                    % Receive new message
                    receivedMessage = ttGetMsg();
                    if ~isa(receivedMessage, 'NetworkMsg')
                        error('VariableDelay:InvalidMessageType', 'Variable Delay can only process NetworkMsg objects.');
                    end
                    
                    % Compute transmission time
                    transmitTime = obj.calculateTransmitTime(receivedMessage);
                    receivedMessage.lastTransmitTimestamp = [receivedMessage.lastTransmitTimestamp(end), transmitTime];

                    if obj.messageBuffer.elementCount == 0 || transmitTime < obj.messageBuffer.getTop().transmitTime
                        % Cancel existing job, insert new packet at the beginning, and reschedule job
                        try
                            ttKillJob(obj.sendTaskName);
                        catch
                            warning('VariableDelay:KillJobFailed', 'Problem killing send task job.');
                        end
                        
                        % Insert new message at the top of the buffer
                        element = BufferElement(transmitTime, receivedMessage);
                        obj.messageBuffer.pushTop(element);
                        
                        % Schedule a new send job for the next packet
                        ttCreateJob(obj.sendTaskName);
                    else
                        % Insert the message into the buffer and sort by transmission time
                        element = BufferElement(transmitTime, receivedMessage);
                        obj.messageBuffer.pushBack(element);
                        obj.messageBuffer.sortBuffer();
                    end
                    
                    executionTime = -1;
            end
        end
        
        function [executionTime, obj] = sendCode(obj, seg)
            % sendCode Waits until the next message should be transmitted and sends it.
            
            switch seg
                case 1
                    % Sleep until the next message should be transmitted
                    if obj.messageBuffer.elementCount > 0
                        wakeUpTime = obj.messageBuffer.getTop().transmitTime;
                    else
                        wakeUpTime = 1e9;
                    end
                    ttSleepUntil(wakeUpTime);
                    executionTime = 0;
                    
                case 2
                    % If the transmit time has not been reached, go to sleep again
                    if obj.messageBuffer.getTop().transmitTime - ttCurrentTime() > 1e-8
                        ttSetNextSegment(1);
                    end
                    executionTime = 0;
                    
                case 3
                    % The transmit time has been reached -> send the message to the next node
                    
                    % Retrieve message from buffer
                    transmittedMessage = obj.messageBuffer.getTop().data;
                    
                    % Send to all next nodes
                    for nextNode = obj.nextnode
                        if nextNode ~= 0
                            ttSendMsg(nextNode, transmittedMessage, 80); % Send message (80 bits)
                        end
                    end
                    
                    % Output analog data
                    ttAnalogOutVec(1:obj.Nout, transmittedMessage.data);
                    
                    % Remove message from buffer
                    obj.messageBuffer.popTop();
                    
                    % Schedule the next job
                    ttCreateJob(obj.sendTaskName);
                    executionTime = -1;
            end
        end
        
        function init(obj)
            % init Initializes the TrueTime kernel and creates send/delay tasks.
            
            % Clear the message buffer
            obj.messageBuffer.clear();
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create sporadic network delay task, activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.delayTaskName, deadline, obj.taskWrapperName, @obj.delayCode);
            ttAttachNetworkHandler(obj.delayTaskName);
            
            % Create and schedule send task
            ttCreateTask(obj.sendTaskName, deadline, obj.taskWrapperName, @obj.sendCode);
            ttCreateJob(obj.sendTaskName);
        end

        function generateSendTaskName(obj, nodeNumber)
            % setTaskName Sets the task name for the controller node.
            obj.sendTaskName = ['SendTaskNode', num2str(nodeNumber)];
        end

        function generateDelayTaskName(obj, nodeNumber)
            % setTaskName Sets the task name for the controller node.
            obj.delayTaskName = ['DelayTaskNode', num2str(nodeNumber)];
        end
    end
end
