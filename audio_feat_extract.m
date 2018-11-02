 function [audio_feat] = audio_feat_extract(videoDir)
% reads all files in videoDir and extracts metrics from each video and
% concatenates them. Each video or video chunk will have a seperate feature
% column

%read files and extract video names to be called
file = dir([videoDir,'*.mp4']); %struct 
database = {file.name}; %cell of file names

    for (i=1:numel(database))
        % Read video file
        [inputAudio,Fs] = audioread([videoDir, database{i}]);
        
        %FFT
        audioDFT = fft(inputAudio(:,1));

        %Calculate PCC
        pccFeature(:,i) = dct(log(abs(audioDFT)));

        %Calculate PSC
%         pscFeature(:,i) = dct(abs(audioDFT));

        % compute PSTC 
%         pstcFeature(:,i) = dct(spectrogram(inputAudio(:,1)));

    end

% put feature vector into audio feat to be output by function
audio_feat = pccFeature; %, pscFeature , pstcFeature];

end
