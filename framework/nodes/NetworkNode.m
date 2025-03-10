classdef  NetworkNode < handle
    % NetworkNode Abstract class for configuring TrueTime kernel blocks.
    %
    % This class serves as a base for all networked nodes in a TrueTime simulation.
    % It provides fundamental properties for message handling and ensures that 
    % derived classes implement initialization functions for the TrueTime kernel.
    %
    % Properties:
    %   - nOut (double) : Number of output elements from this node.
    %   - nIn (double) : Number of input elements expected by this node.
    %   - nextNode (double) : Node number(s) that should receive messages from this node.
    %   - nodeNr (double) : Unique identifier for this node in the network.
    %
    % Constants:
    %   - taskWrapperName (string) : Name of the function called when executing tasks.
    %   - initFunctionWrapper (string) : Name of the initialization function wrapper.
    %
    % Methods:
    %   - NetworkNode(nOut, nIn, nextNode, nodeNr) : Constructor that initializes a network node.
    %   - init() : Abstract method that must be implemented by subclasses to initialize TrueTime kernel.
    %
    % See also: TrueTime, SensorNode, ControllerNode, ObserverNode

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
            % This constructor sets up fundamental network parameters such as input/output sizes
            % and connections to other nodes.
            %
            % Inputs:
            %   - nOut (double) : Number of output elements.
            %   - nIn (double) : Number of input elements.
            %   - nextNode (double or vector) : Node number(s) that should receive messages from this node.
            %   - nodeNr (double) : Unique number assigned to this node.
            
            obj.nOut = nOut;
            obj.nIn = nIn;
            obj.nextNode = nextNode;
            obj.nodeNr = nodeNr;          
        end
    end
end
