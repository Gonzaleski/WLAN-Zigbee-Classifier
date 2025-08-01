addpath(genpath('../../functions'));
Nfft = 4096;
overlap = 10;
classNames = ["Background", "WLAN", "Zigbee"];
imageSize = [256 256];
numSubFrames = 40;
frameDuration = numSubFrames*1e-3; 
sampleRate = 20e6;  % Hz

load('trainedModel.mat', 'net');

meanAllScores = zeros([imageSize numel(classNames)]);
segResults = zeros([imageSize 10]);

try
    for frameCnt=1:10
        rxWave = rx();
        rxSpectrogram = spectrogramImage(rxWave, ...
            Nfft, sampleRate, imageSize);

        [segResults(:,:,frameCnt),scores,allScores] = semanticseg(rxSpectrogram, net);
        meanAllScores = (meanAllScores*(frameCnt-1) + allScores) / frameCnt;
    end
    release(rx)
catch ME
    release(rx)
    rethrow(ME)
end

[~,predictedLabels] = max(meanAllScores,[],3);

figure
displayResults(rxSpectrogram, [], predictedLabels, classNames, ...
    sampleRate, rx.CenterFrequency, frameDuration)

figure
freqBand = displayIdentifiedSignals(rxSpectrogram,predictedLabels, ...
    classNames, sampleRate, rx.CenterFrequency, frameDuration);
