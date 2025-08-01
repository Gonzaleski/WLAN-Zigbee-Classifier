function WLANZigbeeTrainingDataGenerator(numFrames, classNames, imageSize, trainDir, numSF, outFs, saveChannelInfo)
% Generates training data with Zigbee, WLAN signals and their combinations.
%
% Inputs:
%   numFrames       - Number of frames to generate
%   classNames      - Cell array of class names (e.g. {'Background','WLAN','Zigbee'})
%   imageSize       - [Height Width] of output spectrogram image
%   trainDir        - Directory to save training data
%   numSF           - Number of subframes (signal duration related)
%   outFs           - Output sampling frequency
%   saveChannelInfo - Boolean to save channel metadata files
%
%   Copyright 2025 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

addpath(genpath('..'));

% Create directory structure
for idx=1:size(imageSize,1)
    imgSize = imageSize(idx,:);
    dirName = fullfile(trainDir, sprintf('%dx%d', imgSize(1), imgSize(2)));
    if ~exist(dirName,'dir')
        mkdir(dirName)
        combinedDir = fullfile(dirName, 'Zigbee_WLAN');
        mkdir(combinedDir)
    end
end

maxFrameNum = 2;

% Zigbee Parameters
samplesPerChip = 22;
ZigbeeChBW = 2;

% WLAN Parameters
wlanChBW = 20;

% Common Parameters
maxTimeShift = numSF; % Time shift in milliseconds

% Channel Parameters
SNRMin = 0;   % dB
SNRMax = 40;   % dB

DopplerMin = 0;
DopplerMax = 500;
Fc = 2.4e9;

if exist("gcp","file")
  pool = gcp('nocreate');
  if isempty(pool)
    pool = parpool;
  end
  numWorkers = pool.NumWorkers;
else
  numWorkers = 1;
end
numFramesPerWorker = ceil(numFrames / numWorkers);

