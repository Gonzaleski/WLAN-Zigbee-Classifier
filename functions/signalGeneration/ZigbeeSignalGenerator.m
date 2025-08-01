function [rxZigbeeWaveform, waveInfo, timePosInd] = ZigbeeSignalGenerator(...
    samplesPerChip, timeShift, timeDur, outputFs, imSize)
%ZigbeeSignalGenerator Generate a Zigbee signal waveform for spectrum sensing
%
%   [rxZigbeeWaveform, waveInfo, timePosInd] = ZigbeeSignalGenerator(samplesPerChip, ...
%       timeShift, timeDur, outputFs, imSize) generates a Zigbee IEEE 802.15.4 
%   OQPSK PHY waveform with specified parameters.
%
%   Inputs:
%     samplesPerChip - Number of samples per chip for Zigbee PHY (e.g., 20)
%     timeShift      - Time delay (ms) to shift each packet in the generated waveform
%     timeDur        - Total duration (ms) of the output waveform
%     outputFs       - Output sample rate (Hz)
%     imSize         - Image width (pixels) corresponding to time axis for labeling
%
%   Outputs:
%     rxZigbeeWaveform - Complex baseband signal vector after multipath channel
%     waveInfo         - Struct with fields SampleRate, Bandwidth, and Nfft
%     timePosInd       - Vector of pixel indices on the time axis where Zigbee signal is present
%
%   The function generates multiple Zigbee packets with random payloads, shifts 
%   them in time, interpolates to the output sampling rate, applies a Rician
%   multipath channel, and scales the power to match LTE/NR levels.
%
%   The output timePosInd corresponds to image pixels where the Zigbee signal is active.

% Configure Zigbee PHY parameters using IEEE 802.15.4 OQPSK config
cfgZB = lrwpanOQPSKConfig('SamplesPerChip', samplesPerChip);
cfgZB.Band = 2450;          % 2.45 GHz ISM band
cfgZB.PSDULength = 127;     % Maximum payload length in bytes

% Baseband sample rate of Zigbee PHY
baseRate = cfgZB.SampleRate;

% Calculate interpolation factors to convert baseRate to desired outputFs
[interpP, interpQ] = rat(outputFs / baseRate);

% Total samples for the entire waveform duration
numBBSamples = timeDur * 1e-3 * outputFs;

% Initialize output waveform as complex zeros
rxZigbeeWaveform = zeros(numBBSamples, 1, 'like', 1+1j);

% Define possible idle gaps (samples) between Zigbee packets
idleTime = round((1:10) * 1e-4 * outputFs);

endIdx = 0; % End index of last appended packet
timeStartInd = [];
timeEndInd = [];

% Maximum payload bits (127 bytes * 8 bits)
maxPayloadBits = cfgZB.PSDULength * 8;

% Generate Zigbee packets until waveform length is met
while endIdx < numBBSamples
    % Random payload bits for a single packet
    payload = randi([0 1], maxPayloadBits, 1);
    
    % Generate Zigbee waveform for one packet (no idle time within packet)
    txWave = lrwpanWaveformGenerator(payload, cfgZB, ...
        'NumPackets', 1, ...
        'IdleTime', 0);

    % Apply time shift (circular shift by given milliseconds)
    txWave = circshift(txWave, floor(timeShift * 1e-3 * baseRate));

    % Resample waveform to desired output sample rate
    txInterp = resample(txWave, interpP, interpQ);

    % Pass waveform through a Rician multipath channel to simulate indoor fading
    chanOut = multipathChannelZigbee(txInterp, outputFs);

    % Randomly choose start index separated by idle gap from last packet
    startIdx = endIdx + idleTime(randi([1 numel(idleTime)]));
    endIdx = startIdx + numel(chanOut);

    % If waveform exceeds total length, discard this packet and retry
    if endIdx > numBBSamples
        continue
    end

    % Insert scaled Zigbee signal into overall waveform
    rxZigbeeWaveform(startIdx+1:endIdx) = 0.008 * chanOut;

    % Record start and end indices for labeling
    timeStartInd = [timeStartInd; startIdx+1];
    timeEndInd = [timeEndInd; endIdx];
end

% Map time sample indices to image pixel indices for labeling
sampPerPixel = round(numBBSamples / imSize);
timePosCell = arrayfun(@(a, b) a:b, ...
    floor(timeStartInd / sampPerPixel) + 1, ...
    ceil(timeEndInd / sampPerPixel), ...
    'UniformOutput', false);

% Ensure column vectors for concatenation
timePosCell = cellfun(@(x) x(:), timePosCell, 'UniformOutput', false);

% Combine and get unique pixel indices where signal is present
timePosInd = unique(cell2mat(timePosCell));

% Provide output waveform information for reference
waveInfo.SampleRate = outputFs;
waveInfo.Bandwidth = 2e6;  % Approximate Zigbee bandwidth ~2 MHz
waveInfo.Nfft = 256;       % FFT size for spectrogram generation
end
