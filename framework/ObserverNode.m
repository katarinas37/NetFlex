classdef ObserverNode < NetworkNode & handle
    % ObserverNode: Implements an observer node for estimating states in an NCS.
    % 
    % See also: NetworkNode
    
    properties
        taskName char % TrueTime task name
        ncsPlant NcsPlant % Networked control system plant
        Ad double % Discrete-time system matrix
        Bd double % Discrete-time input matrix
        Cd double % Output matrix
        Dd double % Direct feedthrough matrix
        xkObsvHist double % Observer state history
        ykHist double % Measured output history
        ekYHist double % Observation error history
        ekYNodropoutHist double % Observation error history without dropouts
        dropoutCount uint32 % Number of packet dropouts
        flagLost uint32 % Flag indicating consecutive packet loss
    end
    
    methods
        function obj = ObserverNode(outputCount, nextNode, nodeNr, ncsPlant)
            % Constructor for ObserverNode
            
            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);
            obj.taskName = ['observerTaskNode', num2str(nodeNr)];
            obj.ncsPlant = ncsPlant;
            obj.Ad = ncsPlant.sys_d.A;
            obj.Bd = ncsPlant.sys_d.B;
            obj.Cd = [1, 0];
            obj.Dd = 0;
        end
        
        function init(obj)
            % Initializes the observer node
            
            obj.xkObsvHist = zeros(obj.ncsPlant.n, 1); % Initial state estimate
            obj.ykHist = [];
            obj.ekYHist = [];
            obj.ekYNodropoutHist = [];
            obj.dropoutCount = zeros(2, 1);
            obj.flagLost = 0;
            
            % Initialize TrueTime kernel
            ttInitKernel('prioDM'); % Deadline-monotonic scheduling
            
            % Create TrueTime task
            deadline = 0.1; % Maximum execution time
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.observerTask);
            ttAttachNetworkHandler(obj.taskName);
        end
        
        function [executionTime, obj] = observerTask(obj, segment)
            % TrueTime task function for observer
            
            receivedMsg = ttGetMsg();
            [xk1Obsv, yk] = obj.updateObserver(receivedMsg);
            obj.sendUpdatedState(receivedMsg, xk1Obsv);
            
            executionTime = -1;
        end
        
        function [xk1Obsv, yk] = updateObserver(obj, receivedMsg)
            % Updates the observer state based on received msg
            
            yk = obj.Cd * receivedMsg.data(1:size(obj.Cd, 2));
            uk = receivedMsg.data(size(obj.Cd, 2) + 1);
            xkObsv = obj.xkObsvHist(:, end); % Last observer state
            
            observerGains = obj.computeObserverGain();
            
            if ~isnan(yk)
                obj.flagLost = 0;
                xk1Obsv = obj.Ad * xkObsv + obj.Bd * uk + observerGains{obj.flagLost + 1} * (yk - obj.Cd * xkObsv);
                obj.ekYHist = [obj.ekYHist, yk - obj.Cd * xkObsv];
            else
                if receivedMsg.seq ~= 1
                    obj.flagLost = obj.flagLost + 1;
                    xk1Obsv = obj.Ad * xkObsv + obj.Bd * uk + observerGains{obj.flagLost + 1} * obj.ekYHist(end);
                end
                obj.ekYHist = [obj.ekYHist, obj.ekYHist(end)];
            end
            
            obj.ekYNodropoutHist = [obj.ekYNodropoutHist, yk - obj.Cd * xkObsv];
            obj.xkObsvHist = [obj.xkObsvHist, xk1Obsv];
        end
        
        function observerGains = computeObserverGain(obj)
            % Computes observer gain for different dropout scenarios
            
            l0 = [0.661; 9.51];
            l1 = [0.176; 2.56];
            l2 = [0.117; 1.51];
            l3 = [0.0925; 0.939];
            
            observerGains = {l0, l1, l2, l3};
        end
        
        function sendUpdatedState(obj, receivedMsg, xk1Obsv)
            % Sends the updated state to the next node
            
            updatedMsg = receivedMsg;
            updatedMsg.data(1:obj.ncsPlant.n) = xk1Obsv; % Send xk+1
            updatedMsg.data(end) = NaN;
            
            ttSendMsg(obj.nextnode, updatedMsg, 80); % Send message (80 bits) to next node
        end
    end
end
