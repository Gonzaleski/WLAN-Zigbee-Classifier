function displayResults(signal,trueLabels,predictedLabels,...
    classNames,sr,fc,to)
%   Copyright 2021 The MathWorks, Inc.
%   Modified by Arad Soutehkeshan, 2025
%
%   This function displays spectrogram results including:
%   - The received signal's spectrogram
%   - Ground truth labels (if provided)
%   - Predicted labels from classification

numClasses = numel(classNames);
cmap = cool(numClasses); % Define colormap for class labels

if ~isempty(trueLabels)
  trueLabels = double(trueLabels);
end

predictedLabels = double(predictedLabels);

% Time axis in milliseconds
t = linspace(-to,0,size(signal,1)) * 1e3;
% Frequency axis in MHz, centered around carrier frequency
f = (linspace(-sr/2,sr/2,size(signal,2)) + fc)/1e6;

freqDim = 2; % Set frequency dimension on x-axis

N = numel(classNames);
ticks = 1:N;

% Layout: if true labels are available, use 3 subplots
if ~isempty(trueLabels)
  subplot(311)
else
  subplot(211)
end

% Flip spectrogram data before displaying (MATLAB image flips it again)
signal = flipud(signal);

% Plot received spectrogram
if freqDim == 2
  imagesc(f,t,signal)
  xlabel('Frequency (MHz)')
  ylabel('Time (ms)')
else
  imagesc(t,f,signal)
  xlabel('Time (ms)')
  ylabel('Frequency (MHz)')
end
set(gca,'YDir','normal')
a = colorbar;
colormap(a,parula(256))
title("Received Spectrogram")

% Plot ground truth labels if available
if ~isempty(trueLabels)
  subplot(312)
  if freqDim == 2
    im = imagesc(f,t,trueLabels,[1 numClasses]);
    xlabel('Frequency (MHz)')
    ylabel('Time (ms)')
  else
    im = imagesc(t,f,trueLabels,[1 numClasses]);
    xlabel('Time (ms)')
    ylabel('Frequency (MHz)')
  end
  set(gca,'YDir','normal')
  im.Parent.Colormap = cmap;
  colorbar('TickLabels',cellstr(classNames),'Ticks',ticks,...
    'TickLength',0,'TickLabelInterpreter','none');
  title('True signal labels')
end

% Plot predicted labels
if ~isempty(trueLabels)
  subplot(313)
else
  subplot(212)
end

predictedLabels = flipud(predictedLabels);

if freqDim == 2
  im = imagesc(f,t,predictedLabels,[1 numClasses]);
  xlabel('Frequency (MHz)')
  ylabel('Time (ms)')
else
  im = imagesc(t,f,predictedLabels,[1 numClasses]);
  xlabel('Time (ms)')
  ylabel('Frequency (MHz)')
end
set(gca,'YDir','normal')
im.Parent.Colormap = cmap;
colorbar('TickLabels',cellstr(classNames),'Ticks',ticks,...
  'TickLength',0,'TickLabelInterpreter','none');
title('Estimated signal labels')

end
