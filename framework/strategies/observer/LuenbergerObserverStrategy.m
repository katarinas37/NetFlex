classdef LuenbergerObserverStrategy < IObserverStrategy
    % LuenbergerObserverStrategy
    % This class implements a Luenberger observer strategy for 
    % state estimation in a networked control system (NCS). 
    % The observer corrects the state estimate using the measured 
    % system output and a predefined observer gain.
    % 
    % Properties:
    %   - Ad: Discrete-time system matrix
    %   - Bd: Discrete-time input matrix
    %   - Cd: Output matrix
    %   - Dd: Direct feedthrough matrix
    %   - estimatesHistory: Keeps state estimates history
    %
    % Methods:
    %   - LuenbergerObserverStrategy: Constructor to initialize observer parameters
    %   - execute: Performs the observer update using received measurements
    properties
        Ad double % Discrete-time system matrix
        Bd double % Discrete-time input matrix
        Cd double % Output matrix
        Dd double % Direct feedthrough matrix
        estimatesHistory double % State estimates history
    end

    methods
        function obj = LuenbergerObserverStrategy(ncsPlant)
            % Constructor for LuenbergerObserverStrategy

            obj.Ad = ncsPlant.discreteSystem.A; 
            obj.Bd = ncsPlant.discreteSystem.B; 
            obj.Cd = ncsPlant.discreteSystem.C; 
            obj.estimatesHistory = zeros(ncsPlant.stateSize,1); % estX0 = 0;
        end

        function [predictedEstimates,obj] = execute(obj, rcvMsg, observerParams, ncsPlant, ~)
            % Executes the observer update using received measurements.
            % 
            % Inputs:
            %   - rcvMsg: Received message containing output and input data
            %   - observerParams: Struct containing the observer gain
            %   - ncsPlant: The networked control system plant
            %
            % Output:
            %   - predictedEstimates: Updated state estimate

            % Ensure observerGain has the correct dimensions
            observerGain = observerParams.l;
             assert(isequal(size(observerGain), [ncsPlant.stateSize, ncsPlant.outputSize]), ...
                'Size of observerParams.l must be %d x %d', ncsPlant.stateSize, ncsPlant.outputSize);
            
             % Extract measured output and applied input from received message
            outputKstep = rcvMsg.data(1:ncsPlant.outputSize);     % yk: output signal measured at t = k*sampleTime
            inputKstep = rcvMsg.data(ncsPlant.outputSize+1:end);  % uk*: input signal applied at t = k*sampleTime
            % Retrieve the last state estimate
            estimatesKstep = obj.estimatesHistory(:,end);
            % Luenberger observer update equation     
            estimatesK1step = obj.Ad*estimatesKstep+obj.Bd*inputKstep + observerGain*(outputKstep-obj.Cd*estimatesKstep);
            % Store the updated estimate
            obj.estimatesHistory = [obj.estimatesHistory, estimatesK1step];
            % Output the predicted state estimate
            predictedEstimates = estimatesK1step; % !strategy! -> send predicted estimates
        end
    end
end