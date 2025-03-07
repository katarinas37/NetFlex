classdef NetworkMsg
    % NetworkMsg Represents a message sent through the network.
    % Stores measurement data along with timestamping and sequencing information.
    %
    % Properties:
    %   - samplingTimestamp (double) : Timestamp of the sensor at message creation.
    %   - lastTransmitTimestamp (double) : Timestamp of the last transmission.
    %   - data (double) : Measurement data stored as a numeric vector/matrix.
    %   - seq (uint32) : Sequence number of the message.
    %
    % Methods:
    %   - NetworkMsg(samplingTimestamp, lastTransmitTimestamp, data, seq) 
    %     : Constructs a network message with required attributes.
    
    properties (SetAccess = public) % Prevent modification after initialization
        samplingTimestamp double % Timestamp of the sensor
        lastTransmitTimestamp double % Last time message was transmitted
        data double % Measurement data (vector/matrix)
        seq uint32 % Sequence number
    end
    
    methods
        function obj = NetworkMsg(samplingTimestamp, lastTransmitTimestamp, data, seq)
            % NetworkMsg Constructor for a network message.
            %
            % Example:
            %   msg = NetworkMsg(0.1, 0.2, [1, 2, 3], 1);
            
            % Input validation
            validateattributes(samplingTimestamp, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'samplingTimestamp');
            validateattributes(lastTransmitTimestamp, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'lastTransmitTimestamp');
            validateattributes(data, {'numeric'}, {'nonempty', 'real', 'finite'}, mfilename, 'data');
            validateattributes(seq, {'numeric'}, {'scalar', 'integer', 'nonnegative'}, mfilename, 'seq');

            % Assign properties
            obj.samplingTimestamp = samplingTimestamp;
            obj.lastTransmitTimestamp = lastTransmitTimestamp;
            obj.data = data;
            obj.seq = uint32(seq);
        end
    end
end
