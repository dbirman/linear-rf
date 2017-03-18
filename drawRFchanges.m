% drawRFchanges
%     
%    purpose: draws changes in receptive field
%
%      usage: drawRFchanges(pregainParams, postgainParams)
%             drawRFchanges()
%
function drawRFchanges(pregainParams, postgainParams)

if ieNotDefined('pregainParams')
  [pregainParams, postgainParams] = fitRFs(1);
end

% Draw Receptive Field center changes
figure;
x1 = pregainParams(:,1); x1 = x1(~isnan(x1));
y1 = pregainParams(:,2); y1 = y1(~isnan(y1));
x2 = postgainParams(:,1); x2 = x2(~isnan(x2));
y2 = postgainParams(:,2); y2 = y2(~isnan(y2));

quiver(x1,y1,x2-x1,y2-y1, 'LineWidth', 2, 'MaxHeadSize', 0.5); hold on; hline(0,'-k'); vline(0,'-k');
whitebg([1 1 1]);
plot(5,5,'*r', 'MarkerSize', 10);
xlim([-15 15]);
ylim([-10 10]);
title('Change in RF centers with 10% attentional gain');
xlabel('x position (degrees)'); ylabel('y position (degrees)');
drawPublishAxis

keyboard

% Plot change in RF width
figure;
rfWidth_pre = pregainParams(:,3);
rfWidth_pre = rfWidth_pre(~isnan(rfWidth_pre));
rfWidth_post = postgainParams(:,3);
rfWidth_post = rfWidth_post(~isnan(rfWidth_post));

x1 = 1:length(rfWidth_pre);

plot(x1', rfWidth_pre, '+b'); hold on;
plot(x1', rfWidth_post, '*g');
legend('pregain width', 'postgain width');
title('RF widths by voxel before and after gain');

figure;
bar([mean(rfWidth_pre) mean(rfWidth_post)]);
