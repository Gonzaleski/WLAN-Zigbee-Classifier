% Define the root directory where training data is stored (relative to current folder)
trainDirRoot = fullfile(pwd, "../../data");

% Add functions folder and its subfolders to MATLAB path
addpath(genpath('../../functions'));

% Specify base network architecture for DeepLabv3+ (pretrained backbone)
baseNetwork = 'resnet18';

% Define the folder path containing images of size 256x256
folders = fullfile(trainDirRoot, '256x256');

% Set the input image size for the network
imageSize = [256 256];

% Create an imageDatastore to load all PNG images from the specified folder
imds = imageDatastore(folders, FileExtensions = ".png");

% Define the class names for semantic segmentation
classNames = ["Background", "WLAN", "Zigbee"];

% Number of classes (including background)
numClasses = length(classNames);

% Define pixel label IDs: map each class to a grayscale value between 0 and 255
pixelLabelID = floor((0:numClasses-1) / (numClasses-1) * 255);

% Create a pixelLabelDatastore to load labeled pixel masks (.hdf files) with specified classes and pixel IDs
pxdsTruthZigbeeWLAN = pixelLabelDatastore(folders, classNames, pixelLabelID, ...
                                  FileExtensions = ".hdf");

% Count the number of pixels per class across the dataset
tbl = countEachLabel(pxdsTruthZigbeeWLAN);

% Split data into training (80%), validation (10%), and test (10%) sets
[imdsTrain, pxdsTrain, imdsVal, pxdsVal, imdsTest, pxdsTest] = ...
  partitionData(imds, pxdsTruthZigbeeWLAN, [80 10 10]);

% Combine image and pixel label datastores for training, validation, and test sets
cdsTrain = combine(imdsTrain, pxdsTrain);
cdsVal = combine(imdsVal, pxdsVal);
cdsTest = combine(imdsTest, pxdsTest);

% Create DeepLabv3+ semantic segmentation network with specified input size and number of classes
layers = deeplabv3plus(imageSize, numClasses, baseNetwork);

% Calculate the frequency of each class appearing in the dataset
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
imageFreq(isnan(imageFreq)) = []; % Remove any NaN values

% Compute class weights inversely proportional to class frequency (to balance classes)
classWeights = median(imageFreq) ./ imageFreq;

% Normalize class weights to sum to 1 (add small epsilon to avoid division by zero)
classWeights = classWeights / (sum(classWeights) + eps(class(classWeights)));

% If number of computed weights is less than number of classes, pad with zeros
if length(classWeights) < numClasses
    classWeights = [classWeights; zeros(numClasses - length(classWeights), 1)];
end

% Define training mini-batch size
mbs = 40;

% Set training options for stochastic gradient descent with momentum (SGDM)
opts = trainingOptions("sgdm", ...
  MiniBatchSize = mbs, ...
  MaxEpochs = 15, ...
  LearnRateSchedule = "piecewise", ...
  InitialLearnRate = 0.02, ...
  LearnRateDropPeriod = 10, ...
  LearnRateDropFactor = 0.1, ...
  ValidationData = cdsVal, ...
  ValidationPatience = 5, ...
  Shuffle = "every-epoch", ...
  OutputNetwork = "best-validation-loss", ...
  Plots = 'training-progress');

% Train the semantic segmentation network using the combined training datastore,
% network layers, custom loss function (with class weights), and training options
[net, trainInfo] = trainnet(cdsTrain, layers, ...
    @(ypred, ytrue) lossFunction(ypred, ytrue, classWeights), opts);

% Save the trained network to the models folder with a timestamped filename
save(sprintf('../../models/myNet_%s_%s', baseNetwork, ...
    datetime('now', 'format', 'yyyy_MM_dd_HH_mm')), 'net');

% Also save a copy with fixed name for quick loading
save('../../models/trainedModel.mat', 'net');
