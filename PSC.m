function audioFeature = PSC(inputVideo)
%Calculates PSC audio feature

% Read video file
[inputAudio,Fs] = audioread(inputVideo)

%Calculate DFT of audio
audioFeature = fft(inputAudio(:,2))

%Calculate PSC
audioFeature = dct(abs(audioFeature))

end

