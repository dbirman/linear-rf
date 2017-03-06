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
        coord = find(pRF.d.linearCoords==pRF.(roi).linearScanCoords(ls),1);
        if ~isempty(coord)
            pRF.(roi).linearScanCoords(ls) = coord;
        else
            pRF.(roi).linearScanCoords(ls) = 0;
        end
    end
    % remove voxels that we couldn't find coordinates for (and
    % therefore no parameters are available)
    idxs = logical(pRF.(roi).linearScanCoords>0);
    pRF.(roi).scanCoords = pRF.(roi).scanCoords(:,idxs);
    pRF.(roi).tSeries = pRF.(roi).tSeries(idxs,:);
    pRF.(roi).linearScanCoords = pRF.(roi).linearScanCoords(idxs);
    
    pRF.(roi).r2 = pRF.r2(pRF.(roi).linearScanCoords);
    % remove voxels that have a total shit r2 
    cutoff = quantile(pRF.(roi).r2,.1);
    idxs = logical(pRF.(roi).r2>cutoff);
    pRF.(roi).scanCoords = pRF.(roi).scanCoords(:,idxs);
    pRF.(roi).tSeries = pRF.(roi).tSeries(idxs,:);
    pRF.(roi).linearScanCoords = pRF.(roi).linearScanCoords(idxs);
end

%% Compute maps of visual field coverage
for ri = 1:length(pRF.ROIs)
    h = figure; hold on
    
    croi = pRF.(pRF.ROIs{ri});
    croiparams = pRF.rfParams(:,croi.linearScanCoords);
    
    croiparams = croiparams(:,croiparams(3,:)>eps);    
    axis equal
    axis([-40 40 -20 20]);
    set(gca,'Units','Inches');
    set(gca,'Position',[1 1 5 2.5]);
    markerWidth = diff(xlim)*axpos(3); % Calculate Marker width in points
    scatter(croiparams(1,:),croiparams(2,:),(2*72*5/80*croiparams(3,:)).^2,'ok');
    title(pRF.ROIs{ri});
    xlabel('X (degs)');
    ylabel('Y (degs)');
    drawPublishAxis
    
    savepdf(h,fullfile(datafolder_lrf,sprintf('%s_coverage.pdf',pRF.ROIs{ri})));
end

%% Compute voxel mapping
mappings = {{'lV1','lV2'}};

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
    disppercent(-1/size(higher.tSeries,2));
    for vi = 1:size(higher.tSeries,2)
        % for each higher voxel, compute lasso weights
        roi_data = lower.tSeries(logical(cmap(vi,:)),:);
        timecourse = higher.tSeries(vi,:);
        if ~isempty(roi_data) && ~any(isnan((timecourse)))
        
            w = prf_lasso(roi_data,timecourse);
            higher.weights{vi} = w;
        end
        disppercent(vi/size(higher.tSeries,2));
    end
    disppercent(inf);
    pRF.(mappings{mi}{2}).weights = weights;
end

%% Draw a figure taking a random v2 voxel and showing its underlying weights