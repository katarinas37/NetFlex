classdef ControllerNode < NetworkNode
    % ControllerNode Sets up the TrueTime kernel for a controller.
    % Implements control logic for a networked control system.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : The networked control system plant.
    %   - taskName (string) : Name of the TrueTime task. 
    %   - sendTimeHistory (double array) : Time instants when the controller sends signals.
    %   - controlSignalHistory (double array) : Control signals sent by the controller.
    %   - controlStrategy (string) : Control strategy used in the node
    %   - controlParams (struct) : Control parameters for the strategy
    %
    % Methods:
    %   - ControllerNode(nextNode, nodeNr, ncsPlant)
    %   - init() : Initializes the TrueTime kernel and controller.
    %   - evaluate(segment) : Executes the control logic.
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
            
            % Initialize NetworkNode
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
        
        function init(obj)
            % init Initializes the TrueTime kernel and resets controller states.
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create a sporadic controller task activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);
        end
        
        function [executionTime,obj] = evaluate(obj, ~)
            % evaluate Executes the control logic when a network message arrives
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
            ttSendMsg(obj.nextNode, sentMsg, 80);
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end

        function generateTaskName(obj, nodeNr)
            % setTaskName Sets the task name for the controller node.
            obj.taskName = ['ControllerTaskNode', num2str(nodeNr)];
        end
    end
end
