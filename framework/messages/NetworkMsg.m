classdef NetworkMsg
    % NetworkMsg Represents a message sent through the network.
    %
    % This class models a network message that carries sensor data along with
    % timestamping and sequencing information. 
    %
    % Properties:
    %   - samplingTS (double) : Timestamp when the sensor generated the measurement.
    %   - lastTransmitTS (double) : Timestamp when the message was last transmitted.
    %   - data (double array) : Measurement data stored as a numeric vector or matrix.
    %   - seqNr (uint32) : Sequence number of the message.
    %   - nodeId (uint32) : Unique node identifier from which the message was sent.
    %
    % Methods:
    %   - NetworkMsg(samplingTS, lastTransmitTS, data, seqNr, nodeId) 
    %     : Constructs a network message with required attributes.
    %
    % See also: NetworkNode, NetworkBuffer
    
    properties (SetAccess = public)
        samplingTS double % Timestamp when the sensor generated the measurement
        lastTransmitTS double % Timestamp of the last message transmission
        data double % Measurement data (vector or matrix)
        seqNr uint32 % Sequence number of the message
        nodeId uint32 % Unique node identifier from which the message was sent 
    end
    
    methods
        function obj = NetworkMsg(samplingTS, lastTransmitTS, data, seqNr, nodeId)
            % NetworkMsg Constructor for a network message.
            %
            % This constructor initializes a network message with required properties,
            % ensuring that the data is valid and formatted correctly.
            %
            % Inputs:
            %   - samplingTS (double) : Timestamp when the sensor measurement was taken.
            %   - lastTransmitTS (double) : Timestamp of the last message transmission.
            %   - data (double array) : Measurement data in numeric format.
            %   - seqNr (integer) : Sequence number of the message.
            %   - nodeId (integer) : Identifier of the node that sent the message.
            %
            % Outputs:
            %   - obj (NetworkMsg) : A new instance of the NetworkMsg class.
            
            % Input validation
            validateattributes(samplingTS, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'sampling TS');
            validateattributes(lastTransmitTS, {'numeric'}, {'scalar', 'real', 'nonnegative'}, mfilename, 'lastTransmit TS');
            validateattributes(data, {'numeric'}, {'nonempty', 'real', 'finite'}, mfilename, 'data');
            validateattributes(seqNr, {'numeric'}, {'scalar', 'integer', 'nonnegative'}, mfilename, 'seq Nr');
            validateattributes(nodeId, {'numeric'}, {'scalar', 'integer', 'nonnegative'}, mfilename, 'node ID');

            % Assign properties
            obj.samplingTS = samplingTS;
            obj.lastTransmitTS = lastTransmitTS;
            obj.data = data;
            obj.seqNr = uint32(seqNr);
            obj.nodeId = uint32(nodeId);
        end
    end
end
