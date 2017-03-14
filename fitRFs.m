%%
%
%
%
function [pregainParams, postgainParams] = fitRFs()

% Load the forward pass computed pRFs
pRF = load('~/Box Sync/LINEAR_RF/pRFparams_forward.mat');
pRF = pRF.pRF;
lV2 = pRF.lV2;


%
pRFAnalysis = 'pRF.mat';
scanNum = 2;
v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', scanNum);
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);
concatInfo = viewGet(v, 'concatInfo', scanNum);
d = viewGet(v, 'd', scanNum);
analysisParams = viewGet(v, 'analysisParams');
analysisParams.pRFFit.algorithm = 'nelder-mead';
numVoxels = size(lV2.tSeries,1);

% Get global prefit
global gpRFFitTypeParams;
prefit = gpRFFitTypeParams.prefit;

% run pRFFit and generate RF params for the two time series
pregainParams = nan(numVoxels,3);
postgainParams = nan(numVoxels,3);
parfor i = 1:numVoxels
  disp(sprintf('Voxel %d of %d', i, numVoxels));
  if any(lV2.tSeries_gain(i,:)~=0)
    x = lV2.scanCoords(1,i); y = lV2.scanCoords(2,i); z = lV2.scanCoords(3,i);
    fit1 = pRFFit(v, [], x,y,z, 'tSeries', lV2.tSeries(i,:).', 'stim', d.stim, 'prefit', prefit,...
                'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
    pregainParams(i,:) = fit1.params;
  
    fit2 = pRFFit(v, [], x,y,z, 'tSeries', lV2.tSeries_gain(i,:).', 'stim', d.stim, 'prefit', prefit,...
                'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
    postgainParams(i,:) = fit2.params;
  else
    disp('Skipping voxel');
  end
end

keyboard


