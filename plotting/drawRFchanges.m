% drawRFchanges
%     
%         by: akshay jagadeesh
%       date: 03/30/2017
%    purpose: draws changes in receptive field
%
%     inputs:
%             - fold : struct (from crossval_params.mat) containing fit params
%             - upper : Higher level ROI for which forward pass was computed, e.g. 'lV2'
%             - lower : Lower level ROI from which forward pass was computed, e.g. 'lV1'
%
%      usage: 
%             CV =  load('~/Box Sync/LINEAR_RF/crossval_params.mat');
%             drawRFchanges(CV.fold1, 'lV2', 'lV1');
%
%             drawRFchanges() % defaults to fold1, 'lV2', 'lV1'
%
function drawRFchanges(fold, lower, upper)

if ieNotDefined('fold')
  load('~/Box Sync/LINEAR_RF/crossval_params.mat');
  fold = CV.fold1;
  upper = 'lV2';
  lower = 'lV1';
end

pregainParams = fold.(upper).(lower).paramsForward;
postgainParams = fold.(upper).(lower).paramsGain;

% Draw Receptive Field center changes
figure;
x1 = pregainParams(:,1); x1 = x1(~isnan(x1));
y1 = pregainParams(:,2); y1 = y1(~isnan(y1));
x2 = postgainParams(:,1); x2 = x2(~isnan(x2));
y2 = postgainParams(:,2); y2 = y2(~isnan(y2));

quiver(x1,y1,x2-x1,y2-y1 ,'-k','LineWidth', 2, 'MaxHeadSize', 0.5); hold on;
hline(0,'--k'); 
vline(0,'--k');
whitebg([1 1 1]);
plot(5,5,'*r', 'MarkerSize', 10);
axis([-10 10 -5 10]);
title(sprintf('Change in %s RF centers with 10%% attentional gain in %s', upper, lower));
xlabel('x position (degrees)'); ylabel('y position (degrees)');
drawPublishAxis

% Plot change in RF width
figure;
rfWidth_pre = pregainParams(:,3);
rfWidth_pre = rfWidth_pre(~isnan(rfWidth_pre));
rfWidth_post = postgainParams(:,3);
rfWidth_post = rfWidth_post(~isnan(rfWidth_post));

% x1 = 1:length(rfWidth_pre);
hold on
plot(rfWidth_pre,rfWidth_post,'*k');
plot([0 20],[0 20],'--r');
axis([0 20 0 20]);
xlabel('Pre width');
ylabel('Post width');
% plot(x1', rfWidth_pre, '+b'); hold on;
% plot(x1', rfWidth_post, '*g');
% legend('pregain width', 'postgain width');
title('RF widths by voxel before and after gain');
drawPublishAxis;

% figure;
% bar([mean(rfWidth_pre) mean(rfWidth_post)]);
