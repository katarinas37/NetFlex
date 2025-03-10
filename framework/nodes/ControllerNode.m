classdef ControllerNode < NetworkNode
    % ControllerNode Sets up the TrueTime kernel for a controller.
    % Implements control logic for a networked control system.
    %
    % This node is responsible for computing control inputs based on received 
    % state information and executing a predefined control strategy.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : The networked control system plant.
    %   - taskName (string) : Name of the TrueTime task. 
    %   - sendTimeHistory (double array) : Time instants when the controller sends signals.
    %   - controlSignalHistory (double array) : Control signals sent by the controller.
    %   - controlStrategy (object) : Control strategy used in the node.
    %   - controlParams (struct) : Control parameters for the strategy.
    %
    % Methods:
    %   - ControllerNode(nextNode, nodeNr, ncsPlant, controlParams, strategyClass)
    %   - init() : Initializes the TrueTime kernel and controller.
    %   - evaluate(segment) : Executes the control logic upon receiving a message.
    %   - generateTaskName(nodeNr) : Generates a unique task name for the node.
    %
    % See also: NetworkNode

    properties 
        ncsPlant NcsPlant % Networked control system plant
        taskName char % Name of the TrueTime task
        sendTimeHistory double % Time instants when signals were sent
        controlSignalHistory double % Control signals sent
        controlStrategy % Control strategy used in the node
        controlParams % Control parameters for the strategy
    end
    
    methods
        function obj = ControllerNode(nextNode, nodeNr, ncsPlant, controlParams, strategyClass)
            % ControllerNode Constructor for a controller node in the network.
            %
            % This constructor initializes the controller node, assigns it a control 
            % strategy, and sets up message passing to the next node.
            %
            % Inputs:
            %   - nextNode (integer) : Identifier of the next node in the network.
            %   - nodeNr (integer) : Unique identifier for this controller node.
            %   - ncsPlant (NcsPlant) : Reference to the controlled system model.
            %   - controlParams (struct) : Contains parameters for the control strategy.
            %   - strategyClass (string) : Name of the control strategy class to be instantiated.

            % Call the parent class constructor (NetworkNode)
            obj@NetworkNode(ncsPlant.inputSize, 0, nextNode, nodeNr);
            
            obj.generateTaskName(nodeNr);
            obj.ncsPlant = ncsPlant;
            obj.controlParams = controlParams;
            obj.controlSignalHistory = [];
            obj.sendTimeHistory = [];

            % Validate controlParams and instantiate the strategy
            if isstruct(controlParams)
                if exist(strategyClass, 'class') == 8 % Check if class exists
                    obj.controlStrategy = feval(strategyClass, ncsPlant); % Instantiate object dynamically
                else
                    error('ControllerNode:InvalidStrategy', 'Control strategy "%s" class does not exist.', strategyClass);
                end
            else
                error('ControllerNode:MissingStrategy', 'controlParams must contain a valid strategy field.');
            end
        end
        
        
        function [executionTime,obj] = evaluate(obj, ~)
            % evaluate Executes the control logic when a network message arrives.
            %
            % This method is triggered when a message arrives at the controller node. 
            % It retrieves the message, applies the control strategy, and transmits 
            % the computed control signal to the next node.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for the control task.
            
            rcvMsg = ttGetMsg(); % Retrieve incoming network message
            currentTime = ttCurrentTime();

            % Execute selected control strategy dynamically
            [controlSignal,obj.controlStrategy] = obj.controlStrategy.execute(rcvMsg, obj.controlParams, obj.ncsPlant);

            % update
            obj.controlSignalHistory = [obj.controlSignalHistory; controlSignal];
            obj.sendTimeHistory = [obj.sendTimeHistory; currentTime];

            % Transmit results to the next node
            sentMsg = rcvMsg;
            sentMsg.data = controlSignal;
            sentMsg.nodeId = obj.nodeNr;
            ttSendMsg(obj.nextNode, sentMsg, 80);
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end
        
        function init(obj)
            % init Initializes the TrueTime kernel and resets controller states.
            %
            % This method sets up the TrueTime kernel and attaches the network 
            % message handler to respond to incoming messages.
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create a sporadic controller task activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);
        end

        function generateTaskName(obj, nodeNr)
            % generateTaskName Sets the task name for the controller node.
            %
            % The task name is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier.
            
            obj.taskName = ['ControllerTaskNode', num2str(nodeNr)];
        end
    end
end
