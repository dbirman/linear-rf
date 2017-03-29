function plotCV( fname, roi )
%PLOTCV Plot cross-validation fold information
%
% Load a crossvalidation file and plot two figures. First, plot a figure
%  showing the inter-series correlation across folds. Second, plot a figure
%  showing the train/test correlation across folds.
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
