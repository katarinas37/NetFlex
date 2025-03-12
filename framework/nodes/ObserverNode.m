classdef ObserverNode < NetworkNode & handle
    % ObserverNode Sets up the TrueTime kernel for an observer.
    % Implements observer logic for a networked control system.
    %
    % The observer node receives system data, estimates the state,
    % and sends the estimated state to the next node in the network.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : The networked control system plant.
    %   - taskName (char) : Name of the TrueTime task.
    %   - sendTimeHistory (double array) : Time instants when the observer sends signals.
    %   - estimatesHistory (double array) : State estimates sent by the observer.
    %   - observerStrategy (object) : Observer strategy used in the node.
    %   - observerParams (struct) : Observer parameters for the strategy.
    %
    % Methods:
    %   - ObserverNode(nextNode, nodeNr, ncsPlant, observerParams, strategyClass)
    %   - init() : Initializes the TrueTime kernel and observer.
    %   - evaluate(segment) : Executes the observer logic.
    %   - generateTaskName(nodeNr) : Generates a unique task name for the node.
    %
    % See also: NetworkNode
    
    properties
        ncsPlant NcsPlant % Networked control system plant
        taskName char % TrueTime task name
        sendTimeHistory double % Time instants when signals were sent
        estimatesHistory double % Observer state history
        observerStrategy % Observer strategy used in the node
        observerParams % Observer parameters for the strategy
    end
    
    methods
        function obj = ObserverNode(nextNode, nodeNr, ncsPlant, observerParams, strategyClass)
          % ObserverNode Constructor for an observer node in the network.
            %
            % This constructor initializes the observer node, assigns it an observer 
            % strategy, and sets up message passing to the next node.
            %
            % Inputs:
            %   - nextNode (integer) : Identifier of the next node in the network.
            %   - nodeNr (integer) : Unique identifier for this observer node.
            %   - ncsPlant (NcsPlant) : Reference to the controlled system model.
            %   - observerParams (struct) : Contains parameters for the observer strategy.
            %   - strategyClass (string) : Name of the observer strategy class to be instantiated.

            % Call the parent class constructor (NetworkNode)
            obj@NetworkNode(ncsPlant.stateSize, 0, nextNode, nodeNr);
            
            obj.generateTaskName(nodeNr);
            obj.ncsPlant = ncsPlant;
            obj.observerParams = observerParams;
            obj.estimatesHistory = zeros(obj.ncsPlant.stateSize, 1); % Initial state estimate
            obj.sendTimeHistory = [];

            % Validate observerParams and instantiate the strategy
            if isstruct(observerParams)
                if exist(strategyClass, 'class') == 8 % Check if class exists
                    obj.observerStrategy = feval(strategyClass, ncsPlant); % Instantiate object dynamically
                else
                    error('ObserverNode:InvalidStrategy', 'Observer strategy "%s" class does not exist.', strategyClass);
                end
            else
                error('ObserverNode:MissingStrategy', 'observerParams must contain a valid strategy field.');
            end
        end

        function [executionTime, obj] = evaluate(obj, ~)
            % Evaluate Executes the observer logic when a network message arrives.
            %
            % This method is triggered when a message arrives at the observer node. 
            % It retrieves the message, applies the observer strategy, and transmits 
            % the estimated state to the next node.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for the observer task.

            % Retrieve incoming network message
            rcvMsg = ttGetMsg(); % Retrieve incoming network message
            currentTime = ttCurrentTime();

            % Execute selected observer strategy dynamically
            [estimates,obj.observerStrategy] = obj.observerStrategy.execute(rcvMsg, obj.observerParams, obj.ncsPlant);

            % Update
            obj.estimatesHistory = [obj.estimatesHistory, estimates];
            obj.sendTimeHistory = [obj.sendTimeHistory; currentTime];
            
            % Transmit results to the next node
            sentMsg = rcvMsg;
            sentMsg.data = estimates;
            sentMsg.nodeId = obj.nodeNr;
            for nextNode = obj.nextNode(:)'
                if nextNode
                    ttSendMsg(obj.nextNode, sentMsg, 80);
                end
            end
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end
        
        function init(obj)            
            % Init Initializes the TrueTime kernel and resets observer states.
            %
            % This method sets up the TrueTime kernel and attaches the network 
            % message handler to respond to incoming messages.

            % Initialize TrueTime kernel with priority scheduling
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create a sporadic observer task activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);            
        end

        function generateTaskName(obj, nodeNumber)
            % GenerateTaskName Sets the task name for the observer node.
            %
            % The task name is generated dynamically based on the node number 
            % to ensure unique task identification.
            %
            % Inputs:
            %   - nodeNumber (integer) : Unique node identifier.
            
            obj.taskName = ['ObserverTaskNode', num2str(nodeNumber)];
        end
    end
end
