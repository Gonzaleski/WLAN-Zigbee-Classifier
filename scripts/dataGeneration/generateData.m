% Add the '../../functions' folder and all its subfolders to the MATLAB path
addpath(genpath('../../functions'));

% Number of spectrogram frames (samples) to generate
numFrames = 1000;

% Define the semantic classes for segmentation
classNames = ["Background", "WLAN", "Zigbee"];

% Set the size of the output spectrogram images (height x width)
imageSize = [256 256];

% Directory where generated training data will be saved
trainDir = '../../data';

% Number of subframes (signal duration parameter)
numSF = 10;

% Output sampling frequency for generated signals (in Hz)
outFs = 23e6;

% Flag indicating whether to save additional channel metadata information
saveChannelInfo = false;

% Call the data generator function to create combined WLAN and Zigbee training data
WLANZigbeeTrainingDataGenerator(numFrames, classNames, imageSize, trainDir, numSF, outFs, saveChannelInfo);
