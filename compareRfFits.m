%% compareRfFits
%
% Gets model response for held-out dataset using original parameters and the forward pass parameters.
%
function cv = compareRfFits(cv, skip)


roi = 'v2';
lower = 'v1';

folds = fields(cv); folds = folds(2:end);

if ieNotDefined('skip')
v = newView;
v = viewSet(v, 'curGroup', 'Concatenation');
v = viewSet(v, 'curScan', 2);
v = loadAnalysis(v, 'pRFAnal/pRF.mat');
concatInfo = viewGet(v, 'concatInfo');
d = viewGet(v, 'd');
analysisParams = viewGet(v, 'analysisParams');

v2 = loadROITSeries(v, 'lV2', [],[],'straightXform=1', 'loadType=none');

for i = 1:length(folds)

  paramsFromStim = cv.(folds{i}).(roi).rfParams;
  paramsForward = cv.(folds{i}).(roi).(lower).paramsForward;

  testTSeries = cv.(folds{i}).(roi).test;

  modelResp_fromstim = nan(size(testTSeries)); r2_fromstim = zeros(1,size(testTSeries,1));
  modelResp_forward = nan(size(testTSeries)); r2_forward = zeros(1,size(testTSeries,1));
  disp(sprintf('Fold %i - Computing %d model responses using both forward and fromstim parameters', i, size(testTSeries,1)));
  parfor vox = 1:size(testTSeries,1)

    x = v2.scanCoords(1,i); y = v2.scanCoords(2,i); z = v2.scanCoords(3,i);
    fit = pRFFit(v, [], x,y,z, 'tSeries', testTSeries(vox,:).', 'stim', d.stim, 'getModelResponse=1', 'params', paramsFromStim(vox,:),...
                 'concatInfo', concatInfo, 'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo);

    modelResp_fromstim(vox,:) = fit.modelResponse';
    r2_fromstim(vox) = corr(fit.modelResponse, fit.tSeries)^2;


    fit2 = pRFFit(v, [], x,y,z, 'tSeries', testTSeries(vox,:).', 'stim', d.stim, 'getModelResponse=1', 'params', paramsForward(vox,:),...
                  'concatInfo', concatInfo, 'fitTypeParams', analysisParams.pRFFit, 'paramsInfo', d.paramsInfo);

    modelResp_forward(vox,:) = fit2.modelResponse';
    r2_forward(vox) = corr(fit2.modelResponse, fit2.tSeries)^2;

  end

  cv.(folds{i}).(roi).testModelRespForward = modelResp_forward;
  cv.(folds{i}).(roi).testModelRespFromStim = modelResp_fromstim;
  cv.(folds{i}).(roi).testR2Forward = r2_forward;
  cv.(folds{i}).(roi).testR2FromStim = r2_fromstim;
end

end

allR2 = [];
for i = 1:length(folds)
  r2_forward = cv.(folds{i}).(roi).testR2Forward;
  r2_fromstim = cv.(folds{i}).(roi).testR2FromStim;

  r2_diff = r2_forward - r2_fromstim;

  allR2 = [allR2; r2_diff];

end
meanR2 = mean(allR2,1);
stdR2 = std(allR2,1);
figure; errorbar(meanR2, 1.96*stdR2/2, 'o')
title('r2_{forward}-r2_{fromStim} averaged across folds');
xlabel('Voxel'); ylabel('Mean difference (forward - fromStim) across folds');
drawPublishAxis
keyboard
