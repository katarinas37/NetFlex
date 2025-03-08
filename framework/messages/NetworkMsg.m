classdef NetworkMsg
    % NetworkMsg Represents a message sent through the network.
    % Stores measurement data along with TSing and sequencing information.
    %
    % Properties:
    %   - samplingTS (double) : Timestamp of the sensor at message creation.
    %   - lastTransmitTS (double) : Timestamp of the last transmission.
    %   - data (double) : Measurement data stored as a numeric vector/matrix.
    %   - seqNr(uint32) : Sequence number of the message.
    %
    % Methods:
    %   - NetworkMsg(samplingTS, lastTransmitTS, data, seqNr) 
    %     : Constructs a network message with required attributes.
    
    properties (SetAccess = public) % Prevent modification after initialization
        samplingTS double % TS of the sensor
        lastTransmitTS double % Last time message was transmitted
        data double % Measurement data (vector/matrix)
        seqNr int32 % Sequence number
    end
    
    methods
        function obj = NetworkMsg(samplingTS, lastTransmitTS, data, seqNr)
            % NetworkMsg Constructor for a network message.
            %
            % Example:
            %   msg = NetworkMsg(0.1, 0.2, [1, 2, 3], 1);
            
            % Input validation
            validateattributes(samplingTS, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'samplingTS');
            validateattributes(lastTransmitTS, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'lastTransmitTS');
            validateattributes(data, {'numeric'}, {'nonempty', 'real', 'finite'}, mfilename, 'data');
            validateattributes(seqNr, {'numeric'}, {'scalar', 'integer', 'nonnegative'}, mfilename, 'seq');

            % Assign properties
            obj.samplingTS = samplingTS;
            obj.lastTransmitTS = lastTransmitTS;
            obj.data = data;
            obj.seqNr = uint32(seqNr);
        end
    end
end
