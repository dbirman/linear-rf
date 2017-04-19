%% Shared run code
% Authors: Dan Birman, Akshay Jagadeesh
% Date: Spring, 2017

%% Paths
%cd ~/proj/gru
%startup
%cd ~/proj/linear-rf
%addpath(genpath(pwd))
%cd ~/Box' Sync'/LINEAR_RF/

%% File structure
% crossval.mat - CV folds, original pRF and timeseries
% crossval_weights.mat - Linear weights calculated
% crossval_forward.mat - Forward pass calculated
% crossval_params.mat - pRF parameters for forward pass
% crossval_modelComparison.mat - R^2 computed on test timeseries

%% Plotting functions
% Initial:
%   plotCV - compares intra-fold timeseries, and fold vs. test timeseries

plotCV('~/Box Sync/LINEAR_RF/crossval.mat','lMT');
%   plotRF - draws original receptive fields
% Weights:
%   plotWeights - shows which RFs contribute to which voxel (somehow?)
% Forward:
%   plotForward
% Params:
%   drawRFchanges(preparams,postparams) - Draws RF shift arrows
%   R^2 plots?

%% Split data up into 4 folds, run pRFFit on each fold to get params, and get the CV struct
% rois = {'lV1', 'lV2', 'lV3', 'lMT'};
% CV = crossValLinRF(rois);
% save(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'), 'CV');

%% Set opts
% from the standard macaque model it should be:
% v1* -> v2
% v1*, v2*, -> v3
% v1, v2, v3 -> v3a
% v1*, v2*, v3, v3a -> MT
% v1, v2, v3, v3a -> V4

% but we'll just do the starred ones (and not combining ROIs like for V3,
% that's for a future version...)
opts = {{'lV1','lV2'},{'lV1','lV3'},{'lV2','lV3'},{'lV1','lMT'},{'lV2','lMT'}};
%% Run Weights
% load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
% 
% for oi = 1:length(opts)
%     opt = opts{oi};
%     low = opt{1};
%     high = opt{2};
%     CV = computeLinearWeights(CV,low,high);
%     CV = addMask(CV,low,high);
% end
% 
% save(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'),'CV');


%% Run Forward Model
% load(fullfile('~/Box Sync/LINEAR_RF/crossval_weights.mat'));
% for oi = 1:length(opts)
%     opt = opts{oi};
%     low = opt{1};
%     high = opt{2};
%     CV = computeForwardGain(CV,low,high,0.1,5,3,3);
%     CV = computeGainOverlap(CV,high,5,3,3);
% end
% save(fullfile('~/Box Sync/LINEAR_RF/crossval_forward.mat'),'CV');


%% Get pRF fit params for each of the folds after running forward model
% load(fullfile('~/Box Sync/LINEAR_RF/crossval_forward.mat'));
% for oi = 1:length(opts)
%   opt = opts{oi};
%   low = opt{1};
%   high = opt{2};
%   disp(sprintf('Computing pRF for low %s and high %s', low, high));
%   CV = fitCVpRF(CV, low, high);
%   save(fullfile('~/Box Sync/LINEAR_RF/crossval_params.mat'), 'CV');
% end

%% Display pRF changes

for oi = 1:length(opts)
    plotRFChanges('~/Box Sync/LINEAR_RF/crossval_params.mat',opts{oi}{1},opts{oi}{2});
end

%% Compare RF Fits
load(fullfile('~/Box Sync/LINEAR_RF/crossval_params.mat'));
for oi = 1:length(opts)
  opt = opts{oi};
  low = opt{1};
  high = opt{2};
  disp(sprintf('Comparing RF Fits for low %s and high %s', low, high));
  CV = compareRfFits(CV, low, high);
  save(fullfile('~/Box Sync/LINEAR_RF/crossval_modelComparison.mat'), 'CV');
end

%% Display RF Fits
load(fullfile('~/Box Sync/LINEAR_RF/crossval_modelComparison.mat'), 'CV');
for oi = 1:length(opts)
  opt = opts{oi};
  low = opt{1};
  high = opt{2};
  compareRfFits(CV, low, high, 1);
end
