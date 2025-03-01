classdef ControllerNode < NetworkNode
    %ISM_CONTROLLER Sets up the truetime kernel for a ISMC as in CDC2019
    %   See also NetworkNode, SmcControlLaw, ExplicitSTA, MatchingSTA, linearNominalController
    
    properties
        ncsProblem_obj NcsPlant
        taskname % name of the truetime task
        uk_d_vec % delayed control signals
        xik_hist % lifted states [xk; uk-1; uk-2; ... ; uk_deltabar]
        uk_hist          % control signals sent by the controller
        uk_SendTime_hist % time instants at wchich controller sends
    end
    
    methods
        function obj = ControllerNode(nextnode, nodenumber, ncsPlant_obj) %, miT, smc_controller, nominal_controller)
            % ISM_ControllerNode(nextnode, nodenumber, ncsProblem_obj, miT, smc_controller, nominal_controller)
            % nextnode...Nodes which should receive messages from this node
            % nodenumber...Unique number of this node in the network
            % ncsProblem_obj...Object specifying the networked control system
            m = 1;
            obj@NetworkNode(m,0,nextnode,nodenumber);
            obj.taskname = sprintf('controller_task_node%d',nodenumber);

            obj.ncsProblem_obj = ncsPlant_obj;
            obj.uk_d_vec = zeros(obj.ncsProblem_obj.deltaBar,1);
        end
        
        function init(obj)
            %init function which creates the evaluate task and resets the states
            obj.uk_d_vec = zeros(obj.ncsProblem_obj.deltaBar,1);
            obj.uk_hist = [];
            obj.uk_SendTime_hist = [];
            obj.xik_hist = [];

            % Initialize TrueTime kernel
            ttInitKernel('prioDM');   % deadline-monotonic scheduling
            
            % Sporadic controller task, activated by arriving network message
            deadline = 0.1;  % maximal time for calc
            ttCreateTask(obj.taskname, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskname)   
        end
        
        function [exectime, obj] = evaluate(obj,seg)
            %Evaluate the control laws
            
            rx_data = ttGetMsg() ;% get new message
            timestamp = ttCurrentTime;

            %create lifted states
            xik = [rx_data.data(:); obj.uk_d_vec];
            obj.xik_hist = [obj.xik_hist; xik'];

            % ------------ implement control methods ----------------------
            uk = rx_data.seq;
            % -------------------------------------------------------------

            obj.uk_hist = [obj.uk_hist; uk];
            obj.uk_SendTime_hist = [obj.uk_SendTime_hist; timestamp];

            % update delayes control signals for lifted states
            obj.uk_d_vec = [uk; obj.uk_d_vec(1:end-1)];


            %Transmit results to next nodes
            tx_msg = NetworkMsg(rx_data.sampling_timestamp,timestamp,uk, rx_data.seq);
            ttSendMsg(obj.nextnode, tx_msg, 80); 
            ttCurrentTime;
            exectime = -1;
        end
    end
end

