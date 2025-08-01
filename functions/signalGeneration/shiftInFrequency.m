function [y, freqOff] = shiftInFrequency(x, bw, sr, numFreqPixels)
%shiftInFrequency Apply a random frequency offset to input signal
%
%   [y, freqOff] = shiftInFrequency(x, bw, sr, numFreqPixels) applies a
%   random frequency shift to the complex baseband signal x.
%
%   Inputs:
%     x              - Input complex baseband signal vector
%     bw             - Signal bandwidth in Hz
%     sr             - Sample rate in Hz
%     numFreqPixels  - Number of frequency pixels in spectrogram image
%
%   Outputs:
%     y        - Frequency-shifted output signal
%     freqOff  - The actual frequency offset applied (in Hz)
%
%   The frequency offset is randomly chosen within a maximum range that
%   ensures the shifted signal remains within the sampling bandwidth and
%   spectrogram resolution.
%
%   Copyright 2025 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

% Create System object to apply frequency offset
freqOffsetObj = comm.PhaseFrequencyOffset('SampleRate', sr);

% Calculate maximum allowable frequency shift (Hz)
% Ensures shifted signal stays within Nyquist and image resolution limits
maxFreqShift = (sr - bw) / 2 - sr / numFreqPixels;

% Generate random frequency offset between -maxFreqShift and +maxFreqShift
freqOff = (2 * rand() - 1) * maxFreqShift;

% Set frequency offset in the System object
freqOffsetObj.FrequencyOffset = freqOff;

% Apply frequency offset to the input signal
y = freqOffsetObj(x);

end
