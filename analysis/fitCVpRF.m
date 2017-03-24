% fitCVpRF.m
%
%      Given an ROI and two timeseries (pregain and postagin), fits receptive fields
%        and returns the fit parameters to all voxels in that ROI for each response timeseries.
%
%
%
function cv = fitCVpRF(cv, lower, upper, saveParams)

% inputs
pRFAnalysis = 'pRF.mat';
scanNum = 2;
%upper = 'v2'; lower='v1';

% Load the forward pass computed pRFs
if ieNotDefined('cv');
  crossval = load('~/Box Sync/LINEAR_RF/crossval_forward.mat');
  cv = crossval.CV;
  upper = 'lV2'; lower='lV1';
end

% get the struct subfields
f = fields(cv); f = f(2:end);

% init mrTools and load analysis
v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', scanNum);
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);
% get scan analysis variables
concatInfo = viewGet(v, 'concatInfo', scanNum);
d = viewGet(v, 'd', scanNum);
analysisParams = viewGet(v, 'analysisParams');
numVoxels = size(cv.fold1.(upper).train,1);
lV2 = loadROITSeries(v,'lV2',[],[],'straightXform=1','loadType=none');

% Compute prefit and save it
prefitParams = analysisParams.pRFFit; prefitParams.prefitOnly=1;
pre = pRFFit(v, [], lV2.scanCoords(1,1), lV2.scanCoords(2,1), lV2.scanCoords(3,1), 'tSeries', cv.(f{1}).(upper).(lower).tSeries_forward(2,:)',...
                'stim', d.stim, 'fitTypeParams', prefitParams, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);

keyboard


for i = 1:length(f)

  disp(sprintf('Fold %i of %i: Computing rfParams', i, length(f)));

  % Get pregain and postgain time series
  tSeries_forward = cv.(f{i}).(upper).(lower).tSeries_forward;
  tSeries_gain = cv.(f{i}).(upper).(lower).tSeries_gain;

  % Get global prefit
  global gpRFFitTypeParams;
  prefit = gpRFFitTypeParams.prefit;

  % run pRFFit and generate RF params for the two time series
  pregainParams = nan(numVoxels,3);
  postgainParams = nan(numVoxels,3);
  parfor i = 1:numVoxels
    disp(sprintf('Voxel %d of %d', i, numVoxels));
    if ~any(isnan(tSeries_gain))
      x = lV2.scanCoords(1,i); y = lV2.scanCoords(2,i); z = lV2.scanCoords(3,i);
      fit1 = pRFFit(v, [], x,y,z, 'tSeries', tSeries_forward(i,:).', 'stim', d.stim, 'prefit', prefit,...
                  'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
      pregainParams(i,:) = fit1.params;

      fit2 = pRFFit(v, [], x,y,z, 'tSeries', tSeries_gain(i,:).', 'stim', d.stim, 'prefit', prefit,...
                  'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
      postgainParams(i,:) = fit2.params;
    else
      disp('Skipping voxel');
    end
  end

  cv.(f{i}).(upper).(lower).paramsForward = pregainParams;
  cv.(f{i}).(upper).(lower).paramsGain = postgainParams;
  cv.(f{i}).(upper).scanCoords = lV2.scanCoords;
end

if ~ieNotDefined('saveParams')
  CV = cv;
  save('~/Box Sync/LINEAR_RF/crossval_params.mat', 'CV');
  disp('cv saved to crossval_forwardParams.mat');
end
