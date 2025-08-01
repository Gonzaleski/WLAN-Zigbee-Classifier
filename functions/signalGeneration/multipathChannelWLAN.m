function y = multipathChannelWLAN(x, sr, bw, fc)
% Apply WLAN TGax multipath fading channel model
%
% Inputs:
%   x  - input baseband waveform
%   sr - sample rate (Hz)
%   bw - channel bandwidth in MHz (20 or 40)
%   fc - carrier frequency (Hz)
%
% Output:
%   y  - output waveform after channel effects
%
%   Copyright 2025 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

bwList = ["CBW20", "CBW40"];
if bw == 20
    chanBW = bwList(1);
elseif bw == 40
    chanBW = bwList(2);
else
    error('Unsupported bandwidth in multipathChannelWLAN.');
end

chan = wlanTGaxChannel(ChannelBandwidth=chanBW, ...
    DelayProfile="Model-D", ...
    TransmitReceiveDistance=15, ...
    CarrierFrequency=fc, ...
    SampleRate=sr);

y = chan(x);
end