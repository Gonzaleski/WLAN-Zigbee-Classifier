trainDirRoot = fullfile(pwd,"../../data");
addpath(genpath('../../functions'));
baseNetwork = 'resnet18';
folders = fullfile(trainDirRoot,'256x256'); 
imageSize = [256 256];
imds = imageDatastore(folders,FileExtensions=".png");
classNames = ["Background", "WLAN", "Zigbee"];

numClasses = length(classNames);
pixelLabelID = floor((0:numClasses-1)/(numClasses-1)*255);
pxdsTruthZigbeeWLAN = pixelLabelDatastore(folders,classNames,pixelLabelID,...
                                  FileExtensions=".hdf");

tbl = countEachLabel(pxdsTruthZigbeeWLAN);

[imdsTrain,pxdsTrain,imdsVal,pxdsVal,imdsTest,pxdsTest] = ...
  partitionData(imds,pxdsTruthZigbeeWLAN,[80 10 10]);
cdsTrain = combine(imdsTrain,pxdsTrain);
cdsVal = combine(imdsVal,pxdsVal);
cdsTest = combine(imdsTest,pxdsTest);

layers = deeplabv3plus([256 256],numel(classNames),baseNetwork);

imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
imageFreq(isnan(imageFreq)) = [];
classWeights = median(imageFreq) ./ imageFreq;
classWeights = classWeights/(sum(classWeights)+eps(class(classWeights)));
if length(classWeights) < numClasses
    classWeights = [classWeights; zeros(numClasses - length(classWeights),1)];
end

mbs = 40;
opts = trainingOptions("sgdm",...
  MiniBatchSize = mbs,...
  MaxEpochs = 1, ... % Change to 20
  LearnRateSchedule = "piecewise",...
  InitialLearnRate = 0.02,...
  LearnRateDropPeriod = 10,...
  LearnRateDropFactor = 0.1,...
  ValidationData = cdsVal,...
  ValidationPatience = 5,...
  Shuffle="every-epoch",...
  OutputNetwork = "best-validation-loss",...
  Plots = 'training-progress');

[net,trainInfo] = trainnet(cdsTrain,layers, ...
    @(ypred,ytrue) lossFunction(ypred,ytrue,classWeights),opts);
save(sprintf('myNet_%s_%s',baseNetwork, ...
    datetime('now',format='yyyy_MM_dd_HH_mm')), 'net')

save('trainedModel.mat', 'net');