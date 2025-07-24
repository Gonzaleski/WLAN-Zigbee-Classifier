function [rxChanWaveform, waveInfo, timePosInd] = helperSpecSenseWLANSignal(chBW,timeShift,timeDur,outputFs,fc,imSize)
%helperSpecSenseWLANSignal WLAN signal generator
%   [X,INFO,TIMEPOS] =
%   helperSpecSenseWLANSignal(CHBW,TD,DURATION,FS,FC,IMSIZE) generates a
%   WLAN signal with channel bandwidth set to chBW MHz, time delay of the
%   start of the frame is set to TD in ms, time duration of signal is set
%   as DURATION in ms, and output sample rate set to FS. X contains the
%   generated frame I/Q samples after passing through channel with carrier
%   frequency set to fc, INFO contains the information on the generated
%   waveform and TIMEPOSIND contains the pixel indices in which WLAN signal
%   is presentin spectogram.
%
%   See also wlanWaveformGenerator.

%   Copyright 2025 The MathWorks, Inc.

if chBW == 20
    bw = 'CBW20';
else
    bw = 'CBW40';
end
% Create HE-SU configuration object with valid MCS
cfgHE = wlanHESUConfig(ChannelBandwidth=bw,MCS=randi([0 11],1,1));
numBBSamples = timeDur*1e-3*outputFs;
sr = wlanSampleRate(cfgHE, 'OversamplingFactor', 1);
rate = outputFs / sr;
[p,q] = rat(rate);
rxChanWaveform = zeros(numBBSamples,1,'like',1+1j);
idleTime = round((1:10)*1e-4*outputFs);
% Maximum APEP length based on MCS
maxAPEPLength = [4900 9900 14800 19800 29700 39600 44600 49500 59400 64100 74300 82600];
endIdx = 0; 
timeStartInd = [];
timeEndInd = [];
while endIdx < numBBSamples
    cfgHE.APEPLength = randi([10 maxAPEPLength(cfgHE.MCS+1)],1,1);
    input = randi([0 1],cfgHE.APEPLength*8,1);
    txWave = wlanWaveformGenerator(input, cfgHE, ...
    'ScramblerInitialization', 93, ...
    'WindowTransitionTime', 1e-07);
    % Time shift
    txWave = circshift(txWave,floor(timeShift*1e-3*sr));
    % Interpolate for wideband spectrum monitoring
    txWaveInt = resample(txWave,p,q);
    txChanOut = multipathChannelWLAN(txWaveInt,outputFs,chBW,fc);
    startIdx = endIdx + idleTime(randi([1 length(idleTime)]));
    endIdx = startIdx + length(txChanOut);
    if endIdx > numBBSamples
        continue
    end
    % Apply power scaling to match 5G NR and LTE signals power levels
    rxChanWaveform(startIdx+1:endIdx) = 0.008*txChanOut; 
    timeStartInd = [timeStartInd;startIdx+1];
    timeEndInd = [timeEndInd;endIdx];
end
% Map the WLAn signal to image pixel index in time domain
sampPerPixel = round(numBBSamples/imSize);
timePosCell = arrayfun(@(A, B) A:B, floor(timeStartInd/sampPerPixel)+1, ceil(timeEndInd/sampPerPixel), 'UniformOutput', false);
timePosInd = cell2mat(cellfun(@(x) x, timePosCell, 'UniformOutput', false).')';
timePosInd = unique(timePosInd);
waveInfo.SampleRate = outputFs;
waveInfo.Bandwidth = chBW*1e6;
waveInfo.Nfft = 256*chBW/20;
end
function y = multipathChannelWLAN(x, sr, bw, fc)
  bwList = ["CBW20" "CBW40"];
  chan = wlanTGaxChannel(ChannelBandwidth=bwList(bw/20), ...
      DelayProfile="Model-D",...
      TransmitReceiveDistance=15,...
      CarrierFrequency=fc, ...
      SampleRate=sr);
  y = chan(x);
end