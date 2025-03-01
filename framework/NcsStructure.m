classdef NcsStructure < handle
    % NCS_ISMC: Builder class for spatially distributed networked control systems. It designs all necessary
    % components for a spatially distribued networked control system.
    %
    % obj = NCS_ISMC(ncsProblem_obj, smc_controller_classname, Name, Value)
    % ncsProblem_obj:           NcsProblem object
    %
    % Optional name/value pairs:
    % 'tsim':  Specify the largest simulation time (default: 5000*Td)
    %
    %See also: NetworkDelay, NetworkOrderer, ISM_ControllerNode, SensorNode, NetworkBuffer, NcsProblem

    properties
        ncsPlant NcsPlant %Object which specifies the control loop (plant, delays, ...)
        sensor_node SensorNode %Sensor Node Object
        simtime %Largest simulation time
        tau_ca_node %Cell array of variable delay objects from controller to actuator
        controller_node % Cell array of integral sliding mode controller node objects
    end
    
    properties (Dependent)
        allnodes %Cell array of all nodes
        Results
    end
    
    properties (Constant)
        sensor_nodenumber=1 %Nodenumber of sensor and also lowest nodenumber
    end
    
    methods
        function obj = NcsStructure(ncsPlant_obj, varargin)
            
            p = inputParser;
            addRequired(p,'ncsPlant_obj',@(x) isa(x,'NcsPlant'));
            addParameter(p,'tsim', 5000*ncsPlant_obj.Td , @(x) validateattributes(x,{'numeric'}, {'scalar'}));

            parse(p,ncsPlant_obj, varargin{:});
            obj.ncsPlant = p.Results.ncsPlant_obj;
            obj.simtime = p.Results.tsim;
            
            % Generate nodes - depends on the structure
            act_nodenumber = obj.sensor_nodenumber+1;
            controller_nodenumber = act_nodenumber;
            delay_ca_nodenumber = act_nodenumber + 1;


            tau_ca = obj.generateDelays();

            obj.controller_node = ControllerNode(delay_ca_nodenumber, controller_nodenumber, obj.ncsPlant);
            obj.tau_ca_node =  NetworkDelay(1, 0, delay_ca_nodenumber, tau_ca);
            obj.sensor_node = SensorNode(ncsPlant_obj.n,controller_nodenumber,obj.sensor_nodenumber,ncsPlant_obj.Td,obj.simtime);
        end

        function [tau_ca] = generateDelays(obj)
            %Generate random delays
            Td = obj.ncsPlant.Td;

            load networkeffects.mat
            tau_ca = ceil(tau_ca/1e-4)*1e-4;
        end

        function out = get.allnodes(obj)
            %returns a cell array of all nodes
           out = [{obj.sensor_node}; {obj.tau_ca_node}; {obj.controller_node}];
        end
        function nr = getMaxNodeNumber(obj)
            %returns the maximum node number
            all_nodenumbers = cellfun(@(x) x.nodenumber,obj.allnodes);
            nr = max(all_nodenumbers);
        end
        
        function results = get.Results(obj)
            
            numsamples = length(obj.controller_node.uk_hist);
            timevector = (0:(numsamples-1))*obj.ncsPlant.Td;
                
            results.uk = timeseries(obj.controller_node.uk_hist, timevector);
            results.uk.DataInfo.Interpolation = 'zoh';


            numsamples = length(obj.controller_node.uk_hist);
            timevector = (0:(numsamples-1))*obj.ncsPlant.Td;

            results.tau_ca = timeseries(cell2mat(cellfun(@(x) x.tau,obj.tau_ca_node,'uni',false)'),timevector);
            results.tau_ca.DataInfo.Interpolation = 'zoh';

        end
    end
end

