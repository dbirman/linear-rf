function CV = computeForwardGain( CV, lower, higher )
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
    CV.(folds{fi}) = computeFoldGain(CV.(folds{fi}),lower,higher);
end

function fold = computeFoldGain(fold,lower,higher)

lroi = fold.(lower);
hroi = fold.(higher);

%% Forward pass

tweights = hroi.(lower).weights;
tweights(isnan(tweights)) = 0;
hroi.(lower).tSeries_forward = tweights*lroi.train;

%% Apply gain

% attention gain parameters
x = 5;
y = 5;
sd = 3;

dx = abs(x-lroi.rfParams(:,1));
dy = abs(y-lroi.rfParams(:,2));
dist = hypot(dx,dy);
% warning: this normalizes to a maximum 10% gain
gain = 1 + normpdf(dist,0,sd) * 0.1 / normpdf(0,0,sd);

lower_train_gain = repmat(gain,1,size(lroi.train,2)).*lroi.train;

% Re-run forward pass with gain
hroi.(lower).tSeries_gain = tweights*lower_train_gain;

%% Save and return

fold.(higher) = hroi;