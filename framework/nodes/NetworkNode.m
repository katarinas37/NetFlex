classdef NetworkNode < handle
    % NetworkNode Abstract class for configuring TrueTime kernel blocks.
    %
    % Properties:
    %   - nOut (double) : Number of output elements.
    %   - nIn (double) : Number of input elements.
    %   - nextNode (double) : Node numbers that should receive messages from this node.
    %   - nodeNr (double) : Unique number of this node in the network.
    %
    % Constants:
    %   - TASK_WRAPPER_NAME (string) : Name of the function called for tasks.
    %   - INIT_FUNCTION_WRAPPER (string) : Name of the initialization function wrapper.
    %
    % Methods:
    %   - NetworkNode(Nout, Nin, nextnode, nodenumber) : Constructor.
    %   - init() : Abstract method to initialize the TrueTime kernel.

    properties
        nOut double % Number of output elements
        nIn double % Number of input elements
        nextNode double % Node numbers that should receive messages from this node
        nodeNr double % Unique number of this node in the network
    end
    
    properties (Constant)
        taskWrapperName = 'taskWrapper' % Name of the function called for tasks
        initFunctionWrapper = 'initFctWrapper' % Name of the initialization function wrapper
    end
    
    methods (Abstract)
       init(obj) % Abstract function to initialize the TrueTime kernel and create tasks
    end
    
    methods
        function obj = NetworkNode(nOut, nIn, nextNode, nodeNr)
            % NetworkNode Constructor for a network node in the TrueTime simulation.
            %
            % Example:
            %   node = NetworkNode(1, 1, 2, 3);
            
            obj.nOut = nOut;
            obj.nIn = nIn;
            obj.nextNode = nextNode;
            obj.nodeNr = nodeNr;          
        end
    end
end
