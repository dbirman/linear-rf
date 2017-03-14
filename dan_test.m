%% Paths
cd ~/proj/gru
startup
cd ~/proj/linear-rf
addpath(genpath(pwd))

%% To-do list
% Attention simulation (add attention and compute new timeseries via the
% calculated weights)

% pRF fit test (check that the pRF fits from the linear weighted
% reconstructions match the originals)

% pRF attention simulation (check what effect attention has on higher order
% receptive fields)

%% Load params file
load(fullfile(datafolder_lrf,'pRFparams_concat.mat'));
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
    axpos = get(gca,'Position');
    scatter(croiparams(1,:),croiparams(2,:),(2*72*axpos(3)/80*croiparams(3,:)).^2,'ok');
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

%% Test voxel mapping

for mi = 1:length(mappings)
    cmap = map{mi};
    
    % Get a random higher voxel, and then plot all it's lower voxels
    for vh = 1%:size(cmap,1)
        
    end
end

%% Use voxel mapping to constrain lasso

% figure
for mi = 1:length(mappings)
    cmap = map{mi}; % mapping: incl/excl voxels
    lower = pRF.(mappings{mi}{1});
    higher = pRF.(mappings{mi}{2});
    disppercent(-1/size(higher.tSeries,2));
    highers.weights = cell(1,size(higher.tSeries,1));
    voxels = cell(1,size(higher.tSeries,1));
    for vi = 1:size(higher.tSeries,1)
        % for each higher voxel, compute lasso weights
        roi_data = lower.tSeries(logical(cmap(vi,:)),:);
        timecourse = higher.tSeries(vi,:);
        if ~isempty(roi_data) && ~any(isnan((timecourse)))
        
            w = prf_lasso(roi_data,timecourse);
            higher.weights{vi} = w;
            voxels{vi} = find(cmap(vi,:));
            % test figure
%             clf; hold on
%             plot(timecourse,'b');
%             plot(w*roi_data,'r');
%             pause(0.001);
        end
        disppercent(vi/size(higher.tSeries,2));
    end
    disppercent(inf);
    pRF.(mappings{mi}{2}).weights = higher.weights;
    pRF.(mappings{mi}{2}).lower_voxels = voxels;
    pRF.(mappings{mi}{2}).mapping = cmap;
end

%% Save file
fname = fullfile(datafolder_lrf,'pRFparams_map.mat');
save(fname,'pRF');
%% Load file
fname = fullfile(datafolder_lrf,'pRFparams_map.mat');
load(fname);

%% Draw a figure taking a random v2 voxel and showing its underlying weights

%% Check that prefit refits match existing pRF 

%% Compute forward attention model
lower = pRF.lV1;
higher = pRF.lV2;

gauss.x = 5;
gauss.y = 5;
gauss.sd = 3;

gain_param = 1; % stronger = more powerful signal

% compute the gain model
lower.gain = ones(size(lower.linearScanCoords));

for vi = 1:size(lower.tSeries,1)
    dx = abs(gauss.x-pRF.rfParams(1,lower.linearScanCoords(vi)));
    dy = abs(gauss.y-pRF.rfParams(2,lower.linearScanCoords(vi)));
    dist = hypot(dx,dy);
    lower.gain(vi) = lower.gain(vi) + normpdf(dist,0,gauss.sd) * gain_param;
end

% compute the gain tSeries
lower.tSeries_gain = lower.tSeries .* repmat(lower.gain',1,size(lower.tSeries,2));

higher.tSeries_gain = zeros(size(higher.tSeries));
for vi = 1:size(higher.tSeries,1)
    % V1 tSeries for this voxel
    orig_tSeries = higher.tSeries(vi,:);
    % which voxels in V1 to use
    map = find(higher.mapping(vi,:));
    if ~isempty(map)
        higher.tSeries_gain(vi,:) = higher.weights{vi}*lower.tSeries_gain(map,:);
    end
end

pRF.lV1 = lower;
pRF.lV2 = higher;

%% Save forward
fname = fullfile(datafolder_lrf,'pRFparams_forward.mat');
save(fname,'pRF');
%% Fit pRFs 