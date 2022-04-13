% /* An example of verifying a continuous nonlinear NNCS */
% / FFNN controller

clc
clear

weights = load('weights.mat');
bias = load('biases.mat');
n = length(fieldnames(weights));
Layers = [];
for i=1:n - 1
    cur_layer = strcat('layer', int2str(i));
    L = LayerS(weights.(cur_layer)', bias.(cur_layer)', 'tansig');
    Layers = [Layers L];
end
cur_layer = strcat('layer', int2str(n));
L = LayerS(weights.(cur_layer)', bias.(cur_layer)', 'purelin');
Layers = [Layers L];
controller = FFNNS(Layers); 
% /* car model
Tr = 0.001; % reachability time step for the plant
Tc = 0.1; % control period of the plant
% output matrix
C = [1 0 0 0 0 0; 0 0 1 0]; % output matrix
num_states = 6;
num_inputs = 6;
agent = NonLinearODE(num_states, num_inputs, @dynamics, Tr, Tc, C);

% /* system
ncs = NonlinearNNCS(controller, agent); 

% /* ranges of initial set of states of the plant
lb =  [24; 24; -0.13776233054248638; -0.13776233054248638; 0.1948253562373095; 0.2697150717707441]
ub =  [26; 26; -0.13776233054248638; -0.13776233054248638; 0.1948253562373095; 0.27552466108497276]

% /* reachability parameters
reachPRM.init_set = Star(lb, ub);
reachPRM.ref_input = [30; 1.4];
reachPRM.numSteps = 50;
reachPRM.reachMethod = 'approx-star';
reachPRM.numCores = 1;

U = 0; % don't check safety for intermediate flowpipes

[safe, counterExamples, verifyTime] = ncs.verify(reachPRM, U);

%% compute reachability safety property at the end
map_mat = [0 1 0 0 0 0; 0 0 0 0 1 0];
map_vec = [];
all_flowpipes = ncs.getOutputReachSet(map_mat, map_vec);
last_flowpipe = Star.get_hypercube_hull(all_flowpipes{length(all_flowpipes)});

x2_ub = 22.87;
x2_lb = 22.81;
x5_ub = 30.02;
x5_lb = 29.88;

if last_flowpipe.lb(1) >= x2_ub || last_flowpipe.lb(2) >= x5_ub || last_flowpipe.ub(1) <= x2_lb || last_flowpipe.ub(2) <= x5_lb
    safe = 'UNSAFE';
elseif last_flowpipe.ub(1) >= x2_ub || last_flowpipe.ub(2) >= x5_ub || last_flowpipe.lb(1) <= x2_lb || last_flowpipe.lb(2) <= x5_lb
    safe = 'UNKNOWN';
end

safe
verifyTime

%% save flowpipes
save('nnv_flowpipes.mat', 'ncs');