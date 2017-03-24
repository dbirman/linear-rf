%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))

%% Compute weights

load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
% CV = CV.cv;
CV = computeLinearWeights(CV,'v1','v2');
save(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'),'CV');

%% Compute forward pass

load(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'));
% CV = CV.cv;
CV = computeForwardGain(CV,'v1','v2');
save(fullfile('~/Box Sync/LINEAR_RF/crossval_forward.mat'),'CV');
