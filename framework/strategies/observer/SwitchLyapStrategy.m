classdef SwitchLyapStrategy < IObserverStrategy

    properties
        Ad double % Discrete-time system matrix
        Bd double % Discrete-time input matrix
        Cd double % Output matrix
        Dd double % Direct feedthrough matrix
        flagLost uint32 % Flag indicating consecutive packet loss
        ykHist double % Measured output history
        ekYHist double % Observation error histor
    end

    methods
        function obj = SwitchLyapStrategy(ncsPlant)
            % Constructor for SwitchLyapStrategy

            obj.Ad = ncsPlant.discreteSystem.A; 
            obj.Bd = ncsPlant.discreteSystem.B; 
            obj.Cd = ncsPlant.discreteSystem.C; 
            obj.Dd = ncsPlant.discreteSystem.D; 
            obj.ykHist = [];
            obj.ekYHist = [];
            obj.flagLost = 0;
        end

        function [predictedEstimates,obj] = execute(obj, receivedMsg, observerParams, ncsPlant, ~)

            % sentMsg.data(1:obj.ncsPlant.n) = xk1Obsv; % Send xk+1
            % sentMsg.data(end) = NaN;
            % sentMsg = NetworkMsg(receivedMsg.samplingTS, currentTime, controlSignal, receivedMsg.seqNr);

            % l0 = [0.661; 9.51];     % -> observerParams
            % l1 = [0.176; 2.56];     % -> observerParams
            % l2 = [0.117; 1.51];     % -> observerParams
            % l3 = [0.0925; 0.939];   % -> observerParams
            
            % observerGains = {l0, l1, l2, l3}; % -> observerParams
            
            % yk = obj.Cd * receivedMsg.data(1:size(obj.Cd, 2));
            % uk = receivedMsg.data(size(obj.Cd, 2) + 1);
            % estimates = obj.estHist(:, end); % Last observer state
            
            % observerGains = obj.computeObserverGain();
            
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
            
            % obj.estHist = [obj.estHist, predictedEstimates];

            predictedEstimates = [receivedMsg.seqNr+1; receivedMsg.seqNr+2]; % CHECK
        end
    end
end