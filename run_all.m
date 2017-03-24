%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))
cd ~/Box' Sync'/LINEAR_RF/

%% File structure
% crossval.mat - CV folds, original pRF and timeseries
% crossval_weights.mat - Linear weights calculated
% crossval_forward.mat - Forward pass calculated
% crossval_params.mat - pRF parameters for forward pass
% crossval_modelComparison.mat - R^2 computed on test timeseries

%% Plotting functions
% Initial:
%   plotCV - compares intra-fold timeseries, and fold vs. test timeseries
plotCV('~/Box Sync/LINEAR_RF/crossval.mat','v1');
%   plotRF - draws original receptive fields
% Weights:
%   plotWeights - shows which RFs contribute to which voxel (somehow?)
% Forward:
%   plotForward
% Params:
%   drawRFchanges(preparams,postparams) - Draws RF shift arrows
% Model comparison:
%   R^2 plots?

%% Split data up into 4 folds, run pRFFit on each fold to get params, and get the CV struct
rois = {'lV1', 'lV2'};
CV = crossValLinRF(rois);
save(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'), 'CV');

%% Run Weights
CV = load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
CV = CV.CV;

CV = computeLinearWeights(CV,'v1','v2');
save(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'),'CV');


%% Run Forward Model
load(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'));
CV = computeForwardGain(CV,'v1','v2');
save(fullfile('~/Box Sync/LINEAR_RF/crossval_forward.mat'),'CV');


%% Get pRF fit params for each of the folds after running forward model
CV = fitCVpRF(CV, 'lV1', 'lV2');
save(fullfile('~/Box Sync/LINEAR_RF/crossval_params.mat'), 'CV');
