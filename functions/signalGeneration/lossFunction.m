function loss = lossFunction(ypred,yactual,weights)
% Compute weighted cross-entropy loss.

% Find the dimension index for the 'C' (channel) dimension in ypred
cdim = find(dims(ypred) == 'C');

% Compute the unnormalized weighted cross-entropy loss
loss = crossentropy(ypred, yactual, weights, ...
    WeightsFormat="C", NormalizationFactor="none");

% Reshape weights to match the dimensions of yactual along the class axis
wn = shiftdim(weights(:)', -(cdim-2));

% Compute weighted normalization factor by multiplying one-hot labels with weights
wnT = extractdata(yactual) .* wn;

% Sum all elements and avoid division by zero using eps
normFac = sum(wnT(:)) + eps('single');

% Normalize the loss by the computed weighted normalization factor
loss = loss / normFac;
end
