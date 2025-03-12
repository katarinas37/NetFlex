classdef RampO < IObserverStrategy
    % RampO Implements a simple ramp strategy for debugging purposes.
    %
    % This observer outputs a ramp signal where the predicted state estimates 
    % increase proportionally to the sequence number of the received message.
    %
    % This class is useful for debugging network timing issues or validating 
    % that messages are being processed in the expected order.
    %
    % Properties:
    %   - (None) : This observer does not require any internal properties.
    %
    % Methods:
    %   - RampO(ncsPlant) : Constructor.
    %   - execute(rcvMsg, observerParams, ncsPlant) : Generates state estimates.
    %
    % See also: IObserverStrategy

    properties
        % No properties are needed for this observer, as the output is 
        % directly based on the received message sequence number.
    end

    methods
        function obj = RampO(ncsPlant)
            % RampO Constructor for the Ramp observer.
            %
            % This observer does not need to store any state, so the 
            % constructor remains empty.
            %
            % Inputs:
            %   - ncsPlant (NcsPlant) : Reference to the system model.
            
            % No initialization required since the observer does not maintain state.
        end

        function [predictedEstimates, obj] = execute(obj, rcvMsg, ~, ncsPlant, ~)
            % execute Computes the observer output.
            %
            % This observer generates a ramp output where each state estimate
            % is set to the sequence number of the received message.
            %
            % This method is primarily used for debugging purposes, as it allows 
            % the user to track message sequence numbers in the observer output.
            %
            % Inputs:
            %   - rcvMsg (NetworkMsg) : Received message containing sensor data.
            %   - ncsPlant (NcsPlant) : Reference to the system model.
            %
            % Outputs:
            %   - predictedEstimates (double vector) : A vector where each element
            %     is set to the sequence number of the received message.
            %   - obj (RampO) : The updated observer object.
            
            % Generate a vector where all elements are equal to the received message's sequence number.
            predictedEstimates = double(rcvMsg.seqNr) * ones(ncsPlant.stateSize, 1); 
        end
    end
end