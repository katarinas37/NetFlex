classdef ObserverNode < NetworkNode & handle
    % ObserverNode: Implements an observer node for estimating states in an NCS.
    % 
    % See also: NetworkNode
    
    properties
        taskName char % TrueTime task name
        ncsPlant NcsPlant % Networked control system plant
        sendTimeHistory double % Time instants when signals were sent
        estimatesHistory double % Observer state history
        observerStrategy % Observer strategy used in the node
        observerParams % Observer parameters for the strategy
    end
    
    methods
        function obj = ObserverNode(nextNode, nodeNr, ncsPlant, observerParams, strategyClass)
            % Constructor for ObserverNode
            
            obj@NetworkNode(ncsPlant.stateSize, 0, nextNode, nodeNr);
            obj.generateTaskName(nodeNr);
            
            obj.estimatesHistory = zeros(obj.ncsPlant.stateSize, 1); % Initial state estimate
            obj.ncsPlant = ncsPlant;
            
            % Validate controlParams and instantiate the strategy
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
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);            
        end

        
        function [executionTime, obj] = evaluate(obj, ~)
            % TrueTime task function for observer
            
            receivedMsg = ttGetMsg();

            % Execute selected observer strategy dynamically
            estimates = obj.observerStrategy.execute(receivedMsg, obj.observerParams, obj.ncsPlant);

            % Update
            obj.estimatesHistory = [obj.estimatesHistory; estimates];
            obj.sendTimeHistory = [obj.sendTimeHistory; ttCurrentTime()];
            
            sentMsg = receivedMsg;
            sentMsg.data = estimates;
            ttSendMsg(obj.nextnode, sentMsg, 80); % Send message (80 bits) to next node
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end

        function generateTaskName(obj, nodeNumber)
            % setTaskName Sets the task name for the observer node.
            obj.taskName = ['ObserverTaskNode', num2str(nodeNumber)];
        end
    end
end
