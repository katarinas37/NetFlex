classdef NcsStructure < handle
    % NcsStructure Builder class for spatially distributed networked control systems.
    %
    % This class defines the structure of a Networked Control System (NCS), 
    % including its nodes (sensor, controller, delays, etc.), simulation parameters, 
    % and network effects.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : Specifies the control loop (plant, delays, etc.).
    %   - simTime (double) : Maximum simulation time.
    %   - networkEffectsData (struct) : Defines network effects (delays, dropouts, etc.).
    %   - controlParams (struct) : Control parameters for the controller.
    %   - observerParams (struct) : Observer parameters for state estimation.
    %   - nodeMap (containers.Map) : Dictionary storing all dynamically created nodes.
    %
    % Dependent Properties:
    %   - allNodes (cell) : Returns all network nodes in a cell array.
    %   - results (struct) : Contains simulation results.
    %
    % Methods:
    %   - NcsStructure(ncsPlant, 'simTime', value) : Constructor.
    %   - createNodes() : Creates and registers nodes dynamically.
    %   - addNode(key, nodeObj) : Adds a node to the nodeMap.
    %   - getMaxNodeNr() : Returns the highest assigned node number.
    %   - get.allNodes() : Retrieves all nodes in a cell array.
    %   - get.results() : Retrieves simulation results.
    
    properties (SetAccess = public)
        ncsPlant NcsPlant % NCS plant specification (system model)
        simTime double % Maximum simulation time
        networkEffectsData struct % Definition of network effects (delays, dropouts, etc.)
        controlParams struct % Controller parameters
        observerParams struct % Observer parameters
        nodeMap % Dictionary to store all nodes dynamically
    end
    
    properties (Dependent)
        allNodes % Returns a cell array of all registered nodes
        results % Contains simulation results
    end
    
    methods
        function obj = NcsStructure(ncsPlant, varargin)
        % Constructor for NcsStructure
        %
        % Inputs:
        %   - ncsPlant (NcsPlant) : The plant model defining the NCS.
        %   - 'simTime' (double, optional) : Maximum simulation time.
        %   - 'networkEffectsData' (struct, optional) : Network effects settings.
        %   - 'controlParams' (struct, optional) : Controller parameters.
        %   - 'observerParams' (struct, optional) : Observer parameters.
        
        % Validate that ncsPlant is of type NcsPlant
        if ~isa(ncsPlant, 'NcsPlant')
            error('NcsStructure:InvalidPlant', 'ncsPlant must be an instance of NcsPlant.');
        end
        
        % Input parsing
        p = inputParser;
        addParameter(p, 'simTime', 5000 * ncsPlant.sampleTime, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
        addParameter(p, 'networkEffectsData', struct(), @(x) isstruct(x)); % !!!
        addParameter(p, 'controlParams', struct(), @(x) isstruct(x)); % Allow empty struct
        addParameter(p, 'observerParams', struct(), @(x) isstruct(x)); % Allow empty struct
        parse(p, varargin{:});
        
        % Assign properties
        obj.ncsPlant = ncsPlant;
        obj.simTime = p.Results.simTime;
        obj.networkEffectsData = p.Results.networkEffectsData;
        obj.controlParams = p.Results.controlParams;
        obj.controlParams = p.Results.controlParams;
        obj.observerParams = p.Results.observerParams;
        obj.nodeMap = containers.Map(); % Initialize empty dictionary
        % Add all nodes and link them
        obj.createNodes();
      end

      function createNodes(obj)
            % createNodes Creates and registers all required network nodes.
            %
            % This method assigns unique node numbers and initializes all nodes.

            % Initialize node numbering
            % The assigned node numbers must be sequential without missing values.
            % However, the numbering does not necessarily correspond to the topology 
            % of the system. It is used solely for unique identification.
            cnt = 0;

            sensorNodeNr = cnt+1;
            controllerNodeNr = cnt+2;
 
            % Sensor Node
            obj.addNode("SensorNode", ...
            SensorNode(obj.ncsPlant.stateSize, controllerNodeNr, sensorNodeNr,obj.ncsPlant.sampleTime, obj.simTime) ...
            );
            % Controller Node
            obj.addNode("ControllerNode", ...
            ControllerNode(0, controllerNodeNr, obj.ncsPlant, obj.controlParams.Ramp, 'Ramp') ...
            );

            % Additional nodes can be added here if required
      end

        function addNode(obj, key, nodeObj)
            % addNode Adds a node to the nodeMap dynamically.
            %
            % Inputs:
            %   - key (string) : The key to store the node under (e.g., "SensorNode").
            %   - nodeObj (object) : The node object to be stored.
            obj.nodeMap(key) = nodeObj;
        end

       function nodeNr = getMaxNodeNr(obj)
            % getMaxNodeNr Returns the highest assigned node number.
            % used in Simulink (TrueTime network)
            %
            % Outputs:
            %   - nodeNr (integer) : The number of nodes currently registered.
            nodeNr = length(obj.nodeMap);
        end

        function allNodes = get.allNodes(obj)
            % get.allNodes Returns a cell array of all registered nodes.
            %
            % Outputs:
            %   - allNodes (cell array) : Contains all nodes added via addNode().
            allNodes = values(obj.nodeMap);
        end

        function results = get.results(obj)
            % get.results Retrieves simulation results for post-processing.
            % Depending on the defined nodes and their properties,
            % additional data can be stored
            %
            % Outputs:
            %   - results (struct) : Contains simulation output data.
            

            controllerNode = obj.nodeMap("ControllerNode"); % Retrieve by key
            numSamples = length(controllerNode.controlSignalHistory); 
            timeVector = (0:(numSamples - 1)) * obj.ncsPlant.sampleTime();
            
            % Controller output signal
            results.uk = timeseries(controllerNode.controlSignalHistory, timeVector);
            results.uk.DataInfo.Interpolation = 'zoh';
        end


    end
end
