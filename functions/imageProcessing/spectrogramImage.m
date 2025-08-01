function [I, P] = spectrogramImage(x, Nfft, sr, imgSize)
% Generate a spectrogram image from input signal x.
%
% Inputs:
%   x       - Input signal vector (time-domain samples)
%   Nfft    - FFT length for spectrogram computation
%   sr      - Sample rate of the input signal (Hz)
%   imgSize - Desired output image size [height, width] in pixels
%
% Outputs:
%   I       - RGB spectrogram image of size imgSize using parula colormap
%   P       - Power spectral density matrix (logarithmic scale)
%
% This function computes the spectrogram power spectral density (PSD) of 
% the input signal, converts it to logarithmic scale, rescales and resizes 
% it to a specified image size, and finally applies the parula colormap 
% to generate an RGB image.
%
%   Copyright 2021-2023 The MathWorks, Inc.
%   Modified 2025 by Arad Soutehkeshan

% Define window and overlap for spectrogram
window = hann(256);
overlap = 10;

% Compute spectrogram (PSD), centered and with 'psd' option
[~, ~, ~, P] = spectrogram(x, window, overlap, Nfft, sr, 'centered', 'psd');

% Convert power spectral density to dB scale (logarithmic)
P = 10 * log10(abs(P') + eps);

% Rescale values to [0, 1] interval, convert to uint8 image
im = imresize(im2uint8(rescale(P)), imgSize, "nearest");

% Map grayscale image to RGB using parula colormap and flip vertically
I = im2uint8(flipud(ind2rgb(im, parula(256))));
end
