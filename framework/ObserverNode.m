classdef ObserverNode < NetworkNode & handle
    % ObserverNode: Implements an observer node for estimating states in an NCS.
    % 
    % See also: NetworkNode
    
    properties
        taskName char % TrueTime task name
        ncsPlant NcsPlant % Networked control system plant
        estimatesHistory double % Observer state history


        %------------ goes to strategy
        Ad double % Discrete-time system matrix
        Bd double % Discrete-time input matrix
        Cd double % Output matrix
        Dd double % Direct feedthrough matrix
        flagLost uint32 % Flag indicating consecutive packet loss
        ykHist double % Measured output history
        ekYHist double % Observation error history
        %-------------
    end
    
    methods
        function obj = ObserverNode(nextNode, nodeNr, ncsPlant)
            % Constructor for ObserverNode
            
            obj@NetworkNode(ncsPlant.stateSize, 0, nextNode, nodeNr);
            obj.generateTaskName(nodeNr);
            
            obj.ncsPlant = ncsPlant;

            %------------ goes to strategy
            obj.Ad = ncsPlant.discreteSystem.A; 
            obj.Bd = ncsPlant.discreteSystem.B; 
            obj.Cd = ncsPlant.discreteSystem.C; 
            obj.Dd = ncsPlant.discreteSystem.D; 
        end
        
        function init(obj)
            % Initializes the observer node
            
            obj.estimatesHistory = zeros(obj.ncsPlant.stateSize, 1); % Initial state estimate
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);

            %------------ goes to strategy
            obj.ykHist = [];
            obj.ekYHist = [];
            obj.flagLost = 0;
        end


        
        function [executionTime, obj] = evaluate(obj, segment)
            % TrueTime task function for observer
            
            receivedMsg = ttGetMsg();

            %------- Execute selected observer strategy dynamically
            %-------- ! implement
            % predictedEstimates = obj.observerStrategy.execute(receivedMsg, obj.observerParams, obj.ncsPlant);
            %--------------------------------------------------------------
            
            
            

            %--------strategy---------------------------------
            % l0 = [0.661; 9.51];     % -> observerParams
            % l1 = [0.176; 2.56];     % -> observerParams
            % l2 = [0.117; 1.51];     % -> observerParams
            % l3 = [0.0925; 0.939];   % -> observerParams
            % 
            % observerGains = {l0, l1, l2, l3}; % -> observerParams
            % 
            % yk = obj.Cd * receivedMsg.data(1:size(obj.Cd, 2));
            % uk = receivedMsg.data(size(obj.Cd, 2) + 1);
            % estimates = obj.estHist(:, end); % Last observer state
            % 
            % observerGains = obj.computeObserverGain();
            % 
            % if ~isnan(yk)
            %     obj.flagLost = 0;
            %     predictedEstimates = obj.Ad * estimates + obj.Bd * uk + observerGains{obj.flagLost + 1} * (yk - obj.Cd * estimates);
            %     obj.ekYHist = [obj.ekYHist, yk - obj.Cd * estimates ];
            % else
            %     if receivedMsg.seqNr~= 1
            %         obj.flagLost = obj.flagLost + 1;
            %         predictedEstimates = obj.Ad * estimates + obj.Bd * uk + observerGains{obj.flagLost + 1} * obj.ekYHist(end);
            %     end
            %     obj.ekYHist = [obj.ekYHist, obj.ekYHist(end)];
            % end
            % 
            % obj.estHist = [obj.estHist, predictedEstimates];
            
           %-----------------------------------------------

            sentMsg = receivedMsg;
            % sentMsg.data(1:obj.ncsPlant.n) = xk1Obsv; % Send xk+1
            % sentMsg.data(end) = NaN;
            % sentMsg = NetworkMsg(receivedMsg.samplingTS, currentTime, controlSignal, receivedMsg.seqNr);
            
            predictedEstimates = [receivedMsg.seqNr+1; receivedMsg.seqNr+2]; % CHECK
            sentMsg.data = predictedEstimates;
            
            ttSendMsg(obj.nextnode, sentMsg, 80); % Send message (80 bits) to next node
            executionTime = -1;
            ttAnalogOutVec(1:numel(sentMsg.data),sentMsg.data);
        end

        function generateTaskName(obj, nodeNumber)
            % setTaskName Sets the task name for the controller node.
            obj.taskName = ['ObserverTaskNode', num2str(nodeNumber)];
        end
    end
end
