%%%
%
%
function drawRFchanges(pregainParams, postgainParams)

if ieNotDefined('pregainParams')
  [pregainParams, postgainParams] = fitRFs(1);
end

figure;
whitebg([1 1 1]);
x1 = pregainParams(:,1); y1 = pregainParams(:,2);
x2 = postgainParams(:,1); y2 = postgainParams(:,2);

quiver(x1,y1,x2-x1,y2-y1, 'LineWidth', 1); hold on; hline(0,'-k'); vline(0,'-k');
whitebg([1 1 1]);
plot(5,5,'*r', 'MarkerSize', 10);
xlim([-25 25]);
ylim([-15 15]);
title('Change in RF centers with 10% attentional gain');
xlabel('x position (degrees)'); ylabel('y position (degrees)');
%drawPublishAxis
%
%
