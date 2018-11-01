function audioFeature = PSTC(inputVideo) 
%Computes PSTC audio feature

% compute spectrogram
audioFeature = spectrogram(inputAudio(:,2)) 

% compute PSTC 
audioFeature = dct(audioFeature)

end 