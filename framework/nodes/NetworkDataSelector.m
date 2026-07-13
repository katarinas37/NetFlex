classdef NetworkDataSelector < NetworkNode
    % NetworkDataSelector sets up a selector node in the TrueTime framework.
    %
    % This node receives a message containing multiple candidate data signals
    % and selects one of them according to a predefined selection policy.
    %
    % Currently supported policies:
    %   - 'delayDependent' : Selects the signal based on the realized delay.
    %
    % Properties:
    %   - taskName (string)         : Name of the TrueTime task.
    %   - selectionPolicy (string)  : Selection policy used in the node.
    %   - sampleTime (double)       : Sample time of the system.
    %   - firstMode (integer)       : Logical mode corresponding to the first
    %                                 transmitted candidate signal.
    %
    %   - rcvHistoryTime            : Time instants of received messages.
    %   - rcvHistory                : Received messages.
    %   - rcvHistoryData            : Received message data.
    %   - sendHistoryTime           : Time instants of sent messages.
    %   - sendHistory               : Sent messages.
    %   - sendHistoryData           : Sent message data.
    %
    % Methods:
    %   - NetworkDataSelector(outputCount, nextNode, nodeNr, sampleTime, ...
    %                         selectionPolicy, firstMode)
    %   - init() : Initializes the TrueTime kernel and selector task.
    %   - evaluate(segment) : Executes the selection logic.
    %   - generateTaskName(nodeNr) : Generates a unique task name.
    %
    % See also: NetworkNode

    properties
        taskName char
        selectionPolicy
        sampleTime
        firstMode

        rcvHistoryTime
        rcvHistory
        rcvHistoryData
        sendHistoryTime
        sendHistory
        sendHistoryData
    end

    methods
        function obj = NetworkDataSelector(outputCount, nextNode, nodeNr, ...
                sampleTime, selectionPolicy, firstMode)
            % NetworkDataSelector Constructor
            %
            % Inputs:
            %   - outputCount (integer)     : Number of outputs from this node
            %   - nextNode (integer/vector) : Identifier(s) of the next node(s)
            %   - nodeNr (integer)          : Unique identifier for this node
            %   - sampleTime (double)       : Sampling time of the system
            %   - selectionPolicy (string)  : Selection policy
            %   - firstMode (integer)       : First logical mode in transmitted data

            obj@NetworkNode(outputCount, 0, nextNode, nodeNr);

            obj.generateTaskName(nodeNr);

            obj.sampleTime = sampleTime;
            obj.selectionPolicy = selectionPolicy;

            if nargin < 6 || isempty(firstMode)
                firstMode = 0;
            end
            obj.firstMode = firstMode;

            obj.rcvHistoryTime = [];
            obj.rcvHistory = [];
            obj.rcvHistoryData = [];
            obj.sendHistoryTime = [];
            obj.sendHistory = [];
            obj.sendHistoryData = [];
        end

        function [executionTime, obj] = evaluate(obj, ~)
            % evaluate Executes the selection logic when a message arrives.
            %
            % This method is triggered when a message arrives at the selector
            % node. It retrieves the message, applies the selection policy,
            % and transmits the selected signal to the next node.
            %
            % Outputs:
            %   - executionTime (double) : Execution time for the selector task

            rcvMsg = ttGetMsg();
            currentTime = ttCurrentTime();

            obj.rcvHistoryTime = [obj.rcvHistoryTime, currentTime];
            obj.rcvHistory = [obj.rcvHistory, rcvMsg];
            obj.rcvHistoryData = [obj.rcvHistoryData, rcvMsg.data];

            sentMsg = rcvMsg;



            switch obj.selectionPolicy
                case 'delayDependent'
                    % Realized delay based on last transmit time and sampling time
                    totalDelay = rcvMsg.lastTransmitTS(end) - rcvMsg.samplingTS;

                    % Logical mode corresponding to realized delay
                    mode = round(totalDelay / obj.sampleTime);

                    % Map logical mode to MATLAB column index
                    idx = mode - obj.firstMode + 1;
                    
                    % Sanity check
                    if isnan(idx) % package generated in the buffer with value 0
                        idx = 1; 
                    elseif idx < 1 || idx > size(rcvMsg.data, 1)
                        
                        error(['NetworkDataSelector: selected mode %d is not available ', ...
                               'in transmitted data. firstMode = %d, available modes = %d to %d.'], ...
                               mode, obj.firstMode, obj.firstMode, ...
                               obj.firstMode + size(rcvMsg.data, 2) - 1);
                    end

                    % Select corresponding data row
                    sentMsg.data = rcvMsg.data(idx,:);
                otherwise
                    error('NetworkDataSelector:InvalidPolicy', ...
                        'Selection policy "%s" is not supported.', obj.selectionPolicy);
            end


            sentMsg.nodeId = obj.nodeNr;

            for nextNode = obj.nextNode(:)'
                if nextNode
                    ttSendMsg(nextNode, sentMsg, 80);
                end
            end

            executionTime = -1;

            transmitTime = currentTime;
            obj.sendHistoryTime = [obj.sendHistoryTime, transmitTime];
            obj.sendHistory = [obj.sendHistory, sentMsg];
            obj.sendHistoryData = [obj.sendHistoryData, sentMsg.data];

            ttAnalogOutVec(1:numel(sentMsg.data), sentMsg.data');
        end

        function init(obj)
            % init Initializes the TrueTime kernel and selector task.
            %
            % This method sets up the TrueTime kernel and attaches the network
            % message handler to respond to incoming messages.

            ttInitKernel('prioDM');

            deadline = 0.1;
            ttCreateTask(obj.taskName, deadline, obj.taskWrapperName, @obj.evaluate);
            ttAttachNetworkHandler(obj.taskName);
        end

        function generateTaskName(obj, nodeNr)
            % generateTaskName Sets the task name for the selector node.
            %
            % Inputs:
            %   - nodeNr (integer) : Unique node identifier

            obj.taskName = ['SelectorTaskNode', num2str(nodeNr)];
        end
    end
end