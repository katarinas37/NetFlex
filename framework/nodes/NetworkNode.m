classdef NetworkNode < handle
    %NETWORKNODE Abstract class for configuring the truetime kernel blocks
    
    properties
        Nout %number of output elements
        Nin %number of input elements
        nextnode %numbers of the nodes which should recieve messages of this node
        nodenumber %unique number of the node in the network
    end
    
    properties (Constant)
        taskWrapperName = 'taskWrapper' %Name of the function which is called for tasks
        initFunctionWrapper = 'initFctWrapper'; %Name of the init function wrapper
    end
    methods (Abstract)
       init(obj) %Abstract function which initializes the truetime kernel and creates the tasks
    end
    
    methods
        function obj = NetworkNode(Nout, Nin, nextnode, nodenumber)
            %Construct an instance of this class
            %NetworkNode(Nout, Nin, nextnode, nodenumber)
            %Nout...Number of output elements
            %Nin...Number of input elements
            %nextnode...Nodenumbers of the nodes, which should receive messages from this node
            %nodenumber...unique number of this node in the network
            
            obj.Nout = Nout;
            obj.nextnode = nextnode;
            obj.nodenumber = nodenumber;
            obj.Nin = Nin;            
        end
    end
end

