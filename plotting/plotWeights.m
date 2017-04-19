function plotWeights( fname, lroi, hroi )
%PLOTWEIGHTS Plot weights from lroi to hroi
%
% Figure 1: Weight consistency
%   Plot the correlation of weights across fodls
%
% Figure 2: Weight mapping
%   Load a params file and plot a figure showing the weighting of each lroi
%   voxel mapped onto each hroi voxel. Choose voxels that have 
%
%   Author: Dan Birman
%   Date: Mar 23, 2017

%% Load file
load(fname);

%% Identify folds
folds_ = fields(CV);
folds = {};

for fi = 1:length(folds_)
    if ~isempty(strfind(folds_{fi},'fold'))
        folds{end+1} = folds_{fi};
    end
end

%% Plot inter-series correlations
h = figure; hold on

cmap = brewermap(length(folds),'Dark2');
ps = zeros(size(folds));
for fi = 1:length(folds)
    fts = CV.(folds{fi}).(roi).train; % rotate to column-wise
    % compute correlations and plot
    for inner = 1:length(folds)
        if fi~=inner
            innerts = CV.(folds{inner}).(roi).train;
            
            % compare voxel-wise
            for vi = 1:size(fts,1)
                r = corr(fts(vi,:)',innerts(vi,:)');
                ps(fi) = plot(vi,r^2,'*','Color',cmap(fi,:));
            end
        end
    end
end

legend(ps,folds);

title('Inter-fold correlations');
ylabel('R^2');
xlabel('Voxel');

drawPublishAxis
