function CV = addMask( CV, lower, higher )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

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
    CV.(folds{fi}) = addMaskHelper(CV.(folds{fi}),lower,higher);
end

function fold = addMaskHelper(fold,lower,higher)

fold.(higher).(lower).mask = any(fold.(higher).(lower).weights,2);
