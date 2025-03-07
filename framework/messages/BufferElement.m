classdef BufferElement < handle
    % BufferElement Represents an element in the message buffer.
    % Stores a network message alongside its designated transmission time.
    %
    % Properties:
    %   - transmitTime (double) : The scheduled transmission time.
    %   - data (NetworkMsg) : The associated message.
    %
    % Methods:
    %   - BufferElement(transmitTime, data) : Constructor to initialize the element.
    
    properties (SetAccess = immutable) % Immutable after object creation
        transmitTime double % Time when the element should be sent
        data NetworkMsg % Network message
    end
    
    methods
        function obj = BufferElement(transmitTime, data)
            % Constructor for BufferElement
            %
            % Example:
            %   msg = NetworkMsg(0, 0, [1, 2, 3], 1);
            %   elem = BufferElement(5.0, msg);

            % Input validation
            validateattributes(transmitTime, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'transmitTime');
            if ~isa(data, 'NetworkMsg')
                error('BufferElement:InvalidType', 'data must be of type NetworkMsg.');
            end
            
            % Assign properties
            obj.transmitTime = transmitTime;
            obj.data = data;
        end
    end
end
