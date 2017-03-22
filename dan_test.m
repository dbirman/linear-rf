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
% Initial:
%   plotCV - compares intra-fold timeseries, and fold vs. test timeseries
%   plotRF - draws original receptive fields
% Weights:
%   plotWeights - shows which RFs contribute to which voxel (somehow?)
% Forward:
%   plotForward
% Params:
%   drawRFchanges(preparams,postparams) - Draws RF shift arrows
% Model comparison:
%   R^2 plots?

%% Run Weights

CV = load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
CV = CV.cv;

CV = computeLinearWeights(CV,'v1','v2');


%% Run Forward Model
load(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'));
CV = computeForwardGain(CV,'v1','v2');
 