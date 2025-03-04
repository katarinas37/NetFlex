classdef NcsPlant <handle
    %NCSPROBLEM Specification of the networked control systems properties.
    %
    %obj = NcsProblem(sys, delay_steps, Td, pert_limits, Name, Value)
    %   sys:          Continuous state space model of the plant
    %   delay_steps:  Number of delay steps for each input channel if the networked control system is spatially 
    %                 distributed, or one single number of delay steps for centralized implementation
    %   Td:           Sampling time
    % Optional name/value pairs:
    %   'u_sat_limits': Saturation limits of the control signal (default: [-inf inf; ...])
    %
    %See also: ss
    
    properties (Access = private)
        n % System order
        m % Input size
        Td % Sampling time
        deltaBar % Number of delays for each input channel
        sys_lifted % Lifted model with controller input
        sys_d % discrete time model (without delay)
        u_sat_limits
        sys %Continuous state space model of the plant
    end
    
    methods
        function obj = NcsPlant(sys, deltaBar, Td, varargin)
            % obj = NcsProblem(sys, delay_steps, Td, pert_limits)
            % sys:          Continuous state space model of the plant
            % delay_steps:  Number of delay steps for each channel if spatially distributed or one single for centralized implementation
            % Td:           Sampling time
            
            p = inputParser;
            p.addRequired('sys', @(x) isa(x,'ss'));
            p.addRequired('deltaBar', @(x) validateattributes(x,{'double'}, {'integer', 'positive', 'finite', 'real'}));
            p.addRequired('Td',@(x) validateattributes(x,{'double'},{'positive', 'finite', 'real', 'scalar'}));
            p.addParameter('u_sat_limits', nan, @(x) validateattributes(x,{'double'},{'real'}));
            p.parse(sys, deltaBar, Td, varargin{:});
            obj.sys = p.Results.sys;

            if ~isa(obj.sys, 'ss')
            error('sys must be a state-space object.');
            end
            
            sys_d = c2d(obj.sys,Td);
            obj.n = size(obj.sys.a,1);
            obj.m = size(obj.sys.b,2);
            obj.Td = p.Results.Td;
            
            u_sat_limits = p.Results.u_sat_limits;
            
            if(isnan(u_sat_limits))
                u_sat_limits = inf*repmat([-1 1],obj.m,1);
            end
            
            if(size(u_sat_limits,1) ~= obj.m)
                error('Please provide a saturation limit for each input channel')
            end
            if(size(u_sat_limits,2) > 2)
                error('Please provide just upper and lower bound of the input saturation for each input channel')
            end
            if(size(u_sat_limits,2) == 1)
                u_sat_limits = abs(u_sat_limits).*repmat([-1 1],obj.m,1);
            end
            obj.u_sat_limits = u_sat_limits;
            if(numel(deltaBar)~=1 && numel(deltaBar) ~= obj.m)
                error('Please specify the number of delay steps for each input or one single number of delay steps for centralized control scheme')
            end
            obj.deltaBar = p.Results.deltaBar;

            obj.sys_d = sys_d;

            obj.getLiftedModel(obj.deltaBar);
        end
        
        function getLiftedModel(obj,deltaBar)

            deltaBar_each_channel = repmat(deltaBar,1,obj.m);
            %getLiftedModel derive the lifted NCS model
            cumdel = [0; cumsum(deltaBar_each_channel)];
            theta = cumdel(end);
            Ad = obj.sys_d.a;
            Bd = obj.sys_d.b;
            Ahat = [Ad;zeros(theta,obj.n)];
            Bhat = [];
            Bfhat = [];
            for i = 1:obj.m
                currdel = deltaBar_each_channel(i);
                state_line = [zeros(obj.n,currdel-1) Bd(:,i)];
                toadd = [state_line; zeros(cumdel(i)+1,currdel); [eye(currdel-1) zeros(currdel-1,1)]; zeros(theta-cumdel(i+1),currdel)];
                Ahat = [Ahat toadd];
                Bhat = [Bhat [zeros(obj.n+cumdel(i),1); 1; zeros(theta-cumdel(i)-1,1)]];
                Bfhat = [Bfhat [Bd(:,i); zeros(theta,1)]];
            end
            
            obj.sys_lifted = ss(Ahat,Bhat,eye(obj.n+theta), zeros(obj.n+theta,obj.m),obj.Td);
        end
    end
end

