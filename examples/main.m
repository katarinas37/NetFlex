%% Stability Analysis and Control Synthesis for Switched Systems: Simulation
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

% Simulation parameters
Ac = [0,1;0,0];
bc = [0;1];
cc = [1,0];
samplingTime = 5e-3; % Td

simulationTime = 0.05 * 10;
delaySteps = 8;
initialState = [0.2; 0];

% Define system
stateSize = size(bc,1);
inputSize = size(bc,2);
system = ss(Ac, bc, eye(stateSize), zeros(stateSize,1));
discreteSystem = c2d(system, samplingTime);

%% Initialize NCS plant
ncsPlant = NcsPlant(system, delaySteps, samplingTime);

controlParams.StateFeedbackStrategy.k = [10, 20, 30];

%% Create Networked Control System
ncs = NcsStructure(ncsPlant, 'simTime', simulationTime, 'controlParams', controlParams);

%% Run simulation
sim('C_sim');
return
%% Process delay results
tau = ncs.tauCaNode.delayTimes';
timeNew = (0:samplingTime:1)' + tau(1:201);
[timeNew, sortedIndices] = sort(timeNew);
value = (1:201)';

%% Plot results
figure(1);
clf; grid on; hold on;
stairs(0:samplingTime:1, 1:201, 'LineWidth', 1.2);
stairs(timeNew, value(sortedIndices), 'LineWidth', 1.2);
stairs(ramp.time, ramp.data, 'LineWidth', 1.2);
xlim([0, 0.3]);
xlabel('Time (s)');
ylabel('Step Response');
legend('Original', 'Sorted Delays', 'Ramp Data');
title('System Response with Network Delays');