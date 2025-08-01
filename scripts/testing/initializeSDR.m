% Set up PlutoSDR receiver
rx = sdrrx('Pluto');
rx.CenterFrequency = 2.4e9;
rx.BasebandSampleRate = 20e6;
rx.SamplesPerFrame = 40 * 1e-3 * rx.BasebandSampleRate;
rx.OutputDataType = 'single';
rx.EnableBurstMode = true;
rx.NumFramesInBurst = 1;
