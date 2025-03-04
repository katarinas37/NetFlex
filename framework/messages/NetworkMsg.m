classdef NetworkMsg
    %NETWORKMSG Object which is sent through the network containing all neccessary 
    %information
    %
    % Msg = NetworkMsg(sampling_timestamp, last_transmit_timestamp, data, seq)
    %  sampling_timestamp...timestamp of the sensor
    %  last_transmit_timestamp...timestamp when the message was last transmitted
    %  data...measurement data
    %  seq...sequence number
    properties
        data %measurement data
        sampling_timestamp %timestamp of the sensor
        last_transmit_timestamp %timestamp when the message was last transmitted
        seq %sequence number
    end
    
    methods
        function obj = NetworkMsg(sampling_timestamp, last_transmit_timestamp, data, seq)
            %NETWORKMSG Construct an instance of this class
            %sampling_timestamp...timestamp of the sensor
            %last_transmit_timestamp...timestamp when the message was transmitted the last time
            %data...measurement data
            %seq...sequence number
            obj.sampling_timestamp = sampling_timestamp;
            obj.last_transmit_timestamp = last_transmit_timestamp;
            obj.data = data;
            obj.seq = seq;
        end
    end
end

