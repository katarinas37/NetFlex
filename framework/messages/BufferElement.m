classdef BufferElement <handle
    %BUFFERELEMENT 
    %See also: NetworkMsg, MsgBuffer
    
    properties (SetAccess=private)
        transmit_time %Time when the element should be sent
        data NetworkMsg
    end
    

    methods
        function obj = BufferElement(transmit_time, data)
            %BUFFERELEMENT Construct an instance of this class
            %transmit_time: Time when the element should be sent
            %data: NetworkMsg element
            %See also: NetworkMsg
            obj.transmit_time = transmit_time;
            obj.data = data;
        end
    end
end

