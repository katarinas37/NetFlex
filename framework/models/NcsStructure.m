classdef NcsStructure < handle
    % NcsStructure Builder class for spatially distributed networked control systems.
    % Designs all necessary components for a networked control system.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : Specifies the control loop (plant, delays, etc.).
    %   - sensorNode (SensorNode) : Sensor node object.
    %   - tauCaNode (NetworkDelay) : Variable delay object from controller to actuator.
    %   - controllerNode (ControllerNode) : Controller node object.
    %   - simTime (double) : Largest simulation time.
    %   - allNodes (cell) [Dependent] : Returns all network nodes.
    %   - results (struct) [Dependent] : Contains simulation results.
    %
    % Methods:
    %   - NcsStructure(ncsPlant, 'simTime', value)
    %   - getMaxNodeNumber() : Returns the highest node number.
    %   - generateDelays() : Generates random delays.
    %   - get.results() : Retrieves the simulation results.

    properties (SetAccess = public)
        ncsPlant NcsPlant % NCS plant specification
        sensorNode SensorNode % Sensor node object
        simTime double % Largest simulation time
        tauCaNode NetworkDelay % Variable delay object from controller to actuator
        controllerNode ControllerNode % Controller node object
        controlParams struct % Control parameters for the controller
    end
    
    properties (Dependent)
        allnodes % Cell array of all nodes
        results % Simulation results
    end
    
    properties (Constant)
        SENSOR_NODE_NUMBER = 1 % Sensor node ID (lowest node number)
    end
    
    methods
        function obj = NcsStructure(ncsPlant, varargin)
            % NcsStructure Constructor for a spatially distributed NCS structure.
            %
            % Example:
            %   ncs = NcsPlant(sys, 3, 0.1);
            %   structure = NcsStructure(ncs, 'simTime', 10);
            
            % Validate input type
            if ~isa(ncsPlant, 'NcsPlant')
                error('NcsStructure:InvalidPlant', 'ncsPlant must be an instance of NcsPlant.');
            end
            
            % Input parsing
            p = inputParser;
            addParameter(p, 'simTime', 5000 * ncsPlant.samplingTime(), @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            addParameter(p, 'controlParams', struct(), @(x) isstruct(x)); % Allow empty struct
            parse(p, varargin{:});

            % Assign properties
            obj.ncsPlant = ncsPlant;
            obj.simTime = p.Results.simTime;
            obj.controlParams = p.Results.controlParams;
            
            % Generate network nodes
            obj.initializeNodes();
        end

        function initializeNodes(obj)
            % Initializes the sensor, controller, and delay nodes.
            actNodeNumber = obj.SENSOR_NODE_NUMBER + 1;
            controllerNodeNumber = actNodeNumber;
            delayCaNodeNumber = actNodeNumber + 1;

            tauCa = obj.generateDelays();
                
            % Create nodes
            obj.controllerNode = ControllerNode(delayCaNodeNumber, controllerNodeNumber, obj.ncsPlant, obj.controlParams.('StateFeedbackStrategy'), 'StateFeedbackStrategy');
            obj.tauCaNode = NetworkDelay(1, 0, delayCaNodeNumber, tauCa);
            obj.sensorNode = SensorNode(obj.ncsPlant.stateSize(), controllerNodeNumber, ...
                obj.SENSOR_NODE_NUMBER, obj.ncsPlant.samplingTime(), obj.simTime);
        end

        function tauCa = generateDelays(obj)
            % Generates random delays using network effect data.
            Td = obj.ncsPlant.samplingTime();
            
            % Check if the external file exists before loading
            if exist('networkeffects.mat', 'file') ~= 2
                error('NcsStructure:MissingFile', 'File "networkeffects.mat" not found.');
            end

            load('networkeffects.mat', 'tau_ca'); % Load only required variable
            
            % Ensure tauCa is properly scaled
            tauCa = ceil(tau_ca / 1e-4) * 1e-4;
        end

        function allNodes = get.allnodes(obj)
            % Returns a cell array of all nodes in the NCS.
            allNodes = [{obj.sensorNode}; {obj.controllerNode}; {obj.tauCaNode}];
        end

        function nr = getMaxNodeNumber(obj)
            %returns the maximum node number
            all_nodenumbers = cellfun(@(x) x.nodenumber,obj.allnodes);
            nr = max(all_nodenumbers);
        end
        
        function results = get.results(obj)
            % Retrieves simulation results in a structured format.
            
            % Controller output signal
            numSamples = length(obj.controllerNode.ukHist);
            timeVector = (0:(numSamples - 1)) * obj.ncsPlant.samplingTime();
            results.uk = timeseries(obj.controllerNode.ukHist, timeVector);
            results.uk.DataInfo.Interpolation = 'zoh';

            % Network delay times
            tauValues = cell2mat(cellfun(@(x) x.tau, obj.tauCaNode, 'UniformOutput', false)');
            results.tauCa = timeseries(tauValues, timeVector);
            results.tauCa.DataInfo.Interpolation = 'zoh';
        end
    end
end
