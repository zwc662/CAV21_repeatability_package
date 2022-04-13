% /* An example of verifying a continuous nonlinear NNCS */
% / FFNN controller

clc
clear

weights = load('docking_tanh64x64_weights.mat');
bias = load('docking_tanh64x64_biases.mat');
n = length(fieldnames(weights));
Layers = [];
for i=1:n - 1
    cur_layer = strcat('layer', int2str(i));
    L = LayerS(weights.(cur_layer)', bias.(cur_layer)', 'tansig');
    Layers = [Layers L];
end
cur_layer = strcat('layer', int2str(n));
L = LayerS(weights.(cur_layer)', bias.(cur_layer)', 'tansig');
Layers = [Layers L];
controller = FFNNS(Layers); 
% /* car model
Tr = 0.005; % reachability time step for the plant
Tc = 1; % control period of the plant
% output matrix
C = [0 0 0 0 1 0;1 0 0 -1 0 0; 0 1 0 0 -1 0]; % output matrix
num_states = 6;
num_inputs = 1;
car = NonLinearODE(num_states, num_inputs, @car_dynamics, Tr, Tc, C);

% /* system
ncs = NonlinearNNCS(controller, car); 

% /* ranges of initial set of states of the plant
lb = [90; 32; 0; 10; 30; 0];
ub = [91; 32.05; 0; 11; 30.05; 0];

% /* reachability parameters
reachPRM.init_set = Star(lb, ub);
reachPRM.ref_input = [30; 1.4];
reachPRM.numSteps = 120;
reachPRM.reachMethod = 'approx-star';
reachPRM.numCores = 1;

U = 0; % don't check safety for intermediate flowpipes

[safe, counterExamples, verifyTime] = ncs.verify(reachPRM, U);

%% compute reachability safety property at the end
map_mat = [1 0 0 0 0 0; 0 1 0 0 0 0; 0 0 1 0 0 0; 0 0 0 1 0 0; 0 0 0 0 1 0; 0 0 0 0 0 1];
map_vec = [];
all_flowpipes = ncs.getOutputReachSet(map_mat, map_vec);
last_flowpipe = Star.get_hypercube_hull(all_flowpipes{length(all_flowpipes)})

if last_flowpipe.ub(5) >= last_flowpipe.lb(6)
    safe = 'UNSAFE';
end

safe
verifyTime

%% save flowpipes
save('nnv_flowpipes.mat', 'ncs');
