% Add folders containing helper functions and models to MATLAB path
addpath(genpath('../../functions'));
addpath(genpath('../../models'));

% Parameters for spectrogram computation and segmentation
Nfft = 4096;              % FFT size used in spectrogram calculation
overlap = 10;             % Overlap between FFT windows
classNames = ["Background", "WLAN", "Zigbee"]; % Classes for segmentation
imageSize = [256 256];    % Size of the spectrogram image input to the network
numSubFrames = 40;        
frameDuration = numSubFrames * 1e-3; % Frame duration in seconds
sampleRate = 20e6;        % Sample rate of the received signal in Hz

% Load the pre-trained semantic segmentation network
load('trainedModel.mat', 'net');

% Initialize accumulators for segmentation scores
meanAllScores = zeros([imageSize numel(classNames)]);
segResults = zeros([imageSize 10]); % Store segmentation results for 10 frames

try
    for frameCnt = 1:10
        % Acquire received waveform from SDR (rx is SDR System object)
        rxWave = rx();
        
        % Generate spectrogram image from the received waveform
        rxSpectrogram = spectrogramImage(rxWave, Nfft, sampleRate, imageSize);

        % Run semantic segmentation on the spectrogram image
        [segResults(:,:,frameCnt), scores, allScores] = semanticseg(rxSpectrogram, net);

        % Update running mean of all scores over frames for stable prediction
        meanAllScores = (meanAllScores * (frameCnt - 1) + allScores) / frameCnt;
    end
    % Release the SDR hardware resource after processing
    release(rx)
catch ME
    % Ensure SDR resource is released on error and rethrow the error
    release(rx)
    rethrow(ME)
end

% Determine predicted labels by selecting class with max mean score at each pixel
[~, predictedLabels] = max(meanAllScores, [], 3);

% Display segmentation results in a figure
figure
displayResults(rxSpectrogram, [], predictedLabels, classNames, ...
    sampleRate, rx.CenterFrequency, frameDuration)

% Display identified signal frequency bands in a separate figure
figure
freqBand = displayIdentifiedSignals(rxSpectrogram, predictedLabels, ...
    classNames, sampleRate, rx.CenterFrequency, frameDuration);
