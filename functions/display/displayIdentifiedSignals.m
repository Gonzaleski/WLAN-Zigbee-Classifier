function varargout = displayIdentifiedSignals(rcvdSpect, segResults, classNames, sr, fc, to)
% displayIdentifiedSignals Visually overlays identified signal classes on a spectrogram.
%
% Inputs:
%   - rcvdSpect   : Spectrogram matrix (time x frequency).
%   - segResults  : Segmentation result (time x frequency), can be numeric or categorical.
%   - classNames  : Cell array of class names (e.g., {'WLAN','Zigbee'}).
%   - sr          : Sample rate of the signal (Hz).
%   - fc          : Center frequency (Hz).
%   - to          : Observation duration (seconds).
%
% Output:
%   - freqBound (optional): Frequency bounds for each detected class occurrence.
%
%   This function masks the spectrogram using segmentation results and
%   overlays labels for each detected signal class.

%   Copyright 2021-2023 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

imageSize = size(segResults);
numClasses = numel(classNames);
cmap = cool(numClasses);  % Generate a distinct colormap for each class

% Convert numeric labels to categorical if needed
if ~isa(segResults, 'categorical')
    segResults = categorical(segResults, 1:length(classNames), classNames);
end

% Dimensions for plotting: frequency = x-axis, time = y-axis
freqDim = 2;
timeDim = 1;

maskedImg = rcvdSpect;
cnt = 1;

% Loop over each class to find and label regions where it's active
for cn = 1:length(classNames)
    % Detect contiguous regions labeled with this class
    changeIdx = diff([0 mode(segResults) == categorical(classNames(cn), classNames) 0]);
    startIdx = find(changeIdx == 1);
    endIdx = find(changeIdx == -1);

    for p = 1:length(startIdx)
        % Convert pixel locations to frequency values
        fminPixel = startIdx(p);
        fmaxPixel = min(endIdx(p), size(segResults, 2));

        fmin = fminPixel * (sr / imageSize(timeDim)) - sr/2;
        fmax = fmaxPixel * (sr / imageSize(timeDim)) - sr/2;
        freqBound{p} = [fmin fmax] + fc; %#ok<AGROW>

        % Create a binary mask over the detected region
        if ~isempty(fmin)
            maskSig = false(imageSize);
            if freqDim == 2
                loc = [(fmin + fc)/1e6, -5 * cn];  % For label positioning
                maskSig(:, fminPixel:fmaxPixel) = true;
            else
                loc = [-5 * cn, (fmin + fc)/1e6];
                maskSig(fminPixel:fmaxPixel, :) = true;
            end

            % Overlay the mask on the spectrogram
            maskedImg = insertObjectMask(maskedImg, maskSig, 'Color', cmap(cn,:), ...
                'Opacity', 0.5, 'LineOpacity', 0);

            % Store label info for later annotation
            textInfo(cnt) = struct('loc', loc, 'text', classNames(cn)); %#ok<AGROW>
            cnt = cnt + 1;
        end
    end
end

% Set up axes for time and frequency
t = linspace(-to, 0, imageSize(1)) * 1e3;           % Time in ms
f = (linspace(-sr/2, sr/2, imageSize(2)) + fc) / 1e6;  % Frequency in MHz

% Display the final labeled spectrogram
if freqDim == 2
    imagesc(f, t, maskedImg);
    xlabel('Frequency (MHz)');
    ylabel('Time (ms)');
else
    imagesc(t, f, maskedImg);
    xlabel('Time (ms)');
    ylabel('Frequency (MHz)');
end

% Fix flipped Y-axis tick labels caused by imagesc
ca = gca;
ca.YTickLabel = flipud(ca.YTickLabel);

% Add colorbar and title
h = colorbar;
colormap(h, parula(256));
title('Labeled Spectrogram');

% Overlay text labels at each detected region
for p = 1:length(textInfo)
    text(textInfo(p).loc(1), textInfo(p).loc(2), textInfo(p).text);
end

% Return frequency boundaries, if requested
if nargout > 0
    varargout{1} = freqBound;
end
