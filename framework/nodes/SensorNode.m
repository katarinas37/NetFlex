classdef SensorNode < NetworkNode
    %SENSORNODE Class to configure a truetime kernal as a sensor node
    
    properties
        Td %Sampling time
        seq %sequence number
        waitbar_handle
        simend
        t_toupdate
    end
    
    methods
        function obj = SensorNode(Nin, nextnode, nodenumber, Td,simend)
            %SensorNode(Nin, nextnode, nodenumber, Td)
            %Nin...Number of input elements
            %nextnode...Nodenumbers of the nodes, which should receive messages from this node
            %nodenumber...unique number of this node in the network
            obj@NetworkNode(Nin,Nin,nextnode,nodenumber);
            obj.Td = Td;
            obj.seq = 1;
            obj.simend = simend;
        end
        
        function init(obj)
            %INIT creates a periodic task for sampling the states
            obj.seq = 1;
            % Initialize TrueTime kernel
            ttInitKernel('prioDM');   % deadline-monotonic scheduling
            
            % Periodic sensor task
            starttime = 0.0;
            period = obj.Td;
            ttCreatePeriodicTask(sprintf('sensor_task_node%d',obj.nodenumber), starttime, period, obj.taskWrapperName, @obj.sample_states);
            
            obj.t_toupdate = 0;
            if(~isempty(obj.waitbar_handle) && isvalid(obj.waitbar_handle))
                close(obj.waitbar_handle)
            end
            obj.waitbar_handle = waitbar(0,'Simulation Progress');
        end
        
        function [exectime, obj] = sample_states(obj,seg)
            %sample_states is called periodically and sends the data to the nextnodes
            tx_data = ttAnalogInVec(1:obj.Nin);  % read data
            ttAnalogOutVec(1:obj.Nin,tx_data);
            timestamp = ttCurrentTime;           
            tx_msg = NetworkMsg(timestamp,timestamp,tx_data, obj.seq);
            obj.seq = obj.seq + 1;
            for nextnode = obj.nextnode(:)'
                if nextnode
                    ttSendMsg(nextnode, tx_msg, 80);
                end
            end
            
            % write data to output for plotting
            
            exectime = -1;
            
            progress = (ttCurrentTime+obj.Td)/obj.simend;
            progress = min(progress,1);
            if(any(obj.t_toupdate <= ttCurrentTime) && isvalid(obj.waitbar_handle))
                obj.t_toupdate = obj.t_toupdate + obj.simend/100;
                waitbar(progress,obj.waitbar_handle)
            end
            if(progress >= 0.99 && isvalid(obj.waitbar_handle))
                close(obj.waitbar_handle)
            end
        end
        function delete(obj)
           if ~isempty(obj.waitbar_handle) && isvalid(obj.waitbar_handle)
               close(obj.waitbar_handle)
           end
        end
    end
end

