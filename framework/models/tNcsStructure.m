classdef tNcsStructure < handle
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
        simTime double % Largest simulation time
        controlParams struct % Control parameters for the controller
        observerParams struct % Observer parameters for the observer
        nodeMap % Dictionary for all nodes
        config struct % Configuration settings from the config file
    end
    
    properties (Dependent)
        allNodes % Cell array of all nodes
        results % Simulation results
    end
    
    methods
        function obj = tNcsStructure(ncsPlant, configFile, varargin)
            % NcsStructure Constructor for a spatially distributed NCS structure.
            %
            % Example:
            %   ncs = NcsPlant(sys, 3, 0.1);
            %   structure = NcsStructure(ncs, 'simTime', 10);
            
            obj.config = ConfigUtils.parseConfigFile(configFile); % Use external utility function

            
            % Validate input type
            if ~isa(ncsPlant, 'NcsPlant')
                error('NcsStructure:InvalidPlant', 'ncsPlant must be an instance of NcsPlant.');
            end
            
            % Input parsing
            p = inputParser;
            addParameter(p, 'simTime', 5000 * ncsPlant.sampleTime, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            addParameter(p, 'controlParams', struct(), @(x) isstruct(x)); % Allow empty struct
            addParameter(p, 'observerParams', struct(), @(x) isstruct(x)); % Allow empty struct
            parse(p, varargin{:});

            % Assign properties
            obj.ncsPlant = ncsPlant;
            obj.simTime = p.Results.simTime;
            obj.controlParams = p.Results.controlParams;
            obj.nodeMap = containers.Map(); % Initialize empty dictionary
            
            % Generate network nodes
            obj.initializeNodes();
        end

        function initializeNodes(obj)
            tauCa = ceil(obj.config.tau_ca / 1e-4) * 1e-4; % Ensure proper scaling

            % Add SensorNode
            obj.addNode("SensorNode", SensorNode(obj.ncsPlant.stateSize, obj.getNextNodeNr(), ...
                "SensorNode", obj.ncsPlant.sampleTime, obj.simTime));
            
            % Add ControllerNode
            obj.addNode("controllerNode", ControllerNode(obj.getNextNodeNr(), obj.nodeMap("SensorNode").nodeNr, ...
                obj.ncsPlant, obj.controlParams.Ramp, 'Ramp'));

            % Add DelayNode (NetworkDelay)
            obj.addNode("delayNode", NetworkDelay(1, obj.getNextNodeNr(), obj.nodeMap("controllerNode").nodeNr, tauCa * 0));

            % Add DropoutNode (NetworkDropoutSimple)
            obj.addNode("dropoutNode", NetworkDropoutSimple(1, 0, obj.getNextNodeNr(), obj.config.vec_ca));
        end

        function addNode(obj, key, nodeObj)
            % Adds a node to the structure dynamically using a key
            obj.nodeMap(key) = nodeObj;
        end

        function nodeNr = getNextNodeNr(obj)
            % Returns the next available node number dynamically
            nodeNr = length(obj.nodeMap) + 1;
        end

        function allNodes = get.allNodes(obj)
            % Returns a cell array of all dynamically added nodes
            allNodes = values(obj.nodeMap);
        end

        function results = get.results(obj)
            % Retrieves simulation results in a structured format
            
            controllerNode = obj.nodeMap("controllerNode"); % Retrieve by key
            numSamples = length(controllerNode.ukHist); 
            timeVector = (0:(numSamples - 1)) * obj.ncsPlant.getSampleTime();
            
            % Controller output signal
            results.uk = timeseries(controllerNode.ukHist, timeVector);
            results.uk.DataInfo.Interpolation = 'zoh';

            % Network delay times
            delayNode = obj.nodeMap("delayNode");
            tauValues = cell2mat(cellfun(@(x) x.tau, delayNode, 'UniformOutput', false)');
            results.tauCa = timeseries(tauValues, timeVector);
            results.tauCa.DataInfo.Interpolation = 'zoh';
        end
    end
end
