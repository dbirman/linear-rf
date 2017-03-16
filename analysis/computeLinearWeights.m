function CV = computeLinearWeights( CV, lower, higher )
%COMPUTELINEARWEIGHTS Linear weighting via lasso from lower to higher ROI
%
% INPUT
%   CV: Cross validation folds
%   lower: ROI to use for input
%   higher: ROI to use for output
%
% OUTPUT
%   CV.higher.lower.mapping: which voxels were included in the model
%   CV.higher.lower.weights: duh
%   CV.higher.lower.tSeries_forward: original forward pass
%   CV.higher.lower.tSeries_gain: gain using 5,5 1.1% max gain
%
%   Computes a set of linear weights from voxel in a lower region to voxels
%   in a higher region. Weights are constrained to be sparse by limiting
%   them to only voxels with overlapping FWHM (2.355*sd). This still allows
%   quite large numbers of voxels to contribute, so we further regularize
%   by using an elastic net regression to estimate the contribution of the
%   lower voxels to the higher ROI. 
%
%   In a second pass we then run the forward model using the computed
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
    CV.(folds{fi}) = computeFoldWeights(CV.(folds{fi}),lower,higher);
end

function fold = computeFoldWeights(fold,lower,higher)
%% Compute the mapping
lroi = fold.(lower);
hroi = fold.(higher);

% For testing
% lroi.train = lroi.train(1:50,:);
% lroi.rfParams = lroi.rfParams(1:50,:);
% hroi.train = hroi.train(1:50,:);
% hroi.rfParams = hroi.rfParams(1:50,:);

hroi.(lower) = struct; % we'll store everything here
hroi.(lower).mapping = computeMapping(lroi,hroi);

% Plot if necessary:
% hist(sum(hroi.v1.mapping,2),50);

%% Compute the weights

hroi.(lower).weights = computeWeights(lroi,hroi,hroi.(lower).mapping);

% Plot if necessary
% h = imagesc(hroi.(lower).weights);
% colormap(cool)
% set(h,'AlphaData',~isnan(hroi.(lower).weights));
% colorbar
% title('Voxel weights computed by regularized regression');
% xlabel('Lower ROI voxel')
% ylabel('Higher ROI voxel')
% set(gca,'XTick',[],'YTick',[]);
% drawPublishAxis;

%% Forward pass

hroi.(lower).tSeries_forward = hroi.(lower).weights*lroi.train;

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
hroi.(lower).tSeries_gain = hroi.(lower).weights*lower_train_gain;

%% Save and return

fold.(higher) = hroi;

function weights = computeWeights(lroi,hroi,map)
%%
weights = nan(size(hroi.train,1),size(lroi.train,1));
disppercent(-1/size(hroi.train,1));
for vh = 1:size(hroi.train,1)
    cmap = logical(map(vh,:));
    ltrain = lroi.train(cmap,:);
    ctrain = hroi.train(vh,:);
    if ~isempty(ltrain)
        [b,stats] = lasso(ltrain',ctrain');
        best = find(stats.Lambda==min(stats.Lambda),1);
        w = b(:,best)';
        weights(vh,cmap) = w;
    end
    disppercent(vh/size(hroi.train,1));
end
disppercent(inf);

function mapping = computeMapping(lroi,hroi)
%%
mapping = zeros(size(hroi.train,1),size(lroi.train,1));
for vh = 1:size(hroi.train,1)
    diffx = lroi.rfParams(:,1)-hroi.rfParams(vh,1);
    diffy = lroi.rfParams(:,2)-hroi.rfParams(vh,2);
    distances = hypot(diffx,diffy);
    mapping(vh,:) = distances < (2.355/2*hroi.rfParams(vh,3));
end