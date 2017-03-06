function w = prf_lasso(roi_data,timecourse)
%% PRF_LASSO
%
% Takes as input a matrix roi_data that is voxels * timecourses and a
% timecourse in a downstream region. Estimates a set of weights (ideally
% cross-validated) that reconstruct 

%% Simulate
% v2 = randn(1,50);
% 
% v1 = repmat(v2,5,1);
% v1 = [v1;randn(size(v1))];
% v1 = v1 + randn(size(v1))*1;
% 
% roi_data = v1;
% timecourse = v2;

%% Lasso
% Future to-do: cross-validate by doing the lasso individually predictive
% for each bar run, and then average the weight vectors

[b,stats] = lasso(roi_data',timecourse');
best = find(stats.Lambda==min(stats.Lambda),1);
w = b(:,best)';

%% Figure
% 
% h = figure; hold on
% plot(timecourse,'r');
% plot(w'*roi_data,'g');