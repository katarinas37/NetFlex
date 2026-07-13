%% Example 1: Signal Propagation Through a Networked Control System
%
% This example demonstrates the basic workflow of NetFlex using a simple
% networked control system. A sampled ramp signal is transmitted through a
% sequence of communication and processing nodes, allowing the influence of
% each node on the propagated data to be inspected individually.
%
% The example includes:
%   - Sensor sampling
%   - Time-varying network delays
%   - Packet dropouts
%   - Message rejection
%   - Node-wise signal history visualization
%
% Plant:
%   x_dot = 1
%   y = x
%
% Controller:
%   u_k = y_k
%
% Purpose:
%   The controller does not modify the signal but simply forwards it,
%   making it easy to visualize how communication effects alter the data
%   as it propagates through the network.
%
% After running the simulation, the histories stored in each NetFlex node
% are used to visualize the received and transmitted signals, illustrating
% delays, packet losses, and message rejection.
%
% This example corresponds to Example 1 in:
% Stanojevic et al., "NetFlex: A Flexible Control-Oriented Simulation
% Framework for Networked Control Systems."
clear; clc;

% Initialize TrueTime (Uncomment if required)
% run('libs/truetime-2.0/init_truetime.m')

%% Simulation Parameters
% Define the continuous-time system dynamics.
Ac = 0;
bc = 1;
cc = 1;

% Sampling time and simulation duration
sampleTime = 1; % Discretization step (Td)
simTime = 20; % Total simulation time

% Number of delay steps and initial system state
delaySteps = 4;
initialState = 1;

% Define system properties
stateSize = size(bc,1);
inputSize = size(bc,2);
system = ss(Ac, bc, cc, 0); % State-space representation

%% Define Network Effects
% Define network delay and packet loss data 

% Store network effects in a structured format
networkEffectsData = struct;
networkEffectsData.delaysSC = 0.25 * round(11 * rand(1, ceil(simTime / sampleTime)))+0.25;  % Sensor-to-Controller delays
networkEffectsData.dataLossCA = generateDataLossWithMAB(1,simTime, sampleTime); % Data loss vector for Controller-to-Actuator (MAB = 1)
load neteff.mat
networkEffectsData.delaysSC = max(networkEffectsData.delaysSC,0.25);
%% Define Control Parameters
% Define different control strategies for comparison

% Simple Ramp Control (used for debugging, increasing sequence values)
controlParams.RampC = struct();

% State Feedback Control
controlParams.StateFeedbackStrategy.k = -1; 

%% Define Observer Parameters
% Define parameters for observer strategies
observerParams.SwitchedLyapStrategy = struct(); 

%% Initialize NCS Plant
% Create the NCS plant model using defined system dynamics
ncsPlant = NcsPlant(system, delaySteps, sampleTime);

%% Create Networked Control System
% Initialize the NCS structure with defined components
NCS = NcsStructureEx0(ncsPlant, 'simTime', simTime, ...
                   'networkEffectsData', networkEffectsData, ...
                   'controlParams', controlParams, ...
                   'observerParams', observerParams);

%% Run Simulation
% Execute the Simulink simulation
sim('NCSEx0_sim');

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

%% Graphical Representation
delayNode = NCS.allNodes{3};
[delayNode.sendHistoryTime,idx] = sort(delayNode.sendHistoryTime);
delayNode.sendHistoryData = delayNode.sendHistoryData(idx);

contNode = NCS.allNodes{1};
dataLoss = NCS.allNodes{4};

msgRejNode = NCS.allNodes{2};


blue   = [0.0000 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];
yellow = [0.9290 0.6940 0.1250];
purple = [0.4940 0.1840 0.5560];
green  = [0.4660 0.6740 0.1880];
cyan   = [0.3010 0.7450 0.9330];
red    = [0.6350 0.0780 0.1840];

figure(1)
clf; hold on; grid on; box on
subplot(5,1,1)
hold on; grid on; box on; xlim([0,10])
plot([0:19],[1:20],'LineStyle','--','LineWidth',2.5,'Color','k')
stairs([0:19],[1:20],'LineStyle','-','LineWidth',2.5,'Color','k','Marker','*','MarkerSize',10)
ylabel('Data','Interpreter','latex','FontSize',16)
title('Sensor Node','Interpreter','latex','FontSize',20)
legend({'Received data', 'Sent data'},'Interpreter','latex','FontSize',16,'Location','southeast')
subplot(5,1,2)
hold on; grid on; box on; xlim([0,10])
stairs(delayNode.rcvHistoryTime,delayNode.rcvHistoryData,'LineStyle','--','LineWidth',1.5,'Color',yellow,'Marker','o','MarkerSize',10)
stairs(delayNode.sendHistoryTime,delayNode.sendHistoryData,'LineStyle','-','LineWidth',2.5,'Color',yellow,'Marker','*','MarkerSize',10)
legend({'Received data', 'Sent data'},'Interpreter','latex','FontSize',16,'Location','southeast')

ylabel('Data','Interpreter','latex','FontSize',16)
title('Delay Node','Interpreter','latex','FontSize',20)
subplot(5,1,3)
hold on; grid on; box on; xlim([0,10])
stairs(contNode.rcvHistoryTime,contNode.rcvHistoryData,'LineStyle','-','LineWidth',1.5,'Color',blue,'Marker','o','MarkerSize',10)
stairs(contNode.sendHistoryTime,contNode.sendHistoryData,'LineStyle','--','LineWidth',2.5,'Color',blue,'Marker','*','Marker','*','MarkerSize',10)
ylabel('Data','Interpreter','latex','FontSize',16)
title('Controller Node','Interpreter','latex','FontSize',20)
legend({'Received data', 'Sent data'},'Interpreter','latex','FontSize',16,'Location','southeast')

subplot(5,1,4)
hold on; grid on; box on; xlim([0,10])
stairs(dataLoss.rcvHistoryTime,dataLoss.rcvHistoryData,'LineStyle','-','LineWidth',1.5,'Color',green,'Marker','o','Marker','*','MarkerSize',10)
stairs(dataLoss.sendHistoryTime(dataLoss.sendHistoryTime<=10),dataLoss.sendHistoryData(dataLoss.sendHistoryTime<=10),'LineStyle','--','LineWidth',2.5,'Color',green,'Marker','*','Marker','*','MarkerSize',10)
ylabel('Data','Interpreter','latex','FontSize',16)
title('Data-loss Node','Interpreter','latex','FontSize',20)
legend({'Received data', 'Sent data'},'Interpreter','latex','FontSize',16,'Location','southeast')

subplot(5,1,5)
hold on; grid on; box on; xlim([0,10])
r = stairs(msgRejNode.rcvHistoryTime,msgRejNode.rcvHistoryData,'LineStyle','-','LineWidth',1.5,'Color','r','Marker','o','MarkerSize',10);
m= stairs(msgRejNode.sendHistoryTime,msgRejNode.sendHistoryData,'LineStyle','--','LineWidth',2.5,'Color',purple,'Marker','*','MarkerSize',10);
ylabel('Data','Interpreter','latex','FontSize',16)
title('Message Rejection Node','Interpreter','latex','FontSize',20)
xlabel('Time $t$','Interpreter','latex','FontSize',16)
legend({'Received data', 'Sent data'},'Interpreter','latex','FontSize',16,'Location','southeast')
