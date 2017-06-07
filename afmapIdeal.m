function afmapIdeal(numTrials)

%%
if ieNotDefined('numTrials')
  numTrials = 100;
end

% Set variables
afRadius = 5;
threshold = 130; %mean brightness detection threshold 
contrast = 0.20;

% Screen variables
width = 1920; height = 1200;
imageWidth = 49.4123006277084; imageHeight = 37.5831787272705;
pixelSize = 8;
gaussX = 5; gaussY = 5; gaussSD = 2/(2*sqrt(2*log(2)));

% Setup Gaussian
[X,Y] = meshgrid((0.5:(width/pixelSize-0.5))-width/(pixelSize*2),(0.5:(height/pixelSize-0.5))-height/(pixelSize*2));
ppdw = width/imageWidth;
ppdh = height/imageHeight;
stimX = X*pixelSize./ppdw;
stimY = Y*pixelSize./ppdh;
afdist = hypot(stimX-gaussX, stimY-gaussY);

% Calculate Gaussian
stimdist = normpdf(afdist,0,gaussSD)';
stimdist = uint8(stimdist ./ max(stimdist(:)) * 255);
stimdist = repmat(reshape(stimdist,[1 size(stimdist)]),3,1,1);

% Calculate attention field
af = afdist<5;

% 50% probability of stimulus being present on each trial
stimPresent = rand(1,numTrials)>0.5;

% Response array
idealResp = zeros(1,numTrials);

% Keep track of noise
noiseMat = nan(numTrials, width/pixelSize, height/pixelSize);

%figure;
for ti = 1:numTrials
  wn = repmat(randi(256,1,width/pixelSize,height/pixelSize,'uint8')-1,3,1,1);

  noiseMat(ti, :,:) = squeeze(wn(1,:,:));
  
  % Add gaussian stimulus on random subset of trials
  if stimPresent(ti) == 1
    wn = min(wn+contrast*stimdist, 255);
  end

  im = squeeze(wn(1,:,:));

  % Check mean brightness within a certain radius from center of attention field
  if mean(im(af')) > threshold
    idealResp(ti) = 1;
  end
  
  % Staircase stimulus contrast
  %if yes, response=1; else, response = 0; end
  %stim.staircase = doStaircase('update', stimulus.staircase, response);
  %[task.thistrial.contrast, stimulus.staircase] = doStaircase('testValue',stimulus.staircase);

end

% Calculate percentage correct
numCorrect = sum(idealResp == stimPresent);
disp(sprintf('Percentage correct: %02.02f%%', 100*numCorrect/numTrials));

%
idealResp = logical(idealResp);
yesResp = noiseMat(idealResp,:,:);
noResp = noiseMat(~idealResp,:,:);
figure;
subplot(3,1,1);
imagesc(squeeze(mean(yesResp))'); colormap('gray'); title(sprintf('Yes Responses (%d trials)', numTrials));
subplot(3,1,2);
imagesc(squeeze(mean(noResp))'); colormap('gray'); title(sprintf('No Responses (%d trials)', numTrials));
subplot(3,1,3);
imagesc((squeeze(mean(yesResp))-squeeze(mean(noResp)))'); colormap('gray'); title(sprintf('Yes minus No (%d trials)', numTrials));

