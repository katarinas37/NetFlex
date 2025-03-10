classdef MsgBuffer < handle
    % MsgBuffer Class for storing and managing network messages.
    % This class provides a message queue for handling network messages efficiently. 
    % Messages can be pushed to the front (highest priority) or back (FIFO), 
    % sorted based on transmission time, and retrieved in sequence.
    %
    % This class provides a message queue for handling network messages efficiently. 
    %
    % Properties:
    %   - elements (cell array) : Internal storage for buffer elements.
    %   - elementCount (integer, dependent) : Number of messages in the buffer.
    %   - transmitTimes (double array, dependent) : Array of transmission times.
    %
    % Methods:
    %   - MsgBuffer() : Constructor, initializes an empty buffer.
    %   - pushTop(element) : Adds an element to the top (highest priority).
    %   - pushBack(element) : Adds an element to the back (FIFO order).
    %   - popTop() : Removes the highest priority element.
    %   - getTop() : Returns the highest priority element without removing it.
    %   - clear() : Clears all elements from the buffer.
    %   - sortBuffer() : Sorts elements in ascending order of transmission time.
    %   - getElementCount() : Returns the number of elements in the buffer.
    %   - getTransmitTimes() : Returns an array of all transmit times.
    %
    % See also: BufferElement, NetworkMsg

    properties (Access = public)
        elements % Internal storage for buffer elements (cell array)
    end
    
    properties (Dependent)
        elementCount % Number of buffered elements
        transmitTimes % Array of transmission times for all elements
    end
    
    methods
        function obj = MsgBuffer()
            % MsgBuffer Constructor for an empty message buffer.
            %
            % Initializes an empty cell array to store messages.            
            
            obj.elements = {};
        end
        
        function pushTop(obj, element)
            % pushTop Adds an element to the top of the buffer (highest priority).
            %
            % The inserted element will be processed before others in the queue.
            %
            % Inputs:
            %   - element (BufferElement) : The message element to be added.

            if ~isa(element, 'BufferElement')
                error('MsgBuffer:InvalidType', 'Only BufferElement objects can be added.');
            end
            obj.elements = [{element}, obj.elements]; % Insert at front
        end
        
        function pushBack(obj, element)
            % pushBack Adds an element to the back of the buffer (FIFO behavior).
            %
            % Messages pushed to the back will be processed after earlier messages.
            %
            % Inputs:
            %   - element (BufferElement) : The message element to be added.
            
            if ~isa(element, 'BufferElement')
                error('MsgBuffer:InvalidType', 'Only BufferElement objects can be added.');
            end
            obj.elements{end + 1} = element;
        end
        
        function ret = getTop(obj)
            % getTop Retrieves the top element without removing it.
            %
            % If the buffer is empty, an error is raised.
            %
            % Outputs:
            %   - ret (BufferElement) : The highest-priority message.
            
            if obj.elementCount > 0
                ret = obj.elements{1};
            else
                error('MsgBuffer:EmptyBuffer', 'Cannot access top element, buffer is empty.');
            end
        end
        
        function obj = popTop(obj)
            % popTop Removes the top element from the buffer.
            %
            % If the buffer is empty, a warning is displayed. 

            if obj.elementCount > 0
                obj.elements(1) = [];
            else
                warning('MsgBuffer:EmptyBuffer', 'Buffer is already empty.');
            end
        end
        
        function clear(obj)
            % clear Removes all elements from the buffer.
            %
            % This method resets the buffer to an empty state.
            
            obj.elements = {};
        end
        
        function sortBuffer(obj)
            % sortBuffer Sorts elements in ascending order of transmission time.
            %
            % This ensures messages are processed in the correct order based on
            % their designated transmission times.
            
            if obj.elementCount > 1
                [~, idx] = sort(obj.transmitTimes());
                obj.elements = obj.elements(idx);
            end
        end
        
        function ret = get.elementCount(obj)
            % elementCount Returns the number of elements in the buffer.
            %
            % Outputs:
            %   - ret (integer) : Number of buffered messages.

            ret = numel(obj.elements);
        end

        function ret = get.transmitTimes(obj)
            % transmitTimes Returns an array of all transmission times.
            %
            % Outputs:
            %   - ret (double array) : List of transmission times.
            
            if obj.elementCount > 0
                ret = cellfun(@(x) x.transmitTime, obj.elements);
            else
                ret = [];
            end
        end
    end
end
