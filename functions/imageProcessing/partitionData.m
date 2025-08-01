function [imdsTrain, pxdsTrain, imdsVal, pxdsVal, imdsTest, pxdsTest] = ...
    partitionData(imds, pxds, parts)
% Partition image and pixel label datastores into training, validation,
% and test sets based on the provided percentages.
%
%   Copyright 2021-2023 The MathWorks, Inc.
%   Modified by Arad Soutehkeshan

% Validate 'parts' input is a 1-by-3 numeric vector
validateattributes(parts, {'numeric'}, {'size',[1 3]}, ...
  'specSensePartitionData', 'P', 3)

% Ensure that the three parts add up to 100
assert(sum(parts) == 100, 'Sum of parts must be 100')

% Set a fixed random seed for reproducibility
s = RandStream('mt19937ar', Seed=0); 

% Get total number of files
numFiles = numel(imds.Files);

% Randomly permute the indices
shuffledIndices = randperm(s, numFiles);

% Calculate how many samples go into training and validation sets
numTrain = floor(numFiles * parts(1) / 100);
numVal = floor(numFiles * parts(2) / 100);

% Partition image datastore into train, validation, and test sets
imdsTrain = subset(imds, shuffledIndices(1:numTrain));
imdsVal = subset(imds, shuffledIndices(numTrain + (1:numVal)));
imdsTest = subset(imds, shuffledIndices(numTrain + numVal + 1:end));

% Partition pixel label datastore correspondingly
pxdsTrain = subset(pxds, shuffledIndices(1:numTrain));
pxdsVal = subset(pxds, shuffledIndices(numTrain + (1:numVal)));
pxdsTest = subset(pxds, shuffledIndices(numTrain + numVal + 1:end));

end
