% === Test Script to Generate WLAN & Zigbee Signals and Visualize Separately ===

% --- Parameters ---
timeDuration = 20;           % ms
outputFs = 20e6;             % 20 MHz common sampling rate
fcWLAN = 2.437e9;            % WLAN Channel 6
imageSize = 256;             % Image width (for timePosInd)
timeShift = 0.2;             % ms delay per burst

% --- Generate WLAN ---
fprintf('Generating WLAN signal...\n');
[wlanWave, wlanInfo, wlanPos] = helperSpecSenseWLANSignal(20, timeShift, ...
    timeDuration, outputFs, fcWLAN, imageSize);

% --- Generate Zigbee ---
fprintf('Generating Zigbee signal...\n');
[zigbeeWave, zigbeeInfo, zigbeePos] = helperSpecSenseZigbeeSignal(20, ...
    timeShift, timeDuration, outputFs, imageSize);

% --- Time vector for plots ---
t = (0:length(wlanWave)-1) / outputFs * 1e3;  % time in ms

% === Plot 1: Spectrum ===
figure;
subplot(2,1,1);
spectrumAnalyzerWLAN = dsp.SpectrumAnalyzer('SampleRate', outputFs, ...
    'SpectrumType', 'Power density', ...
    'Title', 'Power Spectrum of WLAN Signal', ...
    'YLimits', [-120 0]);
spectrumAnalyzerWLAN(wlanWave);
release(spectrumAnalyzerWLAN);

subplot(2,1,2);
spectrumAnalyzerZigbee = dsp.SpectrumAnalyzer('SampleRate', outputFs, ...
    'SpectrumType', 'Power density', ...
    'Title', 'Power Spectrum of Zigbee Signal', ...
    'YLimits', [-120 0]);
spectrumAnalyzerZigbee(zigbeeWave);
release(spectrumAnalyzerZigbee);

% === Plot 2: Spectrograms Separately with Overlay ===
fprintf('Plotting WLAN spectrogram...\n');
figure;
subplot(2,1,1);
windowLength = 256;
noverlap = round(0.9 * windowLength);
nfft = 1024;
spectrogram(wlanWave, windowLength, noverlap, nfft, outputFs, 'yaxis');
title('Spectrogram of WLAN');
ylim([0 10]); yticks(0:1:10);
ylabel('Freq (MHz)'); xlabel('Time (s)');
colormap jet;
hold on;
plot([wlanPos / imageSize * timeDuration / 1000; ...
      wlanPos / imageSize * timeDuration / 1000], ...
     [ones(size(wlanPos)); ones(size(wlanPos)) * 10], 'r.', 'DisplayName', 'WLAN');
legend('WLAN'); hold off;

fprintf('Plotting Zigbee spectrogram...\n');
subplot(2,1,2);
spectrogram(zigbeeWave, windowLength, noverlap, nfft, outputFs, 'yaxis');
title('Spectrogram of Zigbee');
ylim([0 10]); yticks(0:1:10);
ylabel('Freq (MHz)'); xlabel('Time (s)');
colormap jet;
hold on;
plot([zigbeePos / imageSize * timeDuration / 1000; ...
      zigbeePos / imageSize * timeDuration / 1000], ...
     [ones(size(zigbeePos)); ones(size(zigbeePos)) * 10], 'g.', 'DisplayName', 'Zigbee');
legend('Zigbee'); hold off;
