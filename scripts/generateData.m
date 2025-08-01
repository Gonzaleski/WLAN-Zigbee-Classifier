numFrames = 1000;
classNames = ["Background", "WLAN", "Zigbee"];
imageSize = [256 256];
trainDir = 'data';
numSF = 10;
outFs = 23e6;
saveChannelInfo = false;

helperSpecSenseWLANZigbeeTrainingData(numFrames, classNames, imageSize, trainDir, numSF, outFs, saveChannelInfo);