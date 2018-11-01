function audioFeature = PCC(inputVideo)
%Calculates PSC audio feature

%Calculate DFT of audio
audioFeature = fft(inputAudio(:,2))

%Calculate PCC
audioFeature = dct(log(abs(audioFeature)))

end

