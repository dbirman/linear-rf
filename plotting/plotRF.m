function plotRF( fname, roi )
%PLOTCV Plot original receptive fields
%
% Load a crossvalidation file and plot two figures. First, plot a figure
%  showing the inter-series correlation across folds. Second, plot a figure
%  showing the train/test correlation across folds.
%
%   Author: Dan Birman
%   Date: Mar 23, 2017

%% Load file
load(fname);

%% Pull ROI parameters
params = CV.
