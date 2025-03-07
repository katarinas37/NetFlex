classdef NetworkDelayWithDropouts < VariableDelay
    %NETWORKDELAY  Object which configures the true time kernel to act as a variable network delay
    
    properties
        tau         % Vector of time delay for this channel
        dataLoss    % Vector of data loss for this channel
        dataLossMax % Max nr of consecutive data dropouts
        Td          % Sampling time
    end
    
    methods
        function obj = NetworkDelayWithDropouts(Nout, nextnode, nodenumber, tau, dataLoss, dataLossMax,Td)
            %NETWORKDELAY Construct an instance of this class
            % tau...Vector of time delay for each received message
            %See also: VariableDelay, NetworkNode
            obj = obj@VariableDelay(Nout, nextnode, nodenumber);
            obj.tau = tau;
            obj.dataLoss = dataLoss;
            obj.dataLossMax = dataLossMax;
            obj.Td = Td;
        end
        
        function [transmit_time,rx_msg] = calculate_transmit_time(obj, rx_msg) 

            % New buffering Mechanism:
            % Theory - buffer sends [uk,uk-1,uk-2,...uk-pAC], as soon as
            % the packet arrives with the necessary signal, the whole
            % vector is stored
            % Implementation - individual packets are sent. The transmit
            % time is calculated by comparing the arrival of the packet
            % with sequence number k, k+1,... k+p_AC. If dropout occurs for
            % any of the packets, the delay is set to 1e6

            % vec: vector with dropout sequence (0=dropout,1=received)
            % p_AC_ nr of allowable consecutive lost data packets
%             load dataloss_AC.mat 
%             temp = [];
%             for k = 0:p_AC
%                 transmit = ~dataloss_AC(rx_msg.seq+k)*(obj.tau(rx_msg.seq+k) + rx_msg.last_transmit_timestamp(end)+obj.Td*k-1e-6)+...
%                            +dataloss_AC(rx_msg.seq+k)*1e6;
%                 temp = [temp, transmit];
%             end
%            transmit_time = min(temp);
% %            transmit_time = obj.tau(rx_msg.seq) +rx_msg.last_transmit_timestamp(end); % NO DROPOUTS
%            clear temp 


%             vec: vector with dropout sequence (01=dropout,1=received)
%             p_AC_ nr of allowable consecutive lost data packets
            load networkeffects.mat 
            p_AC = 2;
            temp = [];
            dataloss_AC = vec_ac;


%             for k = 0:p_AC
%                 transmit = dataloss_AC(rx_msg.seq+k)*(obj.tau(rx_msg.seq+k) + rx_msg.last_transmit_timestamp(end)+obj.Td*k-1e-6)+...
%                            +~dataloss_AC(rx_msg.seq+k)*1e6;
%                 temp = [temp, transmit];
%             end
%            transmit_time = min(temp);
% %            transmit_time = obj.tau(rx_msg.seq) +rx_msg.last_transmit_timestamp(end); % NO DROPOUTS
%            clear temp 

           for k = 0:obj.dataLossMax
                transmitTimes = obj.dataLoss(rx_msg.seq+k)*(obj.tau(rx_msg.seq+k) + rx_msg.last_transmit_timestamp(end)+obj.Td*k-1e-6)+...
                           +~obj.dataLoss(rx_msg.seq+k)*1e6;
                temp = [temp, transmitTimes];
           end
           transmit_time = min(temp);
           clear temp 
        end
        
        function init(obj)
            %init function to reset the counter and the VariableDelay object
           init@VariableDelay(obj);
        end
    end
end

