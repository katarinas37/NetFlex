classdef NetworkDelay < VariableDelay
    %NETWORKDELAY  Object which configures the true time kernel to act as a variable network delay
    
    properties
        tau %Vector of time delay for each received message
    end
    
    methods
        function obj = NetworkDelay(Nout, nextnode, nodenumber, tau)
            %NETWORKDELAY Construct an instance of this class
            % tau...Vector of time delay for each received message
            %See also: VariableDelay, NetworkNode
            obj = obj@VariableDelay(Nout, nextnode, nodenumber);
            obj.tau = tau;
        end
        
        function transmit_time = calculate_transmit_time(obj, rx_msg) 
            %transmit_time = calculate_transmit_time(obj, rx_msg) 
            %Set the transmit time such that the message is transmitted after the current time delay
            ttCurrentTime;
            transmit_time = obj.tau(rx_msg.seq) + rx_msg.last_transmit_timestamp(end);
        end
        
        function init(obj)
            %init function to reset the counter and the VariableDelay object
           init@VariableDelay(obj);
        end
    end
end

