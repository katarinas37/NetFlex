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
            obj.observerParams = p.Results.observerParams;
            obj.nodeMap = containers.Map(); % Initialize empty dictionary

            % Step 1: Add all nodes without linking
            obj.createNodes();

            % Step 2: Set correct nextNode numbers
            obj.linkNodes();
      end

      function createNodes(obj)
          % Creates all nodes without linking them

          % Sensor Node
          obj.addNode("sensorNode", SensorNode(obj.ncsPlant.getStateSize(), 0, ...
              "sensorNode", obj.ncsPlant.getSampleTime(), obj.simTime));

          % Controller Node
          obj.addNode("controllerNode", ControllerNode(0, 0, obj.ncsPlant, obj.controlParams.Ramp, 'Ramp'));

          % Observer Node
          obj.addNode("observerNode", NetworkObserver(0, 0, obj.observerParams.SwitchLyapStrategy));

          % Delay Node
          tauCa = ceil(obj.config.tau_ca / 1e-4) * 1e-4;
          obj.addNode("delayNode", NetworkDelay(1, 0, 0, tauCa * 0));

          % Dropout Node
          obj.addNode("dropoutNode", NetworkDropoutSimple(1, 0, 0, obj.config.vec_ca));
      end

      function linkNodes(obj)
          % After all nodes exist, link them correctly

          % Define connections
          obj.nodeMap("sensorNode").nextNode = obj.nodeMap("controllerNode").nodeNr;
          obj.nodeMap("controllerNode").nextNode = obj.nodeMap("observerNode").nodeNr;
          obj.nodeMap("observerNode").nextNode = obj.nodeMap("delayNode").nodeNr;
          obj.nodeMap("delayNode").nextNode = obj.nodeMap("dropoutNode").nodeNr;
          obj.nodeMap("dropoutNode").nextNode = 0; % Final node
      end

        function addNode(obj, key, nodeObj)
            % Adds a node to the structure dynamically using a key
            obj.nodeMap(key) = nodeObj;
        end

        function nodeNr = getNextNodeNr(obj)
            % Returns the next available node number dynamically
            nodeNr = length(obj.nodeMap) + 1;
        end

        function count = getNodeCount(obj)
            % Returns the current number of nodes in nodeMap
            count = length(obj.nodeMap);
        end

        function allNodes = get.allNodes(obj)
            % Returns a cell array of all dynamically added nodes
            allNodes = values(obj.nodeMap);
        end

        function results = get.results(obj)
            % Retrieves simulation results in a structured format
            

            controllerNode = obj.nodeMap("ControllerNode"); % Retrieve by key
            % numSamples = length(controllerNode.ukHist); 
            timeVector = (0:(numSamples - 1)) * obj.ncsPlant.getSampleTime();
            
            % Controller output signal
            results.uk = timeseries(controllerNode.ukHist, timeVector);
            results.uk.DataInfo.Interpolation = 'zoh';

            % Network delay times
            delayNode = obj.nodeMap("DelayNode");
            tauValues = cell2mat(cellfun(@(x) x.tau, delayNode, 'UniformOutput', false)');
            results.tauCa = timeseries(tauValues, timeVector);
            results.tauCa.DataInfo.Interpolation = 'zoh';
        end

       function nodeNr = getMaxNodeNr(obj)
            % Returns the next available node number dynamically
            nodeNr = length(obj.nodeMap);
        end
    end
end
