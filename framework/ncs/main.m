%% NetFlex: A Simulation Framework for Networked Control Systems
% This script initializes and runs a TrueTime-based simulation for a 
% Networked Control System (NCS). It defines the system dynamics, 
% network effects, control strategies, observer parameters, and simulates 
% the networked control loop under delays and data losses.

clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = [0,1;0,0];  % State transition matrix
bc = [0;1];      % Input matrix
cc = [1,0];      % Output matrix

% Sampling time and simulation duration
sampleTime = 5e-3; % Discretization step (Td)
simTime = sampleTime * 50; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 8;
initialState = [0.2; 0];

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
system = ss(Ac, bc, eye(stateSize), zeros(stateSize,1)); % State-space representation

%% Define Network Effects
% Load network delay and packet loss data if available
% Optional: Load pre-recorded network effects from a .mat file
load networkeffects

% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysCA = tau_ca;  % Controller-to-Actuator delays
networkEffectsData.delaysAC = tau_ac;  % Actuator-to-Controller delays
networkEffectsData.delaysSC = tau_sc;  % Sensor-to-Controller delays
networkEffectsData.dataLossCA = vec_ca; % Data loss vector for Controller-to-Actuator
networkEffectsData.dataLossAC = vec_ac; % Data loss vector for Actuator-to-Controller
networkEffectsData.dataLossSC = vec_sc; % Data loss vector for Sensor-to-Controller

%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = [10, 20]; 

% Extended State Feedback Control (including delayed states)
controlParams.ExtendedStateFeedbackStrategy.k = [1,-2,12,zeros(1,delaySteps-1)];

%% Define Observer Parameters
% Define parameters for observer strategies
observerParams.SwitchedLyapStrategy = struct(); 

%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);

%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructure(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);

%% Run Simulation
% Execute the Simulink simulation
sim('NCS_sim');
