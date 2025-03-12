%% NetFlex: A Simulation Framework for Networked Control Systems
% Example 3: Example submitted to CoDit2025
% (The system under study is deliberately kept simple)
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = [0,1;0,0];
bc = [0;1];
cc = [1,0];
% Sampling time and simulation duration
sampleTime = 5e-3; % Discretization step (Td)
simTime = 40; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 15;
initialState = [0.2;0];

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
outputsSize = size(cc,1);
system = ss(Ac, bc, cc, zeros(outputsSize,inputSize)); % State-space representation
systemSim = ss(Ac,bc,eye(stateSize), zeros(outputsSize,inputSize)); % to be able to see all system states, sensor ensures that only output is sent
%% Define Network Effects
load networkeffects

% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysCA = max(1e-4,tau_ca);  % Controller-to-Actuator delays
networkEffectsData.delaysAC = max(1e-4,tau_ac);  % Actuator-to-Controller delays
networkEffectsData.delaysSC = max(1e-4,tau_sc);  % Sensor-to-Controller delays
networkEffectsData.delaysMaxSC = ceil(max(networkEffectsData.delaysSC/sampleTime))*sampleTime;

networkEffectsData.dataLossCA = vec_ca; % Data loss vector for Controller-to-Actuator
networkEffectsData.dataLossAC = vec_ac; % Data loss vector for Actuator-to-Controller
networkEffectsData.dataLossMaxAC = 2; % Data loss MAB for Controller-to-Actuator
networkEffectsData.dataLossSC = vec_sc; % Data loss vector for Sensor-to-Controller
%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = [0.057,0.289]; 
%% Define Observer Parameters
% Define parameters for observer strategies
l0 = [0.661; 9.51]; l1 = [0.176;2.56]; l2 = [0.117;1.51]; l3 = [0.0925; 0.939];
observerParams.SwitchedLyapStrategy.l = {l0,l1,l2,l3}; 
observerParams.LuenbergerObserverStrategy.l = [0.83;0.11];
observerParams.RampO = struct();
%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);
%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx3(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);
%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx3_sim');
