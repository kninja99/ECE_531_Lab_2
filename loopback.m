% Setup Receiver
% samplers per frame changes from 2^15 to 10000 to match sinewave
rx=sdrrx('Pluto','OutputDataType','double','SamplesPerFrame',2^15);
%rx.SamplesPerFrame = 3660;
% adjust gains source
% Manual gains source
rx.GainSource ="Manual";
rx.Gain = 30;
% slow attack gains source
%rx.GainSource = "AGC Slow Attack"
% Fast attack gain source
% Slow attack gain source
%rx.GainSource = "AGC Fast Attack";
% Setup Transmitter
tx = sdrtx('Pluto','Gain',-30);
% Transmit sinewave (adjusted samples per frame to fit 300hz) aka phase
% alinement for a continuous waveform
% (F /Fs) * Steps
% Original value was 2^13, introduced spwectual leakage
samplesPerFrame = round(rx.BasebandSampleRate / 300) * 300;
sine = dsp.SineWave('Frequency',300,...
                    'SampleRate',rx.BasebandSampleRate,...
                    'SamplesPerFrame', samplesPerFrame,...
                    'ComplexOutput', true, ...
                    'Amplitude',1);
tx.transmitRepeat(sine()); % Transmit continuously
% Setup Scope
samplesPerStep = rx.SamplesPerFrame/rx.BasebandSampleRate;
steps = 3;
ts = timescope('SampleRate', rx.BasebandSampleRate,...
                   'TimeSpan', samplesPerStep*steps,...
                   'BufferLength', rx.SamplesPerFrame*steps);
% Receive and view sine
for k=1:steps
  ts(rx());
end
% relase for hardware locks
release(rx);
release(tx);