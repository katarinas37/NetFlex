classdef SensorNode < NetworkNode
    % SensorNode Configures a TrueTime kernel as a sensor node.
    %
    % This class represents a sensor node in a networked control system. The 
    % node samples sensor data and transmits it to the next node(s) in the network.
    %
    % The system model used in this simulation is configured such that **all state 
    % variables** are available as outputs (`y = x`). However, the sensor node does 
    % not necessarily transmit all states; instead, it **selects specific outputs** 
    % based on the defined measurement model `cT`. 
    %
    % This means:
    %   - `nIn = stateSize`, since the sensor receives all system states from the plant.
    %   - The **actual output** sent over the network is determined by `outputVector* x`, 
    %     where `cT` is the sensor’s measurement matrix.
    %
    % This structure allows for flexibility in defining **partial state measurement** 
    % scenarios, while still simulating the entire system state evolution.
    %
    % Properties:
    %   - taskName (char) : Name of the TrueTime task.
    %   - sampleTime (double) : Sampling time for periodic measurements.
    %   - seqNr (double) : Sequence number for messages.
    %   - waitbarHandle : Handle to the simulation progress waitbar.
    %   - simEnd (double) : End time of the simulation.
    %   - outputVector(double) : Measurement matrix determining which states are sent.
    %   - updateTime (double) : Time interval for updating the waitbar.
    %
    % Methods:
    %   - SensorNode(nIn, nextNode, nodeNr, ncsPlant, simEnd)
    %   - init() : Initializes the TrueTime kernel and sensor task.
    %   - sampleStates(segment) : Periodically samples sensor data and sends messages.
    %   - delete() : Cleans up resources when the objeoutputVectoris deleted.

    properties
        taskName char % Name of the TrueTime task
        seqNr double % Sequence number for messages
        sampleTime double % Sampling time for periodic measurements
        simEnd double % End time of the simulation
        outputVector double % output vector
        waitbarHandle % Handle to the simulation progress waitbar
        updateTime double % Time interval for updating the waitbar

        rcvHistoryTime
        rcvHistory
        rcvHistoryData
        sendHistoryTime
        sendHistory
        sendHistoryData
    end
    
    methods
        function obj = SensorNode(nIn, nextNode, nodeNr, ncsPlant, simEnd)
            % SensorNode Constructor for a sensor node in the network.
            %
            % Initializes the sensor node with input size, communication links,
            % and timing parameters.
            %
            % Inputs:
            %   - nIn (integer) : Number of system states (`stateSize`).
            %   - nextNode (integer or vector) : IDs of the next nodes in the network.
            %   - nodeNr (integer) : Unique ID of this sensor node.
            %   - ncsPlant (NcsPlant) : Reference to the plant model.
            %   - simEnd (double) : Total simulation time.
            %
            % Note:
            % The **sensor input size (`nIn`) is equal to the number of system states (`stateSize`)** 
            % because the system is configured to output all states. However, the **actual sensor 
            % output sent over the network is determined by the measurement model `cT`**.

            % Call the parent class constructor (NetworkNode)
            obj@NetworkNode(nIn, nIn, nextNode, nodeNr);

            obj.generateTaskName(nodeNr);
            obj.seqNr = 1;
            obj.sampleTime = ncsPlant.sampleTime;
            obj.simEnd = simEnd;
            obj.outputVector= ncsPlant.system.c;

            obj.rcvHistoryTime = [];
            obj.rcvHistory = [];
            obj.rcvHistoryData = [];
            obj.sendHistoryTime = [];
            obj.sendHistory = [];
            obj.sendHistoryData = [];
        end
        
       
        function [executionTime, obj] = sampleStates(obj, ~)
           % sampleStates Periodically samples sensor data and sends messages.
            %
            % This method is triggered periodically to acquire sensor data,
            % package it into a network message, and transmit it to the next node(s).
            %
            % The sensor reads **all system states** but **only transmits selected outputs** 
            % defined by `cT`. This allows simulation of partial-state measurement scenarios.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for this sensor task.
            
            sensorData = obj.outputVector*ttAnalogInVec(1:obj.nIn)'; % Read sensor data (only output)

            

            ttAnalogOutVec(1:obj.nIn, ttAnalogInVec(1:obj.nIn)); % Output all system data
            TS = ttCurrentTime();
            
            obj.rcvHistoryTime = [obj.rcvHistoryTime,TS];
            obj.rcvHistory = [];
            obj.rcvHistoryData = [obj.rcvHistoryData, sensorData]; 

            % Create and send network message
            sentMsg = NetworkMsg(TS, TS, sensorData, obj.seqNr, obj.nodeNr);
            obj.seqNr = obj.seqNr + 1;
            
            for nextNode = obj.nextNode(:)' % Send to all connected nodes
                if nextNode
                    ttSendMsg(nextNode, sentMsg, 80);
                end
            end
            
            executionTime = -1; % Indicate task completion
            transmitTime = TS;
            obj.sendHistoryTime = [obj.sendHistoryTime, transmitTime];
            obj.sendHistory = [obj.sendHistory, sentMsg];
            obj.sendHistoryData = [obj.sendHistoryData, sentMsg.data];

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
            %
            % - The sensor task is **periodic** and runs at `sampleTime` intervals.
            % - The waitbar provides a visual representation of simulation progress.

            % Reset sequence number
            obj.seqNr = 1;
            
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
