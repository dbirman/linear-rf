% crossValLinRF.m
%
%      usage: Cross validates
%         by: akshay jagadeesh
%       date: 03/14/2017
%
function crossVal = crossValLinRF()

% inputs
scanNum = 2;
pRFAnalysis = 'pRF.mat';
%roiNames = {'lV1', 'lV2', 'lV3', 'lV4', 'lV3a', 'lV3b', 'lV7', 'lMT', 'lLO1', 'lLO2'};
roiNames = {'lV1', 'lV2'};

% init mlr and get variables
v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', scanNum);
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);

% get scan/analysis variables
analysisParams = viewGet(v, 'analysisparams');
d = viewGet(v, 'd');
concatInfo = viewGet(v, 'concatInfo');
scanDims = viewGet(v, 'scanDims');

% Get original un-averaged, un-concatenated scan numbers
ogn = viewGet(v, 'originalgroupname'); % first get the average group scan
osn = viewGet(v, 'originalscannum');
ogn2 = viewGet(v, 'originalgroupname', osn, ogn{1}); % Get the motioncomp scans
osn2 = viewGet(v, 'originalscannum', osn, ogn{1});
numScans = length(osn2);

keyboard
% Load time series data for each MotionComp scan for each ROI
scans = loadROITSeries(v, roiNames, osn2, ogn2{1},'straightXform=1'); % Length: numScans * numRois

% init crossVal struct
crossVal.numScans = numScans;
leftOut = [1 2; 3 4; 5 6; 7 8];
v1_size = size(scans{1}.tSeries);
v1Coords = scans{1}.scanCoords;
v2_size = size(scans{9}.tSeries);
v2Coords = scans{9}.scanCoords;

% First cross validate V1.
for fold = 1:size(leftOut,1)
  disp(sprintf('Fold %i of %i: Left Out Set = [%i, %i]', fold, size(leftOut,1), leftOut(fold,1), leftOut(fold,2)));
  foldStr = sprintf('fold%d',fold);
  crossVal.(foldStr).heldOut = leftOut(fold,:);
  train = zeros(v1_size); trainFilt = zeros(v1_size);
  test = zeros(v1_size); testFilt = zeros(v1_size);
  for scanIdx = 1:numScans
    thisScan = scans{scanIdx};
    if ~any(scanIdx==leftOut(fold,:))
      train = train + thisScan.tSeries;
    %  disp('train');
    else
      test = test + thisScan.tSeries;
    %  disp('test');
    end
  end

  train = train./6;
  test = test./2;

  % apply concat filtering to averages & left out
  for k = 1:v1_size(1)
    trainFilt(k,:) = applyConcatFiltering(train(k,:), concatInfo, 1);
    testFilt(k,:) = applyConcatFiltering(test(k,:), concatInfo, 1);
  end

  crossVal.(foldStr).v1_train = trainFilt;
  crossVal.(foldStr).v1_test = testFilt;

  allModelFits = nan(v1_size(1), 3);

  prefitParams = analysisParams.pRFFit;
  prefitParams.prefitOnly = 1;
  prefit = pRFFit(v, [], v1Coords(1,1), v1Coords(2,1), v1Coords(3,1), 'tSeries', trainFilt(1,:)', 'stim', d.stim,...
                  'fitTypeParams', prefitParams, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);

  global gpRFFitTypeParams;
  pre = gpRFFitTypeParams.prefit;
                  
  % Run pRFFit on trainFilt and get v1 RF params
  parfor i = 1:v1_size(1)
    x = v1Coords(1,i); y = v1Coords(2,i); z = v1Coords(3,i);
    modelFit = pRFFit(v, [], x,y,z, 'tSeries', trainFilt(i,:)', 'stim', d.stim,...
                      'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo,...
                      'prefit', pre, 'concatInfo', concatInfo);
    allModelFits(i,:) = modelFit.params;
    disp(sprintf('Completed fitting voxel %i of %i', i, v1_size(1)));
  end

  % Save in crossVal.(foldStr).v1_rfParams
  crossVal.(foldStr).v1.rfParams = allModelFits;

end


% Then do cross validating on V2
for fold = 1:size(leftOut,1)
  foldStr = sprintf('fold%d',fold);
  crossVal.(foldStr).heldOut = leftOut(fold,:);
  train = zeros(v2_size); trainFilt = zeros(v2_size);
  test = zeros(v2_size); testFilt = zeros(v2_size);
  for scanIdx = 9:numScans*2
    thisScan = scans{scanIdx};
    if ~any(scanIdx==leftOut(fold,:))
      train = train + thisScan.tSeries;
    else
      test = test + thisScan.tSeries;
    end
  end

  train = train./6;
  test = test./2;

  % apply concat filtering to averages & left out
  for k = 1:v2_size(1)
    trainFilt(k,:) = applyConcatFiltering(train(k,:), concatInfo, 1);
    testFilt(k,:) = applyConcatFiltering(test(k,:), concatInfo, 1);
  end

  crossVal.(foldStr).v2.train = trainFilt;
  crossVal.(foldStr).v2.test = testFilt;

  allModelFits = nan(v2_size(1), 3);

  prefitParams = analysisParams.pRFFit;
  prefitParams.prefitOnly = 1;
  prefit = pRFFit(v, [], v2Coords(1,1), v2Coords(2,1), v2Coords(3,1), 'tSeries', trainFilt(1,:)', 'stim', d.stim,...
                  'fitTypeParams', prefitParams, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);

  global gpRFFitTypeParams;
  pre = gpRFFitTypeParams.prefit;
                  
  % Run pRFFit on trainFilt and get v2 RF params
  parfor i = 1:v2_size(1)
    x = v2Coords(1,i); y = v2Coords(2,i); z = v2Coords(3,i);
    modelFit = pRFFit(v, [], x,y,z, 'tSeries', trainFilt(i,:)', 'stim', d.stim,...
                      'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo,...
                      'prefit', pre, 'concatInfo', concatInfo);
    allModelFits(i,:) = modelFit.params;
    disp(sprintf('Completed fitting voxel %i of %i', i, v2_size(1)));
  end

  % Save in crossVal.(foldStr).v2_rfParams
  crossVal.(foldStr).v2.rfParams = allModelFits;

end



keyboard



function tSeries = applyConcatFiltering(tSeries,concatInfo,runnum)

tSeries = tSeries(:);

% apply detrending
if ~isfield(concatInfo,'filterType') || ~isempty(findstr('detrend',lower(concatInfo.filterType)))
  tSeries = eventRelatedDetrend(tSeries);
end

% apply hipass filter
if isfield(concatInfo,'hipassfilter') && ~isempty(concatInfo.hipassfilter{runnum})
  if ~isequal(length(tSeries),length(concatInfo.hipassfilter{runnum}))
    disp(sprintf('(applyConcatFiltering) Mismatch dimensions of tSeries (length: %i) and concat filter (length: %i)',length(tSeries),length(concatInfo.hipassfilter{runnum})));
  else
    tSeries = real(ifft(fft(tSeries) .* repmat(concatInfo.hipassfilter{runnum}', 1, size(tSeries,2)) ));
  end
end

% project out the mean vector
if isfield(concatInfo,'projection') && ~isempty(concatInfo.projection{runnum})
  projectionWeight = concatInfo.projection{runnum}.sourceMeanVector * tSeries;
  tSeries = tSeries - concatInfo.projection{runnum}.sourceMeanVector'*projectionWeight;
end

% now remove mean
tSeries = tSeries-repmat(mean(tSeries,1),size(tSeries,1),1);
tSeries = tSeries(:)';
