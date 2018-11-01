function audioFeature = PSC(inputVideo)
%Calculates PSC audio feature

%Calculate DFT of audio
audioFeature = fft(inputAudio(:,2))

%Calculate PSC
audioFeature = dct(abs(audioFeature))

end

