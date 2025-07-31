classes = ["Background", "WLAN", "Zigbee"];
labelIDs = [0, 127, 255];  % Assuming 0-127-255 as before

% Set paths
trainDir = fullfile(pwd, 'GeneratedData');
dataFolder = fullfile(trainDir, '256x256');

% Image datastore
imds = imageDatastore(dataFolder, ...
    'IncludeSubfolders', true, ...
    'FileExtensions', '.png', ...
    'LabelSource', 'foldernames');

% Pixel label datastore
pxds = pixelLabelDatastore(dataFolder, classes, labelIDs, ...
    'IncludeSubfolders', true, ...
    'FileExtensions', '.hdf');

% Combine into a pixelLabelImageDatastore
pximds = combine(imds, pxds);

% Split into 80/20
numFiles = numel(imds.Files);  % or pxds.Files, should be the same

shuffledIndices = randperm(numFiles);

numTrain = round(0.8 * numFiles);

trainIdx = shuffledIndices(1:numTrain);
valIdx = shuffledIndices(numTrain+1:end);

pximdsTrain = subset(pximds, trainIdx);
pximdsVal = subset(pximds, valIdx);

% Network definition (DeepLabv3+ with ResNet-18)
imageSize = [256 256];
numClasses = numel(classes);
lgraph = deeplabv3plusLayers(imageSize, numClasses, 'resnet18');

% Training options
options = trainingOptions('adam', ...
    'InitialLearnRate',1e-3, ...
    'MaxEpochs',15, ...
    'MiniBatchSize',16, ...
    'Plots','training-progress', ...
    'Shuffle','every-epoch', ...
    'ValidationData', pximdsVal, ...
    'ValidationFrequency', 50, ...
    'VerboseFrequency',10);

% Train network
net = trainNetwork(pximdsTrain, lgraph, options);

save('trainedModel.mat', 'net');
