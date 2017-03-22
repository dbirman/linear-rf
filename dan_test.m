%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))

%% File structure
% crossval.mat - CV folds, original pRF and timeseries
% crossval_weights.mat - Linear weights calculated
% crossval_forward.mat - Forward pass calculated
% crossval_params.mat - pRF parameters for forward pass
% crossval_modelComparison.mat - R^2 computed on test timeseries

%% Plotting functions

%% NEW CODE

CV = load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
CV = CV.cv;

CV = computeLinearWeights(CV,'v1','v2');


%%
load(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'));
CV = computeForwardGain(CV,'v1','v2');
 