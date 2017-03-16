%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))

%% NEW CODE

CV = load(fullfile('~/Box Sync/LINEAR_RF/crossval.mat'));
CV = CV.cv;

CV = computeLinearWeights(CV,'v1','v2');