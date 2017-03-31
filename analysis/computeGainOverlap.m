function CV = computeGainOverlap( CV, higher ,x,y,sd)
%COMPUTELINEARWEIGHTS Linear weighting via lasso from lower to higher ROI
%
% INPUT
%   CV: Cross validation folds
%   lower: ROI to use for input
%   higher: ROI to use for output
%
% OUTPUT
%   CV.higher.lower.tSeries_forward: original forward pass
%   CV.higher.lower.tSeries_gain: gain using 5,5 1.1% max gain
%
%   Run the forward model using the computed
%   weights, and then repeat the forward model after applying a gain at
%   location x=5 y=5 degrees with gaussian gain max 1.1%, standard
%   deviation 3. 
%% Identify folds
folds_ = fields(CV);
folds = {};

for fi = 1:length(folds_)
    if ~isempty(strfind(folds_{fi},'fold'))
        folds{end+1} = folds_{fi};
    end
end

%% For each fold
for fi = 1:length(folds)
    CV.(folds{fi}) = computeFoldGain(CV.(folds{fi}),higher,x,y,sd);
end

function fold = computeFoldGain(fold,higher,x,y,sd)

hroi = fold.(higher);


%% Compute gain overlap using dist
% For each voxel in higher region compute the percentage of the gain region
% that it overlaps with, this should ultimately correlate with any effect
% of the gain (and allow estimates of how powerful the gain effects are)

overlap = zeros(1,size(hroi.train,1));
for vh = 1:length(overlap)
    % for now just compute as if everything were squares, even though
    % they're circles... just easier to deal with and it's approximately
    % correct anyways 
    vx = hroi.rfParams(vh,1);
    vy = hroi.rfParams(vh,2);
    vs = hroi.rfParams(vh,3);
    overlap(vh) = mvncdf([vx-vs vy-vs],[vx+vs vy+vs],[x y],[sd 0;0 sd]);
end
hroi.overlap = overlap;

%% Save and return

fold.(higher) = hroi;
