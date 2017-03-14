%% getPRFparams.m
%
%
%    usage:  given a pRF analysis, gets the pRF parameters for a given ROI and loads tseries
%
%       by: akshay jagadeesh
%     date: 03/05/2017
function pRF = getpRFParams(saveToBox)

%% hardcoded inputs
pRFAnalysis = 'pRF.mat';
scanNum = 2;
pRF.roiNames = {'lV1', 'lV2', 'lV3', 'lV4', 'lV3a', 'lV3b', 'lV7', 'lMT', 'lLO1', 'lLO2'};

v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', scanNum);
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);
pRF.d = viewGet(v, 'd', scanNum);
pRF.concatInfo = viewGet(v, 'concatInfo', scanNum);
pRF.scanDims = viewGet(v, 'scanDims');
pRF.rfParams = pRF.d.params;
pRF.r2 = pRF.d.r.^2;

stimfile = viewGet(v, 'stimfile', scanNum);
pRF.stimulus = stimfile{1}{1}.stimulus;

rois = loadROITSeries(v, pRF.roiNames);

for i =1:length(pRF.roiNames)
  tSeries = percentTSeries(rois{i}.tSeries, 'detrend', 'Linear', 'spatialNormalization', 'Divide by mean', 'subtractMean', 'Yes', 'temporalNormalization', 'No');
  pRF.(pRF.roiNames{i}).scanCoords = rois{i}.scanCoords;
  pRF.(pRF.roiNames{i}).tSeries = tSeries;
end

if ~ieNotDefined('saveToBox')

  save('/Users/akshay/Box Sync/LINEAR_RF/pRFparams_concat.mat', 'pRF');
  disp('Saved pRF struct to Box folder');
end


%keyboard
