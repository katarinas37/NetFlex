 %% Example 2: Observer-Based Switched Control of a DC Motor
%
% This example demonstrates how NetFlex can be used to implement an
% advanced networked control system with communication-aware control and
% state estimation.
%
% The simulated system is a DC motor controlled over a communication
% network affected by time-varying delays and packet dropouts. The example
% implements an observer-based switched state-feedback controller together
% with all required communication preprocessing mechanisms.
%
% The example includes:
%   - Time-varying communication delays
%   - Packet dropouts
%   - Message rejection
%   - Network buffering
%   - Delay-dependent signal selection
%   - Pairing and ordering of delayed messages
%   - Observer-based state estimation
%   - Switched state-feedback control
%
% Plant:
%   Continuous-time DC motor
%
% Observer:
%   Discrete-time Luenberger observer.
%
% Controller:
%   Delay-dependent switched state-feedback controller.
%
% Purpose:
%   This example illustrates how multiple NetFlex nodes can be combined to
%   realize a complete networked control architecture with realistic
%   communication effects. It demonstrates how communication handling,
%   preprocessing, state estimation, and control can be implemented as
%   reusable modular components while keeping the control algorithm itself
%   independent of the communication infrastructure.
%
% After running the simulation, the closed-loop response, estimation error,
% and applied control input can be analyzed.
%
% This example implements the observer-based switched control architecture
% presented in:
%
% [1] K. Stanojevic, M. Steinberger, and M. Horn,
%     "Switched Lyapunov Function-Based Controller Synthesis for
%     Networked Control Systems: A Computationally Inexpensive Approach,"
%     IEEE Control Systems Letters, vol. 7, pp. 2023-2028, 2023.
%
% [2] K. Stanojevic, M. Steinberger, and M. Horn,
%     "State Estimation in Networked Control Systems with Time-Varying
%     Delays: A Simple yet Powerful Observer Framework,"
%     Proc. IEEE 63rd Conference on Decision and Control (CDC),
%     Milan, Italy, 2024, pp. 6916-6921.
%
% This example corresponds to Example 2 in:
% Stanojevic et al., "NetFlex: A Flexible Control-Oriented Simulation
% Framework for Networked Control Systems."
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = [0,1;0,-72.5];
bc = [0;75.3];
cc = [1 0];
% Sampling time and simulation duration
sampleTime = 20e-3; % Discretization step (Td)
simTime = 1; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 5;
initialState = [1;0];

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
system = ss(Ac, bc, [1 0], 0); % State-space representation
systemSim = ss(Ac,bc,eye(2),0);
%% Define Network Effects
% Define network delay and packet loss data 

% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysSC = 2*sampleTime*rand(1,ceil(simTime)/sampleTime);  % Sensor-to-Controller delays
networkEffectsData.delaysCA = 2*sampleTime*rand(1,ceil(simTime)/sampleTime);  % Controller-to-Actuator delays
networkEffectsData.delaysAC = 2*sampleTime*rand(1,ceil(simTime)/sampleTime);  % Controller-to-Actuator delays
networkEffectsData.dataLossCA = generateDataLossWithMAB(1,simTime, sampleTime); % Data loss vector for Controller-to-Actuator (MAB = 1)
%% Define Control Parameters
% Define parameters for control strategies
% State Feedback Control
k1 = [5.8586 0.0821];
k2 = [5.4862 0.0666];
k3 = [5.5780 0.0712];
k4 = [5.7655 0.0782];
k5 = [6.1134 0.0729];
controlParams.StateFeedbackStrategy.k = [k1;k2;k3;k4;k5]; 
%% Define Observer Parameters
% Define parameters for observer strategies
observerParams.LuenbergerObserverStrategy.l = [0.83;0.11];

%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);

%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx6(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);

%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx6_sim');

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

%% Graphical representation (paper plots)
OBS = NCS.allNodes{11};   % observer node
xhat = [zeros(2,1),OBS.sendHistoryData]; % state estimates
SENS = NCS.allNodes{12};  % sensor node
y = SENS.sendHistoryData; % output measurement
CONT = NCS.allNodes{1};   % controller node
ukpacket = CONT.sendHistoryData; % data packets containing different uk^*
SELECT = NCS.allNodes{4}; % selector node
uStar = SELECT.sendHistoryData; % data selector selects for the application

numSamples = 50; % plot duration = 50*sampleTime
%--------------------------------------------------------------------------
figure(1)
clf, 
subplot(2,1,1)
title('Estimation Error','Interpreter','Latex','FontSize',20)
grid on, hold on, box on
stairs(0:sampleTime:49*sampleTime,x.data(1:numSamples,1)'-xhat(1,1:numSamples),'Linewidth',1.5)
ylabel('$e_{1,k} = x_{1,k}-\hat{x}_{1,k}$','Interpreter','latex','FontSize',16)
subplot(2,1,2)
grid on, hold on, box on
stairs(0:sampleTime:49*sampleTime,x.data(1:numSamples,2)'-xhat(2,1:numSamples),'Linewidth',1.5)
ylabel('$e_{2,k} = x_{2,k}-\hat{x}_{2,k}$','Interpreter','latex','FontSize',16)
xlabel('Time $t$','Interpreter','latex','FontSize',16)
xlim([0,numSamples*sampleTime])
%--------------------------------------------------------------------------
figure(2)
clf, 
subplot(2,1,1)
title('Evolution of the System States','Interpreter','Latex','FontSize',20)
grid on, hold on
stairs(0:sampleTime:49*sampleTime,x.data(1:50,1)','Linewidth',1.5)
ylabel('$x_{1,k}$','Interpreter','latex','FontSize',16)
subplot(2,1,2)
grid on, hold on
stairs(0:sampleTime:49*sampleTime,x.data(1:50,2)','Linewidth',1.5)
ylabel('$x_{2,k}$','Interpreter','latex','FontSize',16)
xlabel('Time $t$','Interpreter','latex','FontSize',16)
xlim([0,numSamples*sampleTime])
%--------------------------------------------------------------------------
colors = [0.99 0.85 0.90; 0.98 0.70 0.78; 0.95 0.52 0.63; 0.86 0.29 0.39; 0.70 0.08 0.17];
figure(3)
clf;grid on; hold on
title('Candidate control signals and the applied control signal','Interpreter','Latex','FontSize',20)
stairs((0:sampleTime:49*sampleTime),[0;ukpacket(1,1:49)'],'LineWidth',2.5, 'Color', colors(1,:))
stairs((0:sampleTime:49*sampleTime)+sampleTime*1,[0;ukpacket(2,1:numSamples-1)'],'LineWidth',2.5, 'Color', colors(2,:))
stairs((0:sampleTime:49*sampleTime)+sampleTime*2,[0;ukpacket(3,1:numSamples-1)'],'LineWidth',2.5, 'Color', colors(3,:))
stairs((0:sampleTime:49*sampleTime)+sampleTime*3,[0;ukpacket(4,1:numSamples-1)'],'LineWidth',2.5, 'Color', colors(4,:))
stairs((0:sampleTime:49*sampleTime)+sampleTime*4,[0;ukpacket(5,1:numSamples-1)'],'LineWidth',2.5  , 'Color', colors(5,:))
stairs([0;SELECT.sendHistoryTime'],[0;uStar'],'LineWidth',2 ,'LineStyle','--','Color','b')
xlim([0,0.6])
legend({'$u_k$','$u_{k-1}$','$u_{k-2}$','$u_{k-3}$','$u_{k-4}$','$u_k^*$'},...
    'Interpreter','Latex', 'Location', 'best','FontSize',16)
xticks(0:20e-3:0.6)
