classdef NetworkNode < handle
    % NetworkNode Abstract class for configuring TrueTime kernel blocks.
    %
    % Properties:
    %   - Nout (double) : Number of output elements.
    %   - Nin (double) : Number of input elements.
    %   - nextnode (double) : Node numbers that should receive messages from this node.
    %   - nodenumber (double) : Unique number of this node in the network.
    %
    % Constants:
    %   - TASK_WRAPPER_NAME (string) : Name of the function called for tasks.
    %   - INIT_FUNCTION_WRAPPER (string) : Name of the initialization function wrapper.
    %
    % Methods:
    %   - NetworkNode(Nout, Nin, nextnode, nodenumber) : Constructor.
    %   - init() : Abstract method to initialize the TrueTime kernel.

    properties
        Nout double % Number of output elements
        Nin double % Number of input elements
        nextnode double % Node numbers that should receive messages from this node
        nodenumber double % Unique number of this node in the network
    end
    
    properties (Constant)
        taskWrapperName = 'taskWrapper' % Name of the function called for tasks
        initFunctionWrapper = 'initFctWrapper' % Name of the initialization function wrapper
    end
    
    methods (Abstract)
       init(obj) % Abstract function to initialize the TrueTime kernel and create tasks
    end
    
    methods
        function obj = NetworkNode(Nout, Nin, nextnode, nodenumber)
            % NetworkNode Constructor for a network node in the TrueTime simulation.
            %
            % Example:
            %   node = NetworkNode(1, 1, 2, 3);
            
            obj.Nout = Nout;
            obj.Nin = Nin;
            obj.nextnode = nextnode;
            obj.nodenumber = nodenumber;          
        end

        % The following functions are required by TrueTime and serve as getters for various properties.

        % taskWrapperName: Getter for the task wrapper name.
        % initFunctionWrapper: Getter for the initialization function wrapper.
        % Nout: Getter for the output count.
        % Nin: Getter for the input count.
        % nodenumber: Getter for the node number.
        % function name = taskWrapperName(obj)
        %     % getTaskWrapperName Getter for the task wrapper name.
        %     name = obj.TASK_WRAPPER_NAME;
        % end

        % function name = initFunctionWrapper(obj)
        %     % getInitFunctionWrapper Getter for the initialization function wrapper.
        %     name = obj.INIT_FUNCTION_WRAPPER;
        % end

        % function count = Nout(obj)
        %     % Nout Getter for the output count.
        %     count = obj.Nout;
        % end

        % function count = Nin(obj)
        %     % Nin Getter for the input count.
        %     count = obj.Nin;
        % end

        % function number = nodenumber(obj)
        %     % nodenumber Getter for the node number.
        %     number = obj.nodenumber;
        % end

        % function node = nextnode(obj)
        %     % nextnode Getter for the next node.
        %     node = obj.nextnode;
        % end
    end
end
