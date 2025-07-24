function helperSpecSenseWLANZigbeeTrainingData(numFrames, classNames, imageSize, trainDir, numSF, outFs, saveChannelInfo)
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

    maxFrameNum = 2; % Starting frame index
    
    % Zigbee and WLAN params
    samplesPerChip = 20; % Example value, adjust as needed
    wlanChBWVec = 20;
    maxTimeShift = numSF; % in ms
    
    tStart = tic;

    for frameIdx = 1:numFrames
        
        % Random parameters for Zigbee
        zigbeeTimeShift = rand()*maxTimeShift;
        [rxZigbeeWaveform, waveinfoZigbee, timePosIndZigbee] = helperSpecSenseZigbeeSignal(samplesPerChip, zigbeeTimeShift, numSF, outFs, imageSize(1));

        % Random parameters for WLAN
        wlanChBW = wlanChBWVec(randi(length(wlanChBWVec)));
        wlanTimeShift = rand()*maxTimeShift;
        fc = 5e9; % Center frequency for WLAN

        [rxWLANWaveform, waveinfoWLAN, timePosIndWLAN] = helperSpecSenseWLANSignal(wlanChBW, wlanTimeShift, numSF, outFs, fc, imageSize(1));

        % Normalize lengths
        maxLen = max(length(rxZigbeeWaveform), length(rxWLANWaveform));
        rxZigbeeWaveform(end+1:maxLen) = 0;
        rxWLANWaveform(end+1:maxLen) = 0;

        % Add noise and frequency shift individually
        SNRdB = 20 + 10*rand(); % Example SNR range 20 to 30 dB

        % Frequency shifting helper: shiftInFrequency (copy from your WLAN code)
        [rxZigbeeShifted, freqOffZigbee] = shiftInFrequency(rxZigbeeWaveform, waveinfoZigbee.Bandwidth, outFs, imageSize(2));
        rxZigbeeNoisy = awgn(rxZigbeeShifted, SNRdB, 'measured');

        [rxWLANShifted, freqOffWLAN] = shiftInFrequency(rxWLANWaveform, waveinfoWLAN.Bandwidth, outFs, imageSize(2));
        rxWLANNoisy = awgn(rxWLANShifted, SNRdB, 'measured');

        % Save single-signal spectrograms & labels
        dirName = fullfile(trainDir, sprintf('%dx%d', imageSize(1), imageSize(2)));

        % Zigbee
        paramsZigbee = struct();
        paramsZigbee.Bandwidth = waveinfoZigbee.Bandwidth;
        paramsZigbee.SNRdB = SNRdB;
        paramsZigbee.Info = waveinfoZigbee;
        saveSpectrogramImage(rxZigbeeNoisy, outFs, dirName, 'Zigbee', imageSize, frameIdx);
        freqPosZigbee = freqOffZigbee' + [-waveinfoZigbee.Bandwidth/2, waveinfoZigbee.Bandwidth/2]';
        savePixelLabelImage({timePosIndZigbee}, freqPosZigbee, {'Zigbee'}, classNames, outFs, paramsZigbee, dirName, imageSize, frameIdx, saveChannelInfo);

        % WLAN
        paramsWLAN = struct();
        paramsWLAN.Bandwidth = waveinfoWLAN.Bandwidth;
        paramsWLAN.SNRdB = SNRdB;
        paramsWLAN.Info = waveinfoWLAN;
        saveSpectrogramImage(rxWLANNoisy, outFs, dirName, 'WLAN', imageSize, frameIdx);
        freqPosWLAN = freqOffWLAN' + [-waveinfoWLAN.Bandwidth/2, waveinfoWLAN.Bandwidth/2]';
        savePixelLabelImage({timePosIndWLAN}, freqPosWLAN, {'WLAN'}, classNames, outFs, paramsWLAN, dirName, imageSize, frameIdx, saveChannelInfo);

        % Combine Zigbee and WLAN frequency-wise
        combDir = fullfile(dirName, 'Zigbee_WLAN');
        comb = comm.MultibandCombiner("InputSampleRate", outFs, ...
            "OutputSampleRateSource", "Property", "OutputSampleRate", outFs);

        % Frequency spacing setup
        maxFreqSpace = outFs - waveinfoZigbee.Bandwidth - waveinfoWLAN.Bandwidth;
        if maxFreqSpace <= 0
            warning('Sample rate too low to separate Zigbee and WLAN bands.');
            continue;
        end

        freqSpace = round(rand()*maxFreqSpace/1e6)*1e6;
        freqPerPixel = outFs / imageSize(2);
        maxStartFreq = outFs - (waveinfoZigbee.Bandwidth + waveinfoWLAN.Bandwidth + freqSpace) - freqPerPixel;

        % Randomly decide order
        zigbeeFirst = randi([0 1]);

        if zigbeeFirst
            combIn = [rxZigbeeNoisy, rxWLANNoisy];
            labels = {'Zigbee', 'WLAN'};
            startFreq = round(rand()*maxStartFreq/1e6)*1e6 - outFs/2 + waveinfoZigbee.Bandwidth/2;
            bwMatrix = [-waveinfoZigbee.Bandwidth/2, waveinfoZigbee.Bandwidth/2; -waveinfoWLAN.Bandwidth/2, waveinfoWLAN.Bandwidth/2]';
        else
            combIn = [rxWLANNoisy, rxZigbeeNoisy];
            labels = {'WLAN', 'Zigbee'};
            startFreq = round(rand()*maxStartFreq/1e6)*1e6 - outFs/2 + waveinfoWLAN.Bandwidth/2;
            bwMatrix = [-waveinfoWLAN.Bandwidth/2, waveinfoWLAN.Bandwidth/2; -waveinfoZigbee.Bandwidth/2, waveinfoZigbee.Bandwidth/2]';
        end

        comb.FrequencyOffsets = [startFreq, startFreq + waveinfoZigbee.Bandwidth/2 + freqSpace + waveinfoWLAN.Bandwidth/2];
        rxCombined = comb(combIn);

        % Add noise to combined
        rxCombinedNoisy = awgn(rxCombined, SNRdB, 'measured');

        % Save combined spectrogram and pixel labels
        paramsComb = struct();
        paramsComb.SNRdB = SNRdB;
        paramsComb.BandwidthZigbee = waveinfoZigbee.Bandwidth;
        paramsComb.BandwidthWLAN = waveinfoWLAN.Bandwidth;

        saveSpectrogramImage(rxCombinedNoisy, outFs, combDir, 'Zigbee_WLAN', imageSize, frameIdx);
        freqPosCombined = comb.FrequencyOffsets + bwMatrix;
        savePixelLabelImage({timePosIndZigbee, timePosIndWLAN}, freqPosCombined, labels, classNames, outFs, paramsComb, combDir, imageSize, frameIdx, saveChannelInfo);

        release(comb);

        if mod(frameIdx,10) == 0
            elapsedTime = seconds(toc(tStart));
            elapsedTime.Format = "hh:mm:ss";
            disp(string(elapsedTime) + ": Generated " + frameIdx + " frames");
        end
    end
end


% Helper Functions
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


