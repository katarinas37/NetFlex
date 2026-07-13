%% NetFlex: A Simulation Framework for Networked Control Systems
% Example 1: Mass Spring System under delays and data loss
% This example is based on the methodology described in:
%
% [1] K. Stanojevic, M. Steinberger, and M. Horn, 
%     “Switched Lyapunov function-based controller synthesis 
%     for networked control systems: A computationally inexpensive approach,”
%     IEEE Control Systems Letters, vol. 7, pp. 2023–2028, 2023.
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = [0,1;0,-72.5];
bc = [0;75.3];
cc = eye(size(Ac,1));
% Sampling time and simulation duration
sampleTime = 20e-3; % Discretization step (Td)
simTime = 1; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 4;
initialState = [1;0];

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
outputsSize = size(cc,1);
system = ss(Ac, bc, cc, zeros(outputsSize,inputSize)); % State-space representation
systemSim = ss(Ac,bc,eye(stateSize), zeros(outputsSize,inputSize)); % to be able to see all system states, sensor ensures that only output is sent
%% Define Network Effects
% Define network delay and packet loss data + computation time
% (max(1e-4,...)

% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysSC = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime));  % Sensor-to-Controller delays 
networkEffectsData.delaysCA = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime));  % Controller-to-Actuator delays
networkEffectsData.delaysAC = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime));  % Actuator-to-Controller delays
load tau_sim
load tauplot_complete
networkEffectsData.delaysSC = tau_sc;  % Sensor-to-Controller delays 
networkEffectsData.delaysCA = tau_sc;  % Controller-to-Actuator delays
networkEffectsData.delaysCA = max(tau_ac,1e-4);  % Actuator-to-Controller delays
networkEffectsData.dataLossCA = ones(size(generateDataLossWithMAB(1,simTime, sampleTime))); % Data loss vector for Controller-to-Actuator (MAB = 1)

sysd = c2d(system,sampleTime);
%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = [4.93 0.09]; 

%% Define Observer Parameters
% Define parameters for observer strategies
observerParams.SwitchedLyapStrategy = struct(); 

%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);
observerParams.LuenbergerObserverStrategy.l = [0.83;0.11];
%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx5(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);

%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx5_sim');

%%
function vec = generateDataLossWithMAB(MAB, simTime, sampleTime)
    % generateDataLossWithMAB Generates a binary sequence for packet dropouts.
    %
    % This function creates a sequence where:
    %   - '1' represents successful transmissions.
    %   - '0' represents packet dropouts.
    %   - No more than 'MAB' consecutive zeros appear.
    %   - The sequence length is determined by 'simTime' and 'sampleTime'.
    %
    % Inputs:
    %   - MAB (integer) : Maximum consecutive packet dropouts.
    %   - simTime (double) : Total simulation time.
    %   - sampleTime (double) : Time step between samples.
    % Output:
    %   - vec (1xN double array) : Generated binary data loss sequence.

    N = ceil(simTime / sampleTime); % Compute total number of samples
    vec = ones(1, N); % Start with all ones (all successful transmissions)
    
    i = 1; % Start index
    while i <= N
        % Randomly decide if a zero block should start (50% chance)
        if rand < 0.5 
            zeroBlockSize = randi([1, MAB]); % Random zero block length (1 to MAB)
            zeroBlockSize = min(zeroBlockSize, N - i + 1); % Prevent out-of-bounds
            vec(i:i+zeroBlockSize-1) = 0; % Insert the zero block
            i = i + zeroBlockSize; % Move index forward
        end
        % Randomly decide the number of ones before the next zero block
        onesBlockSize = randi([1, MAB]); % Randomly determine ones block
        onesBlockSize = min(onesBlockSize, N - i + 1);
        i = i + onesBlockSize; % Move index forward
    end
end
%%