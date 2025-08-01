function savePixelLabelImage(timePos, freqPos, label, pixelClassNames, sr, params, folder, imSize, idx, saveChannelInfo)
% savePixelLabelImage Generate and save a pixel label image for spectrogram
%
%   savePixelLabelImage(timePos, freqPos, label, pixelClassNames, sr, params, folder, imSize, idx, saveChannelInfo)
%   creates a labeled image where pixels corresponding to signals are marked
%   with class values based on 'label' and saves it as an HDF file. Optionally
%   saves channel info as a MAT file.
%
%   Inputs:
%     timePos          - Cell array of time pixel indices per label
%     freqPos          - Matrix of frequency start/end positions per label [2 x numLabels]
%     label            - Cell array of labels for each signal segment (strings)
%     pixelClassNames  - Cell array of all class names (strings)
%     sr               - Sample rate (Hz)
%     params           - Struct or data to save if saveChannelInfo==true
%     folder           - Destination folder to save files
%     imSize           - Size of output image [height width]
%     idx              - Frame index for filename uniqueness
%     saveChannelInfo  - Boolean flag to save channel parameters
%
%   Output:
%     Saves labeled pixel image as HDF file and optionally parameters as MAT file
%
%   Copyright 2025 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

% Initialize label image with zeros (background)
data = uint8(zeros(imSize));

% Frequency range per pixel (Hz per pixel)
freqPerPixel = sr / imSize(2);

for p = 1:length(label)
    % Map label name to pixel class value (0-255 scale)
    pixelValue = floor((find(strcmp(label{p}, pixelClassNames)) - 1) * 255 / (numel(pixelClassNames) - 1));

    % Convert frequency positions (Hz) to pixel indices, clamp to valid range
    freqPixels = floor((sr/2 + freqPos(:, p)) / freqPerPixel) + 1;
    freqPixels(freqPixels < 1) = 1;
    freqPixels(freqPixels > imSize(2)) = imSize(2);

    % Time pixel indices as provided, clamp to image size
    timePixels = timePos{p};
    timePixels(timePixels > imSize(1)) = imSize(1);

    % Assign pixel value to the region in label image (time x freq)
    if freqPixels(1) <= freqPixels(2)
        data(timePixels, freqPixels(1):freqPixels(2)) = uint8(pixelValue);
    end
end

% Create filename string from labels
if isscalar(label)
    lbl = label{1};
else
    lbl = strjoin(label, '_');
end

fname = fullfile(folder, [lbl '_frame_' strrep(num2str(idx), ' ', '')]);
fnameLabels = fname + ".hdf";

% Flip image vertically to match display orientation
data = flipud(data);

% Save label image to HDF file
imwrite(data, fnameLabels, 'hdf');

% Optionally save channel info params as MAT file
if saveChannelInfo
    fnameParams = fname + ".mat";
    save(fnameParams, "params")
end
end
