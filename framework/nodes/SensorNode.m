classdef SensorNode < NetworkNode
    % SensorNode Configures a TrueTime kernel as a sensor node.
    %
    % This class represents a sensor node in a networked control system.
    % The node samples sensor data and transmits it to the 
    % next node(s) in the network.
    % Aperiodic sampling is possible through modification
    %
    % Properties:
    %   - taskName (char) : Name of the TrueTime task.
    %   - sampleTime (double) : Sampling time for periodic measurements.
    %   - sequenceNumber (double) : Sequence number for messages.
    %   - waitbarHandle : Handle to the simulation progress waitbar.
    %   - simEnd (double) : End time of the simulation.
    %   - updateTime (double) : Time interval for updating the waitbar.
    %
    % Methods:
    %   - SensorNode(nIn, nextNode, nodeNr, sampleTime, simEnd)
    %   - init() : Initializes the TrueTime kernel and sensor task.
    %   - sampleStates(segment) : Periodically samples sensor data and sends messages.
    %   - delete() : Cleans up resources when the object is deleted.

    properties
        taskName char % Name of the TrueTime task
        sampleTime double % Sampling time for periodic measurements
        sequenceNumber double % Sequence number for messages
        waitbarHandle % Handle to the simulation progress waitbar
        simEnd double % End time of the simulation
        updateTime double % Time interval for updating the waitbar
    end
    
    methods
        function obj = SensorNode(nIn, nextNode, nodeNr, sampleTime, simEnd)
            % SensorNode Constructor for a sensor node in the network.
            %
            % Initializes the sensor node with input size, communication links,
            % and timing parameters.
            %
            % Inputs:
            %   - nIn (integer) : Number of sensor inputs.
            %   - nextNode (integer or vector) : IDs of the next nodes in the network.
            %   - nodeNr (integer) : Unique ID of this sensor node.
            %   - sampleTime (double) : Sampling period for periodic execution.
            %   - simEnd (double) : Total simulation time.

            % Call the parent class constructor (NetworkNode)
            obj@NetworkNode(nIn, nIn, nextNode, nodeNr);

            obj.generateTaskName(nodeNr);
            obj.sampleTime = sampleTime;
            obj.sequenceNumber = 1;
            obj.simEnd = simEnd;
        end
        
       
        function [executionTime, obj] = sampleStates(obj, ~)
            % sampleStates Periodically samples sensor data and sends messages.
            %
            % This method is triggered periodically to acquire sensor data,
            % package it into a network message, and transmit it to the next node(s).
            %
            % Outputs:
            %   - executionTime (double) : Execution time for this sensor task.
            
            sensorData = ttAnalogInVec(1:obj.nIn); % Read sensor data
            ttAnalogOutVec(1:obj.nIn, sensorData); % Output sensor data
            TS = ttCurrentTime();
            
            % Create and send network message
            txMsg = NetworkMsg(TS, TS, sensorData, obj.sequenceNumber, obj.nodeNr);
            obj.sequenceNumber = obj.sequenceNumber + 1;
            
            for nextNode = obj.nextNode(:)' % Send to all connected nodes
                if nextNode
                    ttSendMsg(nextNode, txMsg, 80);
                end
            end
            
            executionTime = -1; % Indicate task completion
            
            % Update simulation progress waitbar
            progress = (ttCurrentTime() + obj.sampleTime) / obj.simEnd;
            progress = min(progress, 1);
            
            if any(obj.updateTime <= ttCurrentTime()) && isvalid(obj.waitbarHandle)
                obj.updateTime = obj.updateTime + obj.simEnd / 100;
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
        
        function init(obj)
            % init Initializes the TrueTime kernel and creates the sensor task.
            %
            % This method initializes the TrueTime kernel, creates a  
            % task for sensor data acquisition, and initializes a waitbar for 
            % simulation progress.            

            obj.sequenceNumber = 1;
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create periodic sensor task
            startTime = 0.0;
            period = obj.sampleTime;
            ttCreatePeriodicTask(obj.taskName, startTime, period, ...
                obj.taskWrapperName, @obj.sampleStates);
            
            obj.updateTime = 0;
            
            % Initialize the simulation progress waitbar (GUI element)
            if ~isempty(obj.waitbarHandle) && isvalid(obj.waitbarHandle)
                close(obj.waitbarHandle);
            end
            obj.waitbarHandle = waitbar(0, 'Simulation Progress');
        end
 
        function generateTaskName(obj, nodeNr)
            % generateTaskName Sets the task name for the sensor node.
            %
            % The task name is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier.
            
            obj.taskName = ['SensorTaskNode', num2str(nodeNr)];
        end
    end
end
