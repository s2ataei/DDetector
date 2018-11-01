 function audiofeature(videoDir)

videos = dir([videoDir,'*.mp4'])

    for (i=1:numel(videos))
        % Read video file
        [inputAudio(:,i),Fs] = audioread(videos(:,1))
        audioDFT(:,i) = fft(inputAudio(:,2))

        %Calculate PCC
        pccFeature(:,i) = dct(log(abs(audioDFT(:,i))))

        %Calculate PSC
        pscFeature(:,1) = dct(abs(audioDFT(:,i)))

        % compute PSTC 
        pstcFeature(:,i) = dct(spectrogram(inputAudio(:,2)))

    end

audioFeatureMap = [pccFeature, pscFeature, pstcFeature]

end
