classdef NcsPlant < handle
    % NcsPlant Specification of the networked control system properties.
    % Stores the plant model and its discretized version, handling delays.
    %
    % Properties:
    %   - system (ss) : Continuous-time state-space model of the plant.
    %   - stateSize (double) : System order.
    %   - inputSize (double) : Number of control inputs.
    %   - outputSize (double) : Number of measurable outputs.
    %   - sampleTime (double) : Sample time.
    %   - delaySteps (double) : Delay steps for each input channel.
    %   - controlSaturationLimits (double) : Input saturation limits.
    %   - discreteSystem (ss, Dependent) : Discretized system.
    %   - liftedSystem (ss, Dependent) : Lifted model with controller input.
    %
    % Methods:
    %   - NcsPlant(system, delaySteps, sampleTime, 'controlSaturationLimits', [limits])
    %   - computeLiftedModel() : Computes the lifted model.

    properties (SetAccess = private)
        stateSize double % System order
        inputSize double % Input size
        outputSize double % Output size
        sampleTime double % Sampling time
        delaySteps double % Number of delay steps per input channel
        controlSaturationLimits double % Input saturation limits
        system % Continuous-time state-space model
    end
    
    properties (Dependent)
        discreteSystem % Discrete-time model
        liftedSystem % Lifted model including delays
    end
    
    methods
        function obj = NcsPlant(system, delaySteps, sampleTime, varargin)
            % NcsPlant Constructor for a networked control system plant.
            %
            % Example:
            %   system = ss(A, B, C, D);
            %   plant = NcsPlant(system, 3, 0.1, 'controlSaturationLimits', [-10 10]);
            
            % Input parsing and validation
            p = inputParser;
            p.addRequired('system', @(x) isa(x, 'ss')); % Ensure 'system' is a state-space object
            p.addRequired('delaySteps', @(x) validateattributes(x, {'double'}, {'integer', 'positive', 'finite', 'real'}));
            p.addRequired('sampleTime', @(x) validateattributes(x, {'double'}, {'positive', 'finite', 'real', 'scalar'}));
            p.addParameter('controlSaturationLimits', nan, @(x) validateattributes(x, {'double'}, {'real'}));
            p.parse(system, delaySteps, sampleTime, varargin{:});
            
            % Assign properties
            obj.system = p.Results.system;
            obj.stateSize = size(obj.system.A, 1);
            obj.inputSize = size(obj.system.B, 2);
            obj.sampleTime = p.Results.sampleTime;
            obj.delaySteps = p.Results.delaySteps;

            % Validate delaySteps size
            if numel(delaySteps) ~= 1 && numel(delaySteps) ~= obj.inputSize
                error('NcsPlant:InvalidDelaySteps', ...
                      'Provide delay steps for each input (%d inputs) or a single value.', obj.inputSize);
            end

            % Handle control saturation limits
            obj.controlSaturationLimits = obj.processControlSaturationLimits(p.Results.controlSaturationLimits);
        end
        
        function discreteSystem = get.discreteSystem(obj)
            % Computes the discrete-time version of the plant
            discreteSystem = c2d(obj.system, obj.sampleTime);
        end

        function liftedSystem = get.liftedSystem(obj)
            % Computes and returns the lifted state-space model
            liftedSystem = obj.computeLiftedModel();
        end
        
        function controlSaturationLimits = processControlSaturationLimits(obj, controlSaturationLimits)
            % Processes and validates input saturation limits.
            if isnan(controlSaturationLimits)
                controlSaturationLimits = inf * repmat([-1 1], obj.inputSize, 1);
            elseif size(controlSaturationLimits, 1) ~= obj.inputSize
                error('NcsPlant:InvalidSaturationLimits', ...
                      'Provide saturation limits for each input channel (%d inputs).', obj.inputSize);
            elseif size(controlSaturationLimits, 2) > 2
                error('NcsPlant:InvalidSaturationLimits', ...
                      'Provide only upper and lower bounds for each input channel.');
            elseif size(controlSaturationLimits, 2) == 1
                controlSaturationLimits = abs(controlSaturationLimits) .* repmat([-1 1], obj.inputSize, 1);
            end
        end

        function liftedSystem = computeLiftedModel(obj)
            % Computes the lifted NCS model
            delayStepsEachChannel = repmat(obj.delaySteps, 1, obj.inputSize);
            cumulativeDelay = [0; cumsum(delayStepsEachChannel)];
            totalDelay = cumulativeDelay(end);
            
            Ad = obj.discreteSystem.A;
            Bd = obj.discreteSystem.B;
            Ahat = [Ad; zeros(totalDelay, obj.stateSize)];
            Bhat = [];
            Bfhat = [];
            
            for i = 1:obj.inputSize
                currentDelay = delayStepsEachChannel(i);
                stateLine = [zeros(obj.stateSize, currentDelay-1), Bd(:, i)];
                toAdd = [stateLine; zeros(cumulativeDelay(i)+1, currentDelay); [eye(currentDelay-1), zeros(currentDelay-1,1)]; zeros(totalDelay - cumulativeDelay(i+1), currentDelay)];
                Ahat = [Ahat, toAdd];
                Bhat = [Bhat, [zeros(obj.stateSize + cumulativeDelay(i), 1); 1; zeros(totalDelay - cumulativeDelay(i) - 1, 1)]];
                Bfhat = [Bfhat, [Bd(:, i); zeros(totalDelay, 1)]];
            end
            
            liftedSystem = ss(Ahat, Bhat, eye(obj.stateSize + totalDelay), zeros(obj.stateSize + totalDelay, obj.inputSize), obj.sampleTime);
        end

        function sampleTime = get.sampleTime(obj)
            % get.sampleTime Returns the sampling time of the plant.
            sampleTime = obj.sampleTime;
        end

        function stateSize = get.stateSize(obj)
            % get.stateSize Returns the state size of the plant.
            stateSize = obj.stateSize;
        end
    end
end
