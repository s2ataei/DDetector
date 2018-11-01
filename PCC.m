function audioFeature = PCC(inputVideo)
%Calculates PSC audio feature

% Read video file
[inputAudio,Fs] = audioread(inputVideo)

%Calculate DFT of audio
audioFeature = fft(inputAudio(:,2))

%Calculate PCC
audioFeature = dct(log(abs(audioFeature)))

end

