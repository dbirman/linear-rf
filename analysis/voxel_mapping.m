function include = voxel_mapping(pRF,roi_lower,roi_higher)
%% VOXEL_MAPPING
%
% Takes two ROIs and computes the mapping between them. For each voxel in
% the higher ROI it computes an include/exclude metric for all the voxels
% in the lower ROI based on whether their pRF will overlap. 

%% Organize data

roi_lower = pRF.(roi_lower);
roi_higher = pRF.(roi_higher);

%% Include is a matrix, higher_voxels * lower_voxels

include = zeros(size(roi_higher.tSeries,1),size(roi_lower.tSeries,1));

lower_params = pRF.rfParams(:,roi_lower.linearScanCoords);
for vh = 1:size(roi_higher.tSeries,1)
    % get the higher region voxel params
    higher_params = pRF.rfParams(:,roi_higher.linearScanCoords(vh));
    % find all lower region parameters that will overlap with this
    
    
    diffx = lower_params(1,:)-higher_params(1);
    diffy = lower_params(2,:)-higher_params(2);
    distances = hypot(diffx,diffy);
    sumsd = lower_params(3,:)+higher_params(3);
    
    % OPTION 1: STANDARD DEVIATIONS OVERLAP
%     include(vh,:) = distances < sumsd;

    % OPTION 2: V1 CENTER WITHIN 1 SD OF V2 CENTER
    include(vh,:) = distances < higher_params(3);
end

figure
hist(sum(include,2))
