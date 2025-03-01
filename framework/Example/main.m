%% Stability Analysis and Control Synthesis for Switched Systems: 
% Simulation
clear; clc;
% run('/Users/kala/Documents/truetime-2.0/init_truetime.m')
addpath('/Users/kala/Desktop/T')

Ac = [0,1;0,0];
bc = [0;1];
cc = [1,0];
Td = 5e-3;

tsim = 0.05*10;

d = 8;
x0 = [0.2;0];

n = size(bc,1); m = size(bc,2);
sys = ss(Ac,bc,eye(n),zeros(n,1));
sys_d = c2d(sys,Td);
%%
ncsPlant_obj = NcsPlant(sys,d,Td); 
%%
NCS = NcsStructure(ncsPlant_obj,'tsim',tsim); 
sim('C_sim')

%%
tau = NCS.tau_ca_node.tau';
time_new = [0:Td:1]'+tau(1:201);
[time_new,ind] = sort(time_new);
value = [1:201]';

figure(1)
clf; grid on; hold on
stairs(0:Td:1,1:201)
stairs(time_new,value(ind))
stairs(ramp.time,ramp.data)
xlim([0,0.3])