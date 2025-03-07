classdef SensorNode < NetworkNode
    % SensorNode Configures a TrueTime kernel as a sensor node.
    %
    % Properties:
    %   - samplingTime (double) : Sampling time for periodic measurements.
    %   - sequenceNumber (double) : Sequence number for messages.
    %   - waitbarHandle : Handle to the simulation progress waitbar.
    %   - simulationEnd (double) : End time of the simulation.
    %   - updateTime (double) : Time interval for updating the waitbar.
    %
    % Methods:
    %   - SensorNode(Nin, nextnode, nodenumber, samplingTime, simulationEnd)
    %   - init() : Initializes the TrueTime kernel and sensor task.
    %   - sampleStates(segment) : Periodically samples sensor data and sends messages.
    %   - delete() : Cleans up resources when the object is deleted.

    properties
        samplingTime double % Sampling time for periodic measurements
        sequenceNumber double % Sequence number for messages
        waitbarHandle % Handle to the simulation progress waitbar
        simulationEnd double % End time of the simulation
        updateTime double % Time interval for updating the waitbar
    end
    
    methods
        function obj = SensorNode(Nin, nextnode, nodenumber, samplingTime, simulationEnd)
            % SensorNode Constructor for a sensor node in the network.
            %
            % Example:
            %   sensor = SensorNode(2, [3,4], 1, 0.01, 10);
            
            % Initialize NetworkNode
            obj@NetworkNode(Nin, Nin, nextnode, nodenumber);
            obj.samplingTime = samplingTime;
            obj.sequenceNumber = 1;
            obj.simulationEnd = simulationEnd;
        end
        
        function init(obj)
            % init Creates a periodic task for sampling sensor data.
            
            obj.sequenceNumber = 1;
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create periodic sensor task
            startTime = 0.0;
            period = obj.samplingTime;
            ttCreatePeriodicTask(sprintf('sensorTaskNode%d', obj.nodenumber), startTime, period, ...
                obj.taskWrapperName, @obj.sampleStates);
            
            obj.updateTime = 0;
            
            % Initialize the simulation progress waitbar
            if ~isempty(obj.waitbarHandle) && isvalid(obj.waitbarHandle)
                close(obj.waitbarHandle);
            end
            obj.waitbarHandle = waitbar(0, 'Simulation Progress');
        end
        
        function [executionTime, obj] = sampleStates(obj, seg)
            % sampleStates Periodically samples sensor data and sends messages.
            
            sensorData = ttAnalogInVec(1:obj.Nin); % Read sensor data
            ttAnalogOutVec(1:obj.Nin, sensorData); % Output sensor data
            timestamp = ttCurrentTime();
            
            % Create and send network message
            txMsg = NetworkMsg(timestamp, timestamp, sensorData, obj.sequenceNumber);
            obj.sequenceNumber = obj.sequenceNumber + 1;
            
            for nextnode = obj.nextnode(:)' % Send to all connected nodes
                if nextnode
                    ttSendMsg(nextnode, txMsg, 80);
                end
            end
            
            executionTime = -1; % Indicate task completion
            
            % Update simulation progress waitbar
            progress = (ttCurrentTime() + obj.samplingTime) / obj.simulationEnd;
            progress = min(progress, 1);
            
            if any(obj.updateTime <= ttCurrentTime()) && isvalid(obj.waitbarHandle)
                obj.updateTime = obj.updateTime + obj.simulationEnd / 100;
                waitbar(progress, obj.waitbarHandle);
            end
            
            if progress >= 0.99 && isvalid(obj.waitbarHandle)
                close(obj.waitbarHandle);
            end
        end
        
        function delete(obj)
            % delete Cleans up resources when the object is deleted.
            if ~isempty(obj.waitbarHandle) && isvalid(obj.waitbarHandle)
                close(obj.waitbarHandle);
            end
        end
    end
end
