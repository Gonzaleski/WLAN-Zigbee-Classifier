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
    [rxWaveZigbee, waveinfoZigbee, timePosIndZigbee] = helperSpecSenseZigbeeSignal(samplesPerChip, timeShiftZigbee, numSF, outFs, imageSize(1));

    % Generate WLAN signal
    timeShiftWLAN = rand()*maxTimeShift;
    [rxWaveWLAN, waveinfoWLAN, timePosIndWLAN] = helperSpecSenseWLANSignal(wlanChBW,...
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
    
    
% Helper Functions
function y = multipathChannelZigbee(x, sr, doppler)
% multipathChannelZigbee Apply Zigbee multipath fading channel
%
%   y = multipathChannelZigbee(x, sr, doppler, fc) applies a custom
%   multipath channel for Zigbee signals.
%
%   Inputs:
%       x       - Baseband Zigbee waveform
%       sr      - Sample rate (Hz)
%       doppler - Maximum Doppler shift (Hz)
%       fc      - Carrier frequency (Hz)
%
%   Output:
%       y       - Waveform after channel effects

    % Zigbee typically uses short-range links, so simple Rayleigh fading
    % channel with few taps is sufficient.
    % Example multipath profile: 3 taps with small delays and decay
    pathDelays = [0 50e-9 100e-9];                % in seconds
    avgPathGains = [0 -3 -6];                     % in dB

    % Create channel object
    chan = comm.RayleighChannel( ...
        'SampleRate', sr, ...
        'PathDelays', pathDelays, ...
        'AveragePathGains', avgPathGains, ...
        'MaximumDopplerShift', doppler, ...
        'NormalizePathGains', true);

    % Apply channel
    y = chan(x);

end


function [y,freqOff] = shiftInFrequency(x, bw, sr, numFreqPixels)
freqOffset = comm.PhaseFrequencyOffset(...
  'SampleRate',sr);

maxFreqShift = (sr-bw) / 2 - sr/numFreqPixels;
freqOff = (2*rand()-1)*maxFreqShift;
freqOffset.FrequencyOffset = freqOff;
y = freqOffset(x);
end


function saveSpectrogramImage(rxWave,sr,folder,label,imageSize, idx)
Nfft = 4096;

rxSpectrogram = helperSpecSenseSpectrogramImage(rxWave,Nfft,sr,imageSize);

% Create file name
fname = fullfile(folder, [label '_frame_' strrep(num2str(idx),' ','')]);
fname = fname + ".png";
imwrite(rxSpectrogram, fname)
end

function savePixelLabelImage(timePos, freqPos, label, pixelClassNames, sr, params, folder, imSize, idx, saveChannelInfo)
    data = uint8(zeros(imSize));
    freqPerPixel = sr / imSize(2);

    for p = 1:length(label)
        pixelValue = floor((find(strcmp(label{p}, pixelClassNames)) - 1) * 255 / (numel(pixelClassNames) - 1));

        freqPixels = floor((sr/2 + freqPos(:, p)) / freqPerPixel) + 1;
        freqPixels(freqPixels < 1) = 1;
        freqPixels(freqPixels > imSize(2)) = imSize(2);

        % For WLAN and Zigbee, just use the provided time indices (clamp if needed)
        timePixels = timePos{p};
        timePixels(timePixels > imSize(1)) = imSize(1);

        if freqPixels(1) <= freqPixels(2)
            data(timePixels, freqPixels(1):freqPixels(2)) = uint8(pixelValue);
        end
    end

    % Build filename based on labels present
    if isscalar(label)
        lbl = label{1};
    else
        lbl = strjoin(label, '_');
    end

    fname = fullfile(folder, [lbl '_frame_' strrep(num2str(idx), ' ', '')]);
    fnameLabels = fname + ".hdf";

    data = flipud(data);
    
    % Save label image
    imwrite(data, fnameLabels, 'hdf');
    
    if saveChannelInfo
        fnameParams = fname + ".mat";
        save(fnameParams, "params")
    end
end