tStart = tic;
parfor parIdx=1:numWorkers
  frameIdx = maxFrameNum - numFramesPerWorker*(numWorkers-1) - numWorkers;
  if frameIdx < 0
    frameIdx = 0;
  end
  while frameIdx < numFramesPerWorker
    Doppler = rand()*(DopplerMax-DopplerMin) + DopplerMin;

    % Generate Zigbee signal
    timeShiftZigbee = rand()*maxTimeShift;
    [rxWaveZigbee, waveinfoZigbee, timePosIndZigbee] = ZigbeeSignalGenerator(samplesPerChip, timeShiftZigbee, numSF, outFs, imageSize(1));

    % Generate WLAN signal
    timeShiftWLAN = rand()*maxTimeShift;
    [rxWaveWLAN, waveinfoWLAN, timePosIndWLAN] = WLANSignalGenerator(wlanChBW,...
        timeShiftWLAN,numSF,outFs,Fc,imageSize(1));

    if length(rxWaveWLAN) > length(rxWaveZigbee)
        rxWaveWLAN = rxWaveWLAN(1:length(rxWaveZigbee));
    else
        rxWaveWLAN = [rxWaveWLAN; zeros(length(rxWaveZigbee) - length(rxWaveWLAN), 1)];
    end

    % Decide on channel parameters
    SNRdB = rand()*(SNRMax-SNRMin) + SNRMin;

    for imgSizeIndex=1:size(imageSize,1)

        imgSize = imageSize(imgSizeIndex,:);

        % Save channel impaired WLAN signal spectrogram and pixel labels
        paramsWLAN = struct();
        paramsWLAN.BW = wlanChBW;
        paramsWLAN.SNRdB = SNRdB;
        paramsWLAN.Info = waveinfoWLAN;

        [rxWaveWLAN2,freqOff] = shiftInFrequency(rxWaveWLAN, ...
            waveinfoWLAN.Bandwidth, ...
            waveinfoWLAN.SampleRate, imgSize(2));
        rxWaveWLAN2 = awgn(rxWaveWLAN2,SNRdB,'measured');
        dirName = fullfile(trainDir, sprintf('%dx%d',imgSize(1),imgSize(2)));
        saveSpectrogramImage(rxWaveWLAN2,waveinfoWLAN.SampleRate,dirName,'WLAN',imgSize,frameIdx+(numFramesPerWorker*(parIdx-1)));
        freqPos = freqOff' + [-waveinfoWLAN.Bandwidth/2 +waveinfoWLAN.Bandwidth/2]';
        savePixelLabelImage({timePosIndWLAN}, freqPos, {'WLAN'}, classNames, waveinfoWLAN.SampleRate, paramsWLAN, dirName, imgSize, frameIdx+(numFramesPerWorker*(parIdx-1)),saveChannelInfo)


        % Save channel impaired Zigbee signal spectrogram and pixel labels
        paramsZigbee = struct();
        paramsZigbee.BW = ZigbeeChBW;
        paramsZigbee.SamplesPerChip = samplesPerChip;
        paramsZigbee.PSDULength = 127;
        paramsZigbee.NumPackets = 1;
        paramsZigbee.SNRdB = SNRdB;
        paramsZigbee.Doppler = Doppler;
        paramsZigbee.Info = waveinfoZigbee;

        [rxWaveZigbee2,freqOff] = shiftInFrequency(rxWaveZigbee, ...
            waveinfoZigbee.Bandwidth, ...
            waveinfoZigbee.SampleRate, imgSize(2));
        rxWaveZigbee2 = awgn(rxWaveZigbee2,SNRdB,'measured');
        dirName = fullfile(trainDir, sprintf('%dx%d',imgSize(1),imgSize(2)));
        saveSpectrogramImage(rxWaveZigbee2,waveinfoZigbee.SampleRate,dirName,'Zigbee',imgSize,frameIdx+(numFramesPerWorker*(parIdx-1)));
        freqPos = freqOff' + [-waveinfoZigbee.Bandwidth/2 +waveinfoZigbee.Bandwidth/2]';
        savePixelLabelImage({timePosIndZigbee}, freqPos, {'Zigbee'}, classNames, waveinfoZigbee.SampleRate, paramsZigbee, dirName, imgSize, frameIdx+(numFramesPerWorker*(parIdx-1)),saveChannelInfo);

        % Save combined image
        assert(waveinfoWLAN.SampleRate == waveinfoZigbee.SampleRate)
        
        sr = waveinfoWLAN.SampleRate;
        comb = comm.MultibandCombiner("InputSampleRate",sr, ...
            "OutputSampleRateSource","Property",...
            "OutputSampleRate",sr);

        % Decide on the frequency space between WLAN and Zigbee
        maxFreqSpace = (sr - waveinfoZigbee.Bandwidth - waveinfoWLAN.Bandwidth);
        if maxFreqSpace > 0
            
        freqSpace = round(rand()*maxFreqSpace/1e6)*1e6;
        freqPerPixel = sr / imgSize(2);
        maxStartFreq = sr - (waveinfoZigbee.Bandwidth + waveinfoWLAN.Bandwidth + freqSpace) - freqPerPixel;

        % Decide if Zigbee or WLAN is on the left
        WLANFirst = randi([0 1]);
        if WLANFirst
            combIn = [rxWaveWLAN, rxWaveZigbee];
            labels = {'WLAN','Zigbee'};
            startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfoWLAN.Bandwidth/2;
            bwMatrix = [-waveinfoWLAN.Bandwidth/2 +waveinfoWLAN.Bandwidth/2; -waveinfoZigbee.Bandwidth/2 +waveinfoZigbee.Bandwidth/2]';
        else
            combIn = [rxWaveZigbee rxWaveWLAN];
            labels = {'Zigbee','WLAN'};
            startFreq = round(rand()*maxStartFreq/1e6)*1e6 - sr/2 + waveinfoZigbee.Bandwidth/2;
            bwMatrix = [-waveinfoZigbee.Bandwidth/2 +waveinfoZigbee.Bandwidth/2; -waveinfoWLAN.Bandwidth/2 +waveinfoWLAN.Bandwidth/2]';
        end
        comb.FrequencyOffsets = [startFreq startFreq+waveinfoWLAN.Bandwidth/2 + freqSpace + waveinfoZigbee.Bandwidth/2];
        rxWaveChan = comb(combIn);

        % Add noise
        rxWave = awgn(rxWaveChan,SNRdB,'measured');

        % Create spectrogram image
        paramsComb = struct();
        paramsComb.WLANBW = wlanChBW;
        paramsComb.ZigbeeBW = ZigbeeChBW;
        paramsComb.SNRdB = SNRdB;
        paramsComb.Doppler = Doppler;
        paramsComb.SamplesPerChip = samplesPerChip;
        paramsComb.PSDULength = 127;
        paramsComb.NumPackets = 1;
        dirName = fullfile(trainDir, sprintf('%dx%d',imgSize(1),imgSize(2)),'Zigbee_WLAN');
        saveSpectrogramImage(rxWave,sr,dirName,...
            'Zigbee_WLAN',imgSize,frameIdx+(numFramesPerWorker*(parIdx-1)));
        freqPos = comb.FrequencyOffsets + bwMatrix;
        % Compute timePosInd for combined signals
        N = size(rxWave,1);  % total samples
        sampPerPixel = round(N / imgSize(1));
        
        if WLANFirst
            timePosInd1 = timePosIndWLAN;
            timePosInd2 = floor(timePosIndZigbee / sampPerPixel) + 1;
        else
            timePosInd1 = timePosIndZigbee;
            timePosInd2 = floor(timePosIndWLAN / sampPerPixel) + 1;
        end
        
        timePosInd1(timePosInd1 > imgSize(1)) = imgSize(1);
        timePosInd2(timePosInd2 > imgSize(1)) = imgSize(1);
        
        savePixelLabelImage({timePosInd1, timePosInd2}, freqPos, labels, classNames, ...
            sr, paramsComb, dirName, imgSize, ...
            frameIdx+(numFramesPerWorker*(parIdx-1)), saveChannelInfo);
        end
        release(comb)
    end
    
    frameIdx = frameIdx + 1;
    if mod(frameIdx,10) == 0
      elapsedTime = seconds(toc(tStart));
      elapsedTime.Format = "hh:mm:ss";
      disp(string(elapsedTime) + ": Worker " + parIdx + ...
        " generated "  + frameIdx + " frames")
    end
  end
  elapsedTime = seconds(toc(tStart));
  elapsedTime.Format = "hh:mm:ss";
  disp(string(elapsedTime) + ": Worker " + parIdx + ...
    " generated "  + frameIdx + " frames")
end
end
