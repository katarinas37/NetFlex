classdef SwitchedLyapStrategy < IObserverStrategy
    % SwitchedLyapStrategy
    % This class implements a switched Lyapunov-based observer strategy for 
    % state estimation in a networked control system (NCS). The observer 
    % handles packet loss by switching between different observer gains.
    % 
    % Properties:
    %   - Ad: Discrete-time system matrix
    %   - Bd: Discrete-time input matrix
    %   - Cd: Output matrix
    %   - Dd: Direct feedthrough matrix
    %   - flagLost: Tracks consecutive packet losses
    %   - ekYHist: Stores observation error history
    %   - estimatesHistory: Keeps state estimates history
    %
    % Methods:
    %   - SwitchedLyapStrategy: Constructor to initialize observer parameters
    %   - execute: Executes the observer update based on received messages

    properties
        Ad double % Discrete-time system matrix
        Bd double % Discrete-time input matrix
        Cd double % Output matrix
        Dd double % Direct feedthrough matrix
        flagLost uint32 % Flag indicating consecutive packet loss
        ekYHist double % Observation error histor
        estimatesHistory double % State estimates history
    end

    methods
        function obj = SwitchedLyapStrategy(ncsPlant)
            % Constructor for SwitchLyapStrategy

            obj.Ad = ncsPlant.discreteSystem.A; 
            obj.Bd = ncsPlant.discreteSystem.B; 
            obj.Cd = ncsPlant.discreteSystem.C; 
            obj.Dd = ncsPlant.discreteSystem.D; 
            obj.ekYHist = 0;
            obj.flagLost = 0;
            obj.estimatesHistory = zeros(ncsPlant.stateSize,1); % estX0 = 0;
        end

        function [predictedEstimates,obj] = execute(obj, rcvMsg, observerParams, ncsPlant, ~)
            % Executes the observer update based on received messages.
            % 
            % Inputs:
            %   - rcvMsg: Received message containing output and input data
            %   - observerParams: Struct containing observer gains
            %   - ncsPlant: The networked control system plant
            %
            % Output:
            %   - predictedEstimates: Updated state estimate
            observerGains = observerParams.l;
            % Extract measured output and applied input from received message
            outputKstep = rcvMsg.data(1:ncsPlant.outputSize);     % yk: output signal measured at t = k*sampleTime
            inputKstep = rcvMsg.data(ncsPlant.outputSize+1:end);  % uk*: input signal applied at t = k*sampleTime
            % Get latest state estimate
            estimatesKstep = obj.estimatesHistory(:,end);
            
            % If the output is received correctly
            if ~isnan(outputKstep)
                obj.flagLost = 0;
                estimatesK1step = obj.Ad*estimatesKstep + obj.Bd*inputKstep + observerGains{obj.flagLost+1} * (outputKstep-obj.Cd*estimatesKstep);
                obj.ekYHist = [obj.ekYHist, outputKstep -  obj.Cd * estimatesKstep ];
            else % output was lost
                obj.flagLost = obj.flagLost + 1;
                estimatesK1step = obj.Ad*estimatesKstep + obj.Bd*inputKstep  + observerGains{obj.flagLost+1} * obj.ekYHist(end);
                obj.ekYHist = [obj.ekYHist, obj.ekYHist(end)];
            end
            % Store the updated estimate
            obj.estimatesHistory = [obj.estimatesHistory, estimatesK1step];
            % Output the predicted estimates
            predictedEstimates = estimatesK1step; % !strategy! -> send predicted estimates
        end
    end
end