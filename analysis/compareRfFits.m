%% compareRfFits
%
%               by: akshay jagadeesh
%             date: 03/30/2017
%          purpose: Gets model response for held-out dataset using original parameters and the forward pass parameters.
%
%            input: 
%            usage: 
%                   load('~/Box Sync/LINEAR_RF/crossval_params.mat');
%                   CV = compareRfFits(CV, 'lV2', 'lV1');
%
%                   %If modelResponse is already computed in CV
%                   compareRfFits(CV,[],[],1);
%
function cv = compareRfFits(cv, lower, upper, plotFigs)

folds = fields(cv); folds = folds(2:end);

if ieNotDefined('plotFigs')
  plotFigs=0;
else
  plotFigs=1;
end

if plotFigs==0
  v = newView;
  v = viewSet(v, 'curGroup', 'Concatenation');
  v = viewSet(v, 'curScan', 2);
  v = loadAnalysis(v, 'pRFAnal/pRF.mat');
  concatInfo = viewGet(v, 'concatInfo');
  d = viewGet(v, 'd');
  analysisParams = viewGet(v, 'analysisParams');
  analysisParams.pRFFit.verbose = 0;

  v2 = loadROITSeries(v, upper, [],[],'straightXform=1', 'loadType=none');

  for i = 1:length(folds)

    paramsFromStim = cv.(folds{i}).(upper).rfParams;
    paramsForward = cv.(folds{i}).(upper).(lower).paramsForward;

    testTSeries = cv.(folds{i}).(upper).test;

    modelResp_fromstim = nan(size(testTSeries)); r2_fromstim = zeros(1,size(testTSeries,1));
    modelResp_forward = nan(size(testTSeries)); r2_forward = zeros(1,size(testTSeries,1));
    disp(sprintf('Fold %i - Computing %d model responses using both forward and fromstim parameters', i, size(testTSeries,1)));
    tic
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

    toc
    cv.(folds{i}).(upper).(lower).testModelRespForward = modelResp_forward;
    cv.(folds{i}).(upper).(lower).testModelRespFromStim = modelResp_fromstim;
    cv.(folds{i}).(upper).(lower).testR2Forward = r2_forward;
    cv.(folds{i}).(upper).(lower).testR2FromStim = r2_fromstim;
  end

else
  disp('Model response passed in. Skipping computing of model response');
  allR2_diff = [];
  allR2_forward = [];
  allR2_fromstim = [];
  for i = 1:length(folds)
    r2_forward = cv.(folds{i}).(upper).(lower).testR2Forward;
    r2_fromstim = cv.(folds{i}).(upper).(lower).testR2FromStim;

    r2_diff = r2_forward - r2_fromstim;

    allR2_diff = [allR2_diff; r2_diff];
    allR2_forward = [allR2_forward; r2_forward];
    allR2_fromstim = [allR2_fromstim; r2_fromstim];
  end

  figure;
  plot(nanmean(allR2_forward), nanmean(allR2_fromstim), '*');
  hold on; plot([0:.1:.8], [0:.1:.8], '-k');
  title(sprintf('Model Comparison: Forward (%s --> %s) vs From Stim', lower, upper));
  xlabel('Forward model cross-validated r^2');
  ylabel('From stimulus model cross-validated r^2');
  drawPublishAxis;
end
