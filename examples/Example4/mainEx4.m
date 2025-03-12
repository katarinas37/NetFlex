%% NetFlex: A Simulation Framework for Networked Control Systems
% Example 4: Mass Spring System under delays and data loss
% with unmeasurable states
% This example is based on the methodology described in
% K. Stanojevic, M. Steinberger, and M. Horn, “Robust state estimation
% in networked control systems under data loss and delays: A switched
% lyapunov funtion based approach,” in 2025 European Control Confer-
% ence (ECC), 2025, p. accepted.
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
m = 0.18;  %[kg]
c = 3.840; %[Nm-1]
k = 0.042; %[kgs-1]
b = 0.086; %[ms-1]

Ac = [0,1,0;-c/m,-k/m,c/m;0,0,0];
bc = [0;0;b];
cc = [1,0,0];
% Sampling time and simulation duration
sampleTime = 5e-3; % Discretization step (Td)
simTime = 6; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 5;
initialState = [0.1;0;0.1];

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
outputsSize = size(cc,1);
system = ss(Ac, bc, cc, zeros(outputsSize,inputSize)); % State-space representation
systemSim = ss(Ac,bc,eye(stateSize), zeros(outputsSize,inputSize)); % to be able to see all system states, sensor ensures that only output is sent
%% Define Network Effects
%
% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysCA = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime)-1e-4);  % Controller-to-Actuator delays
networkEffectsData.delaysAC = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime+2)-1e-4);  % Actuator-to-Controller delays
networkEffectsData.delaysSC = max(1e-4,2*sampleTime*rand(1,ceil(simTime)/sampleTime)-1e-4);  % Sensor-to-Controller delays
networkEffectsData.delaysMaxSC = ceil(max(networkEffectsData.delaysSC/sampleTime))*sampleTime;

networkEffectsData.dataLossCA = ones(1,ceil(simTime)/sampleTime); % Data loss vector for Controller-to-Actuator
networkEffectsData.dataLossAC = generateDataLossWithMAB(2,simTime, sampleTime); % Data loss vector for Actuator-to-Controller
networkEffectsData.dataLossMaxAC = 2; % Data loss MAB for Controller-to-Actuator
networkEffectsData.dataLossSC = generateDataLossWithMAB(3,simTime, sampleTime); % Data loss vector for Sensor-to-Controller
%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = [-9.88 -0.41 16.15]; 
%% Define Observer Parameters
% Define parameters for observer strategies
l0 = [0.65 2.14 0.38]'; l1 = [0.18 0.54 0.1]'; l2 = [0.12 0.32 0.07]'; l3 = [0.095 0.19 0.05]';
observerParams.SwitchedLyapStrategy.l = {l0,l1,l2,l3}; 
observerParams.LuenbergerObserverStrategy.l = [0.83;0.11];
observerParams.RampO = struct();
%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);
%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx4(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);
%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx4_sim');
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

    N = ceil(simTime / sampleTime)+MAB; % Compute total number of samples
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