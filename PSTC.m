function audioFeature = PSTC(inputVideo) 

% Read video file
[inputAudio,Fs] = audioread(inputVideo)

% compute spectrogram
audioFeature = spectrogram(inputAudio(:,2)) 

% compute PSTC 
audioFeature = dct(audioFeature)

end 