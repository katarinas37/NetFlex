%% NetFlex: A Simulation Framework for Networked Control Systems
% Example 2: Rotary Servo under delays with the measurable angle as an output. 
% This example is based on the methodology described in:
%
% [1] K. Stanojevic, M. Steinberger, and M. Horn, 
%     “Switched Lyapunov function-based controller synthesis 
%     for networked control systems: A computationally inexpensive approach,”
%     IEEE Control Systems Letters, vol. 7, pp. 2023–2028, 2023.
% 
% [2] K. Stanojevic, M. Steinberger and M. Horn, "State Estimation in 
% Networked Control Systems with Time-Varying Delays: A Simple yet Powerful
% Observer Framework," 2024 IEEE 63rd Conference on Decision and Control 
% (CDC), Milan, Italy, 2024, pp. 6916-6921
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = [0,1;0,-72.5];
bc = [0;75.3];
cc = [1,0];
% Sampling time and simulation duration
sampleTime = 20e-3; % Discretization step (Td)
simTime = 1; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 3;
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
%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = [7.27,0.14]; 
%% Define Observer Parameters
% Define parameters for observer strategies
observerParams.SwitchedLyapStrategy = struct(); 
observerParams.LuenbergerObserverStrategy.l = [0.83;0.11];
%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);
%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx2(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);
%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx2_sim');
