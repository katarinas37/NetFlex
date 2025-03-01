classdef VariableDelay < NetworkNode & handle
    %VARIABLEDELAY Abstract class which implements a variable delay node. 
    %In the abstract method calculate_transmit_time the transmit time of each message is set.
    %The node transmits each message at the set transmit time to the nextnodes.
    %See also: MsgBuffer, NetworkNode, BufferElement, NetworkMsg
    
    properties
        buffer MsgBuffer %Buffer to store messages which should be transmitted in future
        sendtaskname %taskname of the send task
        delaytaskname %taskname of the delay task
    end
    
    methods (Abstract)
        transmit_time = calculate_transmit_time(obj, rx_msg) %Abstract function to specify the transmit time for each message
    end
    
    methods
        function obj = VariableDelay(Nout, nextnode, nodenumber)
            %See also NetworkNode
            obj@NetworkNode(Nout,0,nextnode,nodenumber);
            obj.sendtaskname = sprintf('send_task_node%d',nodenumber);
            obj.delaytaskname = sprintf('delay_task_node%d',nodenumber);
            obj.buffer = MsgBuffer();
        end
        
        function [exectime, obj] = delay_code(obj, seg)
            %Function gets calld, when a new message is received.
            %The transmit time is computed and a job is created for the message, which should be sent next
            switch seg
                case 1
                    % Get the new message
                    rx_msg = ttGetMsg;
                    if(~isa(rx_msg, 'NetworkMsg'))
                        error('Variable Delay can only deal with NetworkMsg objects')
                    end
                    % Compute the transmit times
                    t_transmit = obj.calculate_transmit_time(rx_msg);
                    rx_msg.last_transmit_timestamp = [rx_msg.last_transmit_timestamp(end),t_transmit];
%                     rx_msg.last_transmit_timestamp = t_transmit;
                    if obj.buffer.elementCount == 0 || t_transmit<obj.buffer.top.transmit_time
                        % cancel actual job, insert data at beginning and schedule job again
                        try
                            ttKillJob(obj.sendtaskname);
                        catch
                            warning('send_delayed_task: Problem killing send_delay job')
                        end
                        % insert actual packet at the beginning of the buffer
                        element = BufferElement(t_transmit,rx_msg);
                        obj.buffer.push_top(element);
                        
                        %Create new send job for the new packet
                        ttCreateJob(obj.sendtaskname);
                        
                    else % there is a packet in the buffer, which should be transmitted before this packet,
                        % so insert tis packet in the buffer
                        element = BufferElement(t_transmit,rx_msg);
                        obj.buffer.push_back(element);
                        sort(obj.buffer);
                    end
                    %ttSetData(obj.sendtaskname,obj);
                    exectime = -1;
            end
        end
        
        function [exectime, obj] = send_code(obj, seg)
            %Waits until the next message should be transmitted and sends it to the next node
            switch seg
                case 1
                    %Sleep until the next packet should be transmitted
                    if obj.buffer.elementCount
                        wakeuptime = obj.buffer.top.transmit_time;
                    else
                        wakeuptime = 1e9;
                    end
                    ttSleepUntil(wakeuptime);
                    exectime = 0;
                case 2
                    %If the transmit time has not been reached, go to sleep again
                    if obj.buffer.top.transmit_time - ttCurrentTime >1e-8
                        ttSetNextSegment(1);
                    end
                    exectime = 0;
                case 3
                    %the transmit time has ben reached -> send the message to the nextnode
                    %get data
                    tx_msg = obj.buffer.top.data;
                    
                    for nextnode = obj.nextnode
                        if(nextnode ~= 0)
                            ttSendMsg(nextnode, tx_msg, 80); % Send message (80 bits) to next node 5 (actuator)
                        end
                    end
                    ttAnalogOutVec(1:obj.Nout,tx_msg.data);
                    % clear the data from the buffer
                    obj.buffer.pop_top;
                    
                    % schedule next job
                    ttCreateJob(obj.sendtaskname);
                    exectime = -1;
            end
            
        end
        
        
        function init(obj)
            %init function creates the send and delay tasks.
            
            % clear the buffer
            obj.buffer.clear;
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM') % deadline-monotonic scheduling
            
            % Sporadic network delay task, activated by arriving network message
            deadline = 0.1;     % maxinal time for calc
            ttCreateTask(obj.delaytaskname, deadline, obj.taskWrapperName, @obj.delay_code);
            ttAttachNetworkHandler(obj.delaytaskname)
            
            deadline = 0.1;     % maxinal time for calc
            ttCreateTask(obj.sendtaskname, deadline, obj.taskWrapperName, @obj.send_code);
            ttCreateJob(obj.sendtaskname);
        end        
    end
end

