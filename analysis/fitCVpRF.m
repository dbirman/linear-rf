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
analysisParams.pRFFit.verbose=0;
numVoxels = size(cv.fold1.(upper).train,1);
lV2 = loadROITSeries(v,upper,[],[],'straightXform=1','loadType=none');

% Compute prefit and save it
disp('Computing prefit');
prefitParams = analysisParams.pRFFit; prefitParams.prefitOnly=1;
pre = pRFFit(v, [], lV2.scanCoords(1,1), lV2.scanCoords(2,1), lV2.scanCoords(3,1), 'tSeries', cv.(f{1}).(upper).(lower).tSeries_forward(2,:)',...
                'stim', d.stim, 'fitTypeParams', prefitParams, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);


for fi = 1:length(f)

  disp(sprintf('Fold %i of %i: Computing rfParams', fi, length(f)));

  % Get pregain and postgain time series
  tSeries_forward = cv.(f{fi}).(upper).(lower).tSeries_forward;
  tSeries_gain = cv.(f{fi}).(upper).(lower).tSeries_gain;

  % Get global prefit
  global gpRFFitTypeParams;
  prefit = gpRFFitTypeParams.prefit;

  % run pRFFit and generate RF params for the two time series
  pregainParams = nan(numVoxels,3);
  postgainParams = nan(numVoxels,3);
  tic
  parfor vi = 1:numVoxels
    disp(sprintf('Voxel %d of %d', vi, numVoxels));
    if ~any(isnan(tSeries_gain))
      x = lV2.scanCoords(1,vi); y = lV2.scanCoords(2,vi); z = lV2.scanCoords(3,vi);
      fit1 = pRFFit(v, [], x,y,z, 'tSeries', tSeries_forward(vi,:).', 'stim', d.stim, 'prefit', prefit,...
                  'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
      pregainParams(vi,:) = fit1.params;

      fit2 = pRFFit(v, [], x,y,z, 'tSeries', tSeries_gain(vi,:).', 'stim', d.stim, 'prefit', prefit,...
                  'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);
      postgainParams(vi,:) = fit2.params;
    else
      disp('Skipping voxel');
    end
  end
  toc

  cv.(f{fi}).(upper).(lower).paramsForward = pregainParams;
  cv.(f{fi}).(upper).(lower).paramsGain = postgainParams;
  cv.(f{fi}).(upper).scanCoords = lV2.scanCoords;
end

if ~ieNotDefined('saveParams')
  CV = cv;
  save('~/Box Sync/LINEAR_RF/crossval_params.mat', 'CV');
  disp('cv saved to crossval_params.mat');
end
