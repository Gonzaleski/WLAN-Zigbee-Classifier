function [rxZigbeeWaveform, waveInfo, timePosInd] = helperSpecSenseZigbeeSignal(...
    samplesPerChip, timeShift, timeDur, outputFs, imSize)
%helperSpecSenseZigbeeSignal Zigbee signal generator
%   [X,INFO,TIMEPOS] = helperSpecSenseZigbeeSignal(SPC,TD,DURATION,FS,FC,IMSIZE)
%   generates a Zigbee signal using IEEE 802.15.4 OQPSK PHY.
%
%   SPC: Samples per chip (e.g., 20)
%   TD: Time shift (in ms)
%   DURATION: Time duration of total signal in ms
%   FS: Output sample rate in Hz
%   FC: Carrier frequency (for channel modeling)
%   IMSIZE: Width of time axis in pixels
%
%   Returns:
%   - X: Interpolated complex baseband signal after channel
%   - INFO: Struct with SampleRate, Bandwidth, Nfft
%   - TIMEPOS: Indices (pixels) where Zigbee signal is present in time

% Zigbee configuration (OQPSK PHY, 2.4 GHz band)
cfgZB = lrwpanOQPSKConfig('SamplesPerChip', samplesPerChip);
cfgZB.Band = 2450;
cfgZB.PSDULength = 127;

% Determine baseband sample rate
baseRate = cfgZB.SampleRate;
[interpP, interpQ] = rat(outputFs / baseRate);

numBBSamples = timeDur * 1e-3 * outputFs;  % total samples for duration
rxZigbeeWaveform = zeros(numBBSamples, 1, 'like', 1+1j);

idleTime = round((1:10) * 1e-4 * outputFs);  % idle gaps between packets
endIdx = 0;
timeStartInd = [];
timeEndInd = [];

% Max payload bits
maxPayloadBits = cfgZB.PSDULength * 8;

% Generate bursts until waveform filled
while endIdx < numBBSamples
    payload = randi([0 1], maxPayloadBits, 1);
    txWave = lrwpanWaveformGenerator(payload, cfgZB, ...
        'NumPackets', 1, ...
        'IdleTime', 0);

    % Time shift
    txWave = circshift(txWave, floor(timeShift * 1e-3 * baseRate));

    % Interpolate to match output sample rate
    txInterp = resample(txWave, interpP, interpQ);

    % Channel model (TGn-like multipath fading)
    chanOut = multipathChannelZigbee(txInterp, outputFs);

    startIdx = endIdx + idleTime(randi([1 numel(idleTime)]));
    endIdx = startIdx + numel(chanOut);

    if endIdx > numBBSamples
        continue
    end

    % Power-scale Zigbee to match LTE/NR range
    rxZigbeeWaveform(startIdx+1:endIdx) = 0.008 * chanOut;
    timeStartInd = [timeStartInd; startIdx+1];
    timeEndInd = [timeEndInd; endIdx];
end

% Map to image pixel index in time domain
sampPerPixel = round(numBBSamples / imSize);
timePosCell = arrayfun(@(a, b) a:b, ...
    floor(timeStartInd / sampPerPixel) + 1, ...
    ceil(timeEndInd / sampPerPixel), ...
    'UniformOutput', false);
% Force all entries to be column vectors
timePosCell = cellfun(@(x) x(:), timePosCell, 'UniformOutput', false);
timePosInd = unique(cell2mat(timePosCell));

% Output waveform info
waveInfo.SampleRate = outputFs;
waveInfo.Bandwidth = 2e6;  % Zigbee BW is ~2 MHz
waveInfo.Nfft = 256;       % For spectrogram consistency
end

function y = multipathChannelZigbee(x, sr)
  % Simple indoor multipath channel model
  chan = comm.RicianChannel( ...
      'SampleRate', sr, ...
      'PathDelays', [0 0.1e-6 0.3e-6], ...
      'AveragePathGains', [0 -5 -10], ...
      'KFactor', 4, ...
      'MaximumDopplerShift', 5, ...
      'DirectPathDopplerShift', 0);
  y = chan(x);
end
