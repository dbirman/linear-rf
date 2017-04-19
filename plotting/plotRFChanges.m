% drawRFchanges
%     
%    purpose: draws changes in receptive field
%
%      usage: drawRFchanges(paramsForward, paramsGain)
%             drawRFchanges()
%
function h = plotRFChanges(file, lroi, hroi)

%% Load File
load(file);

%% Identify folds

folds_ = fields(CV);
folds = {};

for fi = 1:length(folds_)
    if ~isempty(strfind(folds_{fi},'fold'))
        folds{end+1} = folds_{fi};
    end
end
%% Average parameters across folds
paramsForward = zeros(length(folds),size(CV.fold1.(hroi).(lroi).paramsForward,1),size(CV.fold1.(hroi).(lroi).paramsForward,2));
paramsGain = paramsForward;
for fi = 1:length(folds)
    paramsForward(fi,:,:) = CV.(folds{fi}).(hroi).(lroi).paramsForward;
    paramsGain(fi,:,:) = CV.(folds{fi}).(hroi).(lroi).paramsGain;
end

%% Average
paramsForward = squeeze(mean(bootci(1000,@nanmean,paramsForward)));
paramsGain = squeeze(mean(bootci(1000,@nanmean,paramsGain)));

%% Plot

if ieNotDefined('paramsForward')
  [paramsForward, paramsGain] = fitRFs(1);
end

% Draw Receptive Field center changes
h = figure;
x1 = paramsForward(:,1); x1 = x1(~isnan(x1));
y1 = paramsForward(:,2); y1 = y1(~isnan(y1));
x2 = paramsGain(:,1); x2 = x2(~isnan(x2));
y2 = paramsGain(:,2); y2 = y2(~isnan(y2));

quiver(x1,y1,x2-x1,y2-y1 ,'-k','LineWidth', 2, 'MaxHeadSize', 0.5); hold on;
hline(0,'--k'); 
vline(0,'--k');
whitebg([1 1 1]);
plot(5,5,'*r', 'MarkerSize', 10);
xlim([-15 15]);
ylim([-10 10]);
title('Change in RF centers with 10% attentional gain');
xlabel('x position (degrees)'); ylabel('y position (degrees)');
drawPublishAxis

% Plot change in RF width
figure;
rfWidth_pre = paramsForward(:,3);
rfWidth_pre = rfWidth_pre(~isnan(rfWidth_pre));
rfWidth_post = paramsGain(:,3);
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
