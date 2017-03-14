%%%
%
%
function drawRFchanges(pregainParams, postgainParams)

figure;
vectorDifference = [0 0];
distFromGain = zeros(2,1);
count = 0;
for i = 1:size(pregainParams,1)
  if ~any(isnan(pregainParams(i,:))) && abs(pregainParams(i,1))<30 && abs(pregainParams(i,2))<30 && abs(postgainParams(i,1))<30 && abs(postgainParams(i,2))<30
    vectorDifference = vectorDifference + [postgainParams(i,1) - pregainParams(i,1), postgainParams(i,2) - pregainParams(i,2)];
    plot(pregainParams(i,1), pregainParams(i,2), '*b'); hold on;
    plot(postgainParams(i,1), postgainParams(i,2), '*g'); hold on;
    plot([pregainParams(i,1); postgainParams(i,1)], [pregainParams(i,2); postgainParams(i,2)], '-k');

    distFromGain(1) = distFromGain(1) + pdist([pregainParams(i,1:2); 5 5]);
    distFromGain(2) = distFromGain(2) + pdist([postgainParams(i,1:2); 5 5]);
    count = count +1;
  end
end
hline(0,':'); vline(0,':');
%plot([0; vectorDifference(1)], [0; vectorDifference(2)], '-');

% calculate mean difference from (5,5) --> attentional gain center point
meanDistFromGain = distFromGain / count;

keyboard
