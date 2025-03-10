classdef BufferElement < handle
    % BufferElement Represents an element in the message buffer.
    %
    % This class stores a network message along with its designated transmission time. 
    % It is used within message buffering systems to queue and manage messages 
    % based on their intended send time.
    %
    % Properties:
    %   - transmitTime (double) : The scheduled transmission time.
    %   - data (NetworkMsg) : The associated network message.
    %
    % Methods:
    %   - BufferElement(transmitTime, data) : Constructor to initialize the element.
    %
    % See also: MsgBuffer, NetworkMsg

    properties (SetAccess = immutable) % Immutable after object creation
        transmitTime double % Time when the element should be sent
        data NetworkMsg % Network message
    end
    
    methods
        function obj = BufferElement(transmitTime, data)
            % BufferElement Constructor for a buffer element.
            %
            % This constructor initializes a buffer element with a specific 
            % transmission time and the associated network message.
            %
            % Inputs:
            %   - transmitTime (double) : The time at which the message should be sent.
            %   - data (NetworkMsg) : The network message to be stored.
            %
            % Outputs:
            %   - obj (BufferElement) : A new instance of the BufferElement class.

            % Validate input: transmission time must be a positive real scalar
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
