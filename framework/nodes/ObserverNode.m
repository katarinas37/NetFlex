classdef ObserverNode < NetworkNode & handle
    % ObserverNode Sets up the TrueTime kernel for an observer.
    % Implements observer logic for a networked control system.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : The networked control system plant.
    %   - taskName (string) : Name of the TrueTime task.
    %   - sendTimeHistory (double array) : Time instants when the observer sends signals.
    %   - estimatesHistory (double array) : State estimates sent by the observer.
    %   - observerStrategy (string) : Observer strategy used in the node
    %   - observerParams (struct) : Observer parameters for the strategy
    %
    % Methods:
    %   - ObserverNode(nextNode, nodeNr, ncsPlant)
    %   - init() : Initializes the TrueTime kernel and observer.
    %   - evaluate(segment) : Executes the observer logic.
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
            % Constructor for ObserverNode
            
            % Initialize NetworkNode
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
        
        function init(obj)            
            % init Initializes the TrueTime kernel and resets observer states.
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create a sporadic observer task activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);            
        end

        function [executionTime, obj] = evaluate(obj, ~)
            % evaluate Executes the control logic when a network message arrives            
            rcvMsg = ttGetMsg(); % Retrieve incoming network message
            currentTime = ttCurrentTime();

            % Execute selected observer strategy dynamically
            [estimates,obj.observerStrategy] = obj.observerStrategy.execute(rcvMsg, obj.observerParams, obj.ncsPlant);

            % Update
            obj.estimatesHistory = [obj.estimatesHistory; estimates];
            obj.sendTimeHistory = [obj.sendTimeHistory; currentTime];
            
            % Transmit results to the next node
            sentMsg = rcvMsg;
            sentMsg.data = estimates;
            ttSendMsg(obj.nextNode, sentMsg, 80); % Send message (80 bits) to next node
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end

        function generateTaskName(obj, nodeNumber)
            % setTaskName Sets the task name for the observer node.
            obj.taskName = ['ObserverTaskNode', num2str(nodeNumber)];
        end
    end
end
