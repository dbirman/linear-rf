%% getPRFparams.m
%
%
%    usage:  given a pRF analysis, gets the pRF parameters for a given ROI and loads tseries
%
%       by: akshay jagadeesh
%     date: 03/05/2017
%    input: 

function pRF = getpRFParams(pRFAnalysis, roiName, scanNum)

%% hardcoded inputs
pRFAnalysis = 'pRF.mat';
scanNum = 1;
pRF.roiNames = {'lV1', 'lV2', 'lV3', 'lV4', 'lV3a', 'lV3b', 'lV7', 'lMT', 'lLO1', 'lLO2'};

v = newView;
v = viewSet(v, 'curGroup', 'Averages');
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);
pRF.d = viewGet(v, 'd', scanNum);
pRF.concatInfo = viewGet(v, 'concatInfo', scanNum);
pRF.scanDims = viewGet(v, 'scanDims');

pRF.rfParams = pRF.d.params;

rois = loadROITSeries(v, pRF.roiNames);

for i =1:length(pRF.roiNames)
  pRF.(pRF.roiNames{i}).scanCoords = rois{i}.scanCoords;
  pRF.(pRF.roiNames{i}).tSeries = rois{i}.tSeries;
end

%keyboard
