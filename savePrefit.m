% savePrefit.m
%
%     computes the prefits and saves it so that we don't have to run it everytime
%
%     usage: 
%        prefit = savePrefit(tSeries);
%        prefit = savePrefit([], pathToPrefit);
%
%     Saves m*n*d*t array containing possible time series for all m x n positions in a grid and d different rf widths
%     Then, finds the one with highest correlation to each voxel time series and uses that to estimate voxel's RF Params

function prefit = savePrefit(tSeries, prefitPath)

if ieNotDefined('prefitPath')
% Get stimulus image
scanNum = 1;
v = newView;
v = viewSet(v, 'curGroup', 'Averages');
v = loadAnalysis(v, 'pRFAnal/pRF.mat');
stimfile = viewGet(v, 'stimfile', scanNum);
stimulus = stimfile{1}.stimulus;
volTrigRatio = viewGet(v, 'auxParam', 'volTrigRatio', scanNum);
stim = pRFGetStimImageFromStimfile(stimfile{1}, 'volTrigRatio', volTrigRatio);
stimWidth = max(stim.x(:)) - min(stim.x(:));
stimHeight = max(stim.y(:)) - min(stim.y(:));

% Compute m*n grid of RF centers
[prefitx prefity prefitrfHalfWidth] = ndgrid(-0.4:0.025:0.4,-0.4:0.025:0.4,[0.0125 0.025 0.05 0.1 0.25 0.5 0.75]);

% Convert prefit 
prefit.x = prefitx(:)*stimWidth;
prefit.y = prefity(:)*stimHeight;
prefit.rfHalfWidth = prefitrfHalfWidth*max(stimWidth, stimHeight);
prefit.n = length(prefitx(:));
allModelResponse = nan(prefit.n,length(stim.t)); 

disp(sprintf('Computing %i prefit model responses', prefit.n));
parfor i = 1:prefit.n
  [modelResponse rfModel] = getModelResidual(prefit.x(i), prefit.y(i), prefit.rfHalfWidth(i), stim);
  allModelResidual(i,:) = (modelResponse-mean(modelResponse))./sqrt(sum(modelResponse.^2))';
end
prefit.modelResponse = allModelResidual;

% Find correlation between voxel model response and time series
disp(sprintf('Calculating correlation between time series and prefit RFs'));
bestfitParams = nan(size(tSeries, 1), 4);
for i = 1:size(tSeries,1)
  ts = tSeries(i,:);
  i_tSeries = (ts-mean(ts))/sqrt(sum(ts.^2));
  r = prefit.modelResponse*i_tSeries'; % take inner product to determine correlation
  [maxr bestModel] = max(r); % 
  bestFitParams(i,:) = [prefit.x(bestModel),prefit.y(bestModel),prefit.rfHalfWidth(bestModel), maxr];
end
prefit.bestFitParams = bestFitParams;

%save('~/Box Sync/LINEAR_RF/prefit.mat', 'prefit');
keyboard
else
  prefit = load(prefitPath);
  prefit = prefit.prefit;

  figure;
  plot(prefit.bestFitParams(:,1), prefit.bestFitParams(:,2), '*')

end



%%%% < end of main> %%%%

function [rfModel modelResponse] = getModelResidual(x, y, rfWidth, stim)

hrf = getCanonicalHRF();

rfModel = exp(-(((stim.x - x).^2) + ((stim.y - y).^2))/(2*(rfWidth^2)));
rfModel = convolveModelWithStimulus(rfModel, stim.im);
rfHRFmodel = convolveModelResponseWithHRF(rfModel, hrf);
modelResponse = percentTSeries(rfHRFmodel, 'detrend', 'Linear', 'spatialNormalization', 'Divide by mean', 'subtractMean', 'Yes', 'temporalNormalization', 'No');


function hrf = getCanonicalHRF()
offset = 0;
timelag = 1;
tau = 0.6;
exponent = 6;
sampleRate = 0.5;
amplitude = 1;
hrf.time = 0:sampleRate:25;

exponent = round(exponent);
gammafun = (((hrf.time - timelag)/tau).^(exponent-1).*exp(-(hrf.time-timelag)/tau))./(tau*factorial(exponent-1));
gammafun(find((hrf.time-timelag) <0)) = 0;

if (max(gammafun)-min(gammafun))~=0
  gammafun = (gammafun-min(gammafun)) ./ (max(gammafun)-min(gammafun));
end
gammafun = (amplitude*gammafun+offset);

hrf.hrf = gammafun;
hrf.hrf = hrf.hrf / max(hrf.hrf);


function modelResponse = convolveModelWithStimulus(rfModel, stim)
nStimFrames = size(stim, 3);
modelResponse = zeros(1,nStimFrames);
for frameNum = 1:nStimFrames
  modelResponse(frameNum) = sum(sum(rfModel.*stim(:,:,frameNum)));
end

function modelTimecourse = convolveModelResponseWithHRF(modelTimecourse,hrf)
n = length(modelTimecourse);
modelTimecourse = conv(modelTimecourse,hrf.hrf);
modelTimecourse = modelTimecourse(1:n);


