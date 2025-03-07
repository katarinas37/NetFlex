classdef MsgBuffer < handle
    % MsgBuffer Class for storing and managing network messages.
    % Provides efficient message queuing operations for network communication.
    %
    % Methods:
    %   - pushTop(element)    : Add element to the top (highest priority)
    %   - pushBack(element)   : Add element to the back (FIFO)
    %   - popTop()            : Remove and return the highest priority element
    %   - clear()             : Reset the buffer
    %   - sortBuffer()        : Sort elements by transmission time
    %   - getElementCount()   : Returns the number of elements
    %   - getTransmitTimes()  : Returns an array of transmit times
    %   - getTop()            : Returns the top element without removing it

    properties (Access = private)
        elements % Internal storage for buffer elements
    end
    
    properties (Dependent)
        elementCount % Returns the number of buffered elements
        transmitTimes % Returns an array of all transmit times
    end
    
    methods
        function obj = MsgBuffer()
            % Constructor: Initializes an empty buffer.
            obj.elements = {};
        end
        
        function pushTop(obj, element)
            % Adds an element to the top of the queue (highest priority).
            if ~isa(element, 'BufferElement')
                error('MsgBuffer:InvalidType', 'Only BufferElement objects can be added.');
            end
            obj.elements = [{element}, obj.elements]; % Insert at front
        end
        
        function pushBack(obj, element)
            % Adds an element to the back of the queue (FIFO behavior).
            if ~isa(element, 'BufferElement')
                error('MsgBuffer:InvalidType', 'Only BufferElement objects can be added.');
            end
            obj.elements{end + 1} = element;
        end
        
        function ret = getTop(obj)
            % Returns the top element without removing it.
            if obj.elementCount > 0
                ret = obj.elements{1};
            else
                error('MsgBuffer:EmptyBuffer', 'Cannot access top element, buffer is empty.');
            end
        end
        
        function popTop(obj)
            % Removes the top element from the queue.
            if obj.elementCount > 0
                obj.elements(1) = [];
            else
                warning('MsgBuffer:EmptyBuffer', 'Buffer is already empty.');
            end
        end
        
        function clear(obj)
            % Clears all elements from the buffer.
            obj.elements = {};
        end
        
        function sortBuffer(obj)
            % Sorts elements by transmit time (ascending order).
            if obj.elementCount > 1
                [~, idx] = sort(obj.transmitTimes());
                obj.elements = obj.elements(idx);
            end
        end
        
        function ret = get.elementCount(obj)
            % Returns the number of elements in the buffer.
            ret = numel(obj.elements);
        end

        function ret = get.transmitTimes(obj)
            % Returns an array of transmit times for all elements.
            if obj.elementCount > 0
                ret = cellfun(@(x) x.transmitTime, obj.elements);
            else
                ret = [];
            end
        end
    end
end
