function saveSpectrogramImage(rxWave, sr, folder, label, imageSize, idx)
% saveSpectrogramImage Generate and save a spectrogram image from a signal
%
%   saveSpectrogramImage(rxWave, sr, folder, label, imageSize, idx)
%   generates a spectrogram image from the received waveform 'rxWave'
%   using sample rate 'sr', resizes it to 'imageSize', and saves the image
%   as a PNG file in the specified 'folder'.
%
%   Inputs:
%     rxWave    - Input time-domain complex waveform (vector)
%     sr        - Sample rate in Hz
%     folder    - Folder path where image will be saved
%     label     - String label to use in filename (e.g., signal class)
%     imageSize - 2-element vector specifying output image size [height width]
%     idx       - Frame index (used for filename uniqueness)
%
%   Output:
%     Saves spectrogram image as PNG file named as <label>_frame_<idx>.png
%     inside the specified folder.
%
%   Copyright 2025 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

Nfft = 4096; % Number of FFT points for spectrogram calculation

% Generate spectrogram image using helper function
rxSpectrogram = spectrogramImage(rxWave, Nfft, sr, imageSize);

% Create filename with label and frame index
fname = fullfile(folder, [label '_frame_' strrep(num2str(idx), ' ', '')]);

% Append file extension
fname = fname + ".png";

% Save image to disk
imwrite(rxSpectrogram, fname);
end
