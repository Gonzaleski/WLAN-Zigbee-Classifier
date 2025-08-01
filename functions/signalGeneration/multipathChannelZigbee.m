function y = multipathChannelZigbee(x, sr)
% multipathChannelZigbee Simulates a simple indoor multipath fading channel using Rician fading
%
% Inputs:
%   x  - Input signal vector (complex baseband)
%   sr - Sample rate in Hz
%
% Outputs:
%   y  - Output signal after passing through Rician multipath fading channel
%
% This model simulates typical indoor wireless channel conditions with
% multiple delayed paths, power decay, and Doppler effects.

  chan = comm.RicianChannel( ...
      'SampleRate', sr, ...                 % Sampling frequency
      'PathDelays', [0 0.1e-6 0.3e-6], ... % Multipath delays in seconds
      'AveragePathGains', [0 -5 -10], ...  % Power gains (dB) for each path
      'KFactor', 4, ...                     % Rician K-factor (ratio of LOS to scattered power)
      'MaximumDopplerShift', 5, ...        % Maximum Doppler shift in Hz
      'DirectPathDopplerShift', 0);         % Doppler shift of LOS path (0 for static)
  
  y = chan(x); % Pass the input signal through the channel model
end
