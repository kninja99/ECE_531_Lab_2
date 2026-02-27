% Setup Receiver
% samplers per frame changes from 2^15 to 10000 to match sinewave
rx=sdrrx('Pluto','OutputDataType','double','SamplesPerFrame',20000);
%rx.SamplesPerFrame = 3660;
% adjust gains source
% Manual gains source
%rx.GainSource ="Manual";
%rx.Gain = 30;
% slow attack gains source
%rx.GainSource = "AGC Slow Attack"
% Fast attack gain source
% Slow attack gain source
rx.GainSource = "AGC Fast Attack";
% Setup Transmitter
tx = sdrtx('Pluto','Gain',-30);
% Transmit sinewave (adjusted samples per frame to fit 300hz) aka phase
% alinement for a continuous waveform
% (F /Fs) * Steps
sine = dsp.SineWave('Frequency',300,...
                    'SampleRate',rx.BasebandSampleRate,...
                    'SamplesPerFrame', 20000,...
                    'ComplexOutput', true, ...
                    'Amplitude',1);
% replace the last half of the sine wave with zeros
sineSamples = sine(); % Generate sine wave samples
sineSamples(rx.SamplesPerFrame/2 + 1:end) = 0; % Replace the last half with zeros
%sineSamples(samplesPerFrame/2 + 1:end) = 0;
sine = sineSamples;
% transmit continuously
tx.transmitRepeat(sine()); % Transmit continuously

% Setup Scope
samplesPerStep = rx.SamplesPerFrame/rx.BasebandSampleRate;
steps = 3;
ts = timescope('SampleRate', rx.BasebandSampleRate,...
                   'TimeSpan', samplesPerStep*steps,...
                   'BufferLength', rx.SamplesPerFrame*steps);
storedValues = [];
signalAndNoise = [];
noiseSegment = [];
% Receive and view sine
for k=1:steps
  frame = rx();
  ts(frame);
  storedValues = [storedValues; frame];
end
% binning method
segmentPowers = [];
% calculate power threshold dynamically
for i = 1:50:length(storedValues)
    start = i;
    frameEnd = min(i + 49, length(storedValues));
    windowPower = mean(abs(storedValues(start:frameEnd)).^2);
    % look for a high energy or low energy
    segmentPowers(end+1) = windowPower;
end
%powerThreshold = (min(segmentPowers) + max(segmentPowers)/10);
powerThreshold = median(segmentPowers);
% binning used to sort signals
for i = 1:50:length(storedValues)
    start = i;
    frameEnd = min(i + 50, length(storedValues));
    windowPower = mean(abs(storedValues(start:frameEnd)).^2);
    % look for a high energy or low energy
    if windowPower < powerThreshold
        noiseSegment = [noiseSegment; storedValues(start:frameEnd)];
    else
        signalAndNoise = [signalAndNoise; storedValues(start:frameEnd)];
    end
end

% Calculate the power
signalPower = mean(abs(signalAndNoise).^2);
%signalAndNoisePower = mean(abs(storedValues).^2);
noisePower = mean(abs(noiseSegment).^2);
% Calculate SNRa
%snr = 10 * log10((signalPower) / noisePower); % Calculate Signal-to-Noise Ratio (SNR)
snr = 10 * log10((signalPower - noisePower) / noisePower); % Calculate Signal-to-Noise Ratio (SNR)
% display results
fprintf('Signal Power: %.2f W\n', signalPower);
fprintf('Noise Power: %.2f W\n', noisePower);
fprintf('Calculated SNR: %.2f dB\n', snr);


% relase for hardware locks
release(rx);
release(tx);