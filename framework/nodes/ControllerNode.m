classdef ControllerNode < NetworkNode
    % ControllerNode Sets up the TrueTime kernel for a controller.
    % Implements control logic for a networked control system.
    %
    % Properties:
    %   - ncsPlant (NcsPlant) : The networked control system plant.
    %   - taskName (string) : Name of the TrueTime task.
    %   - delayedControlSignals (double array) : Delayed control signal history.
    %   - liftedStateHistory (double matrix) : Lifted states [xk; uk-1; uk-2; ... ; uk_deltabar].
    %   - controlSignalHistory (double array) : Control signals sent by the controller.
    %   - sendTimeHistory (double array) : Time instants when the controller sends signals.
    %
    % Methods:
    %   - ControllerNode(nextnode, nodeNr, ncsPlant)
    %   - init() : Initializes the TrueTime kernel and controller.
    %   - evaluate(segment) : Executes the control logic.

    properties 
        ncsPlant NcsPlant % Networked control system plant
        taskName char % Name of the TrueTime task
        delayedControlSignals double % Delayed control signals
        liftedStateHistory double % Lifted states history
        controlSignalHistory double % Control signals sent
        sendTimeHistory double % Time instants when signals were sent
        controlStrategy % Control strategy used in the node
        controlParams % Control parameters for the strategy
    end
    
    methods
        function obj = ControllerNode(nextNode, nodeNr, ncsPlant, controlParams, strategyClass)
            % ControllerNode Constructor for a controller node in the network.
            %
            % Example:
            %   controller = ControllerNode(2, 1, ncsPlant);
            
            % Initialize NetworkNode
            obj@NetworkNode(ncsPlant.inputSize, 0, nextNode, nodeNr);
            obj.generateTaskName(nodeNr);

            obj.ncsPlant = ncsPlant;
            obj.delayedControlSignals = zeros(obj.ncsPlant.delaySteps, 1);
            obj.controlParams = controlParams;

            % Validate controlParams and instantiate the strategy
            if isstruct(controlParams)
                if exist(strategyClass, 'class') == 8 % Check if class exists
                    obj.controlStrategy = feval(strategyClass); % Instantiate object dynamically
                else
                    error('ControllerNode:InvalidStrategy', 'Control strategy "%s" class does not exist.', strategyClass);
                end
            else
                error('ControllerNode:MissingStrategy', 'controlParams must contain a valid strategy field.');
            end
        end
        
        function init(obj)
            % init Initializes the TrueTime kernel and resets controller states.
            
            obj.delayedControlSignals = zeros(obj.ncsPlant.delaySteps, 1);
            obj.controlSignalHistory = [];
            obj.sendTimeHistory = [];
            obj.liftedStateHistory = [];

            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create a sporadic controller task activated by incoming network messages
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);
        end
        
        function [executionTime, obj] = evaluate(obj, seg)
            % evaluate Executes the control logic when a network message arrives.
            
            receivedMsg = ttGetMsg(); % Retrieve incoming network message
            currentTime = ttCurrentTime();

            % Construct lifted states
            liftedState = [receivedMsg.data(:); obj.delayedControlSignals];
            obj.liftedStateHistory = [obj.liftedStateHistory; liftedState'];

            %------- Execute selected control strategy dynamically --------
            controlSignal = obj.controlStrategy.execute(receivedMsg, obj.controlParams, obj.ncsPlant);
            %--------------------------------------------------------------

            % update
            obj.controlSignalHistory = [obj.controlSignalHistory; controlSignal];
            obj.sendTimeHistory = [obj.sendTimeHistory; currentTime];
            obj.delayedControlSignals = [controlSignal; obj.delayedControlSignals(1:end-1)];

            % Transmit results to the next node
            sentMsg = NetworkMsg(receivedMsg.samplingTS, currentTime, controlSignal, receivedMsg.seqNr);
            ttSendMsg(obj.nextnode, sentMsg, 80);
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);

        end

        function generateTaskName(obj, nodeNr)
            % setTaskName Sets the task name for the controller node.
            obj.taskName = ['controllerTaskNode', num2str(nodeNr)];
        end
    end
end
