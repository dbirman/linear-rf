%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))

%% Load params file
load(fullfile(datafolder_lrf,'pRFparams.mat'));
pRF.ROIs = pRF.roiNames;

%% Fix structures
for ri = 1:length(pRF.ROIs)
    roi = pRF.ROIs{ri};
    pRF.(roi).linearScanCoords = sub2ind(pRF.scanDims,pRF.(roi).scanCoords(1,:),pRF.(roi).scanCoords(2,:),pRF.(roi).scanCoords(3,:));
    for ls = 1:length(pRF.(roi).linearScanCoords)
        pRF.(roi).linearScanCoords(ls) = find(pRF.d.linearCoords==pRF.(roi).linearScanCoords(ls),1);
    end
end

%% Compute voxel mapping
mappings = {{'rV1','rV2d'}};

% For each mapping, compute the RF mapping
map = cell(size(mappings));
for mi = 1:length(mappings)
    cmap = mappings{mi};
    roi_lower = cmap{1};
    roi_higher = cmap{2};
    
    map{mi} = voxel_mapping(pRF,roi_lower,roi_higher);
end

%% Use voxel mapping to constrain lasso

for mi = 1:length(mappings)
    cmap = map{mi}; % mapping: incl/excl voxels
    lower = pRF.(mappings{mi}{1});
    higher = pRF.(mappings{mi}{2});
    for vi = 1:size(higher.tSeries,2)
        % for each higher voxel, compute lasso weights
        
        roi_data = lower.tSeries(logical(cmap(vi,:)),:);
        timecourse = higher.tSeries(vi,:);
        if ~isempty(roi_data) && ~any(isnan((timecourse)))
        
            w = prf_lasso(roi_data,timecourse);
            higher.weights{vi} = w;
        end
    end
    pRf.(mappings{mi}{2}).weights = weights;
end