classdef MsgBuffer < handle
    %BUFFER Summary of this class goes here
    %   Detailed explanation goes here
    %See also: NetworkMsg, BufferElement
    
    properties (SetAccess=private)
        elements 
    end

    
    properties (Dependent)
        transmit_times %Get transmit times of all buffered elements
        elementCount %get the number of elements currently in the buffer
    end
    
    methods
        function obj = MsgBuffer()
            %BUFFER Construct an empty buffer
            obj.elements = {};
        end
        
        function obj = push_top(obj,element)
            %add element to top
            if(~isa(element,'BufferElement'))
                error('Add only BufferElements to MsgBuffer')
            end
            obj.elements(2:end+1) = obj.elements;
            obj.elements(1) = {element};
        end
        
        function obj = push_back(obj,element)
            %add element to back
                        if(~isa(element,'BufferElement'))
                error('Add only BufferElements to MsgBuffer')
            end
            obj.elements(end+1) = {element};
        end
        
        function ret = get.elementCount(obj)
            %get specific element
            ret = numel(obj.elements);
        end

        function ret = get.transmit_times(obj)
            %get all transmit times
            ret = cellfun(@(x) x.transmit_time,obj.elements);
        end
        
        function ret = top(obj)
            %get the top element
            ret = obj.elements{1};
        end
        
        function obj = clear(obj)
            %clear the buffer
            obj.elements = {};
        end
        
        function obj = pop_top(obj)
            %remove and return the top element
            if obj.elementCount
                obj.elements(1) = [];
            else 
                obj.elements = {};
            end
        end
        
        function obj=sort(obj)
            %sort elements by transmit times
           [~,idx] = sort(obj.transmit_times);
           obj.elements = obj.elements(idx);
        end
        
        function ret = subsref(obj,idx)
            %access elements using brackets
            if(strcmp(idx(1).type,'()')|| strcmp(idx(1).type,'{}'))
                ret = subsref(obj.elements, idx);
            else
                ret = builtin('subsref',obj,idx);
            end
        end
        
        function ret = subsasgn(obj,S,B)
            %set elements using brackets
            if(strcmp(S(1).type,'()')|| strcmp(S(1).type,'{}'))
                obj.elements = subsasgn(obj.elements,S,{B});
                ret = obj;
            else
                ret = builtin('subsasgn',obj,S,B);
            end
                
        end

    end
end

