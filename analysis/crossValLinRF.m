% crossValLinRF.m
%
%      usage: Cross validates
%         by: akshay jagadeesh
%       date: 03/14/2017
%
%      input:
%           - roiNames: e.g. {'lV1', 'lV2', 'lV3'}
%           - saveCV (optional) - set to 1 if you want to save struct to Box
function crossVal = crossValLinRF(roiNames, saveCV)

% inputs
scanNum = 2;
pRFAnalysis = 'pRF.mat';
if ieNotDefined('roiNames')
  roiNames = {'lV1', 'lV2'};
end

% init mlr and get variables
v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', scanNum);
v = loadAnalysis(v, ['pRFAnal/' pRFAnalysis]);

% get scan/analysis variables
analysisParams = viewGet(v, 'analysisparams');
analysisParams.pRFFit.verbose=0;
d = viewGet(v, 'd');
concatInfo = viewGet(v, 'concatInfo');
scanDims = viewGet(v, 'scanDims');

% Get original un-averaged, un-concatenated scan numbers
ogn = viewGet(v, 'originalgroupname'); % first get the average group scan
osn = viewGet(v, 'originalscannum');
ogn2 = viewGet(v, 'originalgroupname', osn, ogn{1}); % Get the motioncomp scans
osn2 = viewGet(v, 'originalscannum', osn, ogn{1});
numScans = length(osn2);

% Load time series data for each MotionComp scan for each ROI
scans = loadROITSeries(v, roiNames, osn2, ogn2{1});

% init crossVal struct
crossVal.numScans = numScans;
leftOut = [1 2; 3 4; 5 6; 7 8];
%leftOut = nchoosek(1:8,2);

for roiIdx = 1:length(roiNames)
  disp(sprintf('(crossValLinRF) Computing cross-validated params for ROI: %s', roiNames{roiIdx}));
  firstScan = numScans*(roiIdx-1)+1;
  roi_size = size(scans{firstScan}.tSeries);
  roiCoords = scans{firstScan}.scanCoords;
  for fold = 1:size(leftOut,1)
    disp(sprintf('(crossValLinRF) Fold %i of %i: Left Out Set = [%i, %i]', fold, size(leftOut,1), leftOut(fold,1), leftOut(fold,2)));
    foldStr = sprintf('fold%d',fold);
    crossVal.(foldStr).heldOut = leftOut(fold,:);
    train = zeros(roi_size); trainFilt = zeros(roi_size);
    test = zeros(roi_size); testFilt = zeros(roi_size);
    for scanIdx = 1:numScans
      roiScanIdx = scanIdx + numScans*(roiIdx-1);
      thisScan = scans{roiScanIdx};
      if ~any(scanIdx==leftOut(fold,:))
        train = train + thisScan.tSeries;
      else
        test = test + thisScan.tSeries;
      end
    end

    % Average - divide by number of runs after summing
    train = train./6;
    test = test./2;

    % Convert to percent signal change
    train = percentTSeries(train, 'detrend', 'Linear', 'spatialNormalization', 'Divide by mean', 'subtractMean', 'Yes', 'temporalNormalization', 'No');
    test = percentTSeries(test, 'detrend', 'Linear', 'spatialNormalization', 'Divide by mean', 'subtractMean', 'Yes', 'temporalNormalization', 'No');

    % apply concat filtering in order to subtract the mean.
    for k = 1:roi_size(1)
      trainFilt(k,:) = applyConcatFiltering(train(k,:), concatInfo, 1);
      testFilt(k,:) = applyConcatFiltering(test(k,:), concatInfo, 1);
    end

    crossVal.(foldStr).(roiNames{roiIdx}).train = trainFilt;
    crossVal.(foldStr).(roiNames{roiIdx}).test = testFilt;

    allModelFits = nan(roi_size(1), 3);

    prefitParams = analysisParams.pRFFit;
    prefitParams.prefitOnly = 1;
    prefit = pRFFit(v, [], roiCoords(1,1), roiCoords(2,1), roiCoords(3,1), 'tSeries', trainFilt(1,:)', 'stim', d.stim,...
                    'fitTypeParams', prefitParams, 'paramsInfo', d.paramsInfo, 'concatInfo', concatInfo);

    global gpRFFitTypeParams;
    pre = gpRFFitTypeParams.prefit;
                    
    % Run pRFFit on trainFilt and get ROI RF params
    disp(sprintf('(crossValLinRF) Running pRFFit on %d voxels', roi_size(1))); tic;
    parfor i = 1:roi_size(1)
      x = roiCoords(1,i); y = roiCoords(2,i); z = roiCoords(3,i);
      modelFit = pRFFit(v, [], x,y,z, 'tSeries', trainFilt(i,:)', 'stim', d.stim,...
                        'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo,...
                        'prefit', pre, 'concatInfo', concatInfo);
      allModelFits(i,:) = modelFit.params;
    end
    toc;

    % Save in crossVal.(foldStr).(roiName).rfParams
    crossVal.(foldStr).(roiNames{roiIdx}).rfParams = allModelFits;
  end
end

if ~ieNotDefined('saveCV')
  CV = crossVal;
  save('~/Box Sync/LINEAR_RF/crossval.mat', 'CV');
  disp('(crossValLinRF) Saved crossval.mat to Box folder.');
end


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
