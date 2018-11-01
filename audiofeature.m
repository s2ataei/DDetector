 function audiofeature(videoDir)

videos = dir([videoDir,'*.mp4'])
for (i=1:numel(videos))
    % Read video file
    [inputAudio(:,i),Fs] = audioread(videos(:,1))
    audioFeatureMap(:,1) = PSTC(inputAudio(:,i))
    audioFeatureMap(:,2) = PSC(inputAudio(:,i))
    audioFeatureMap(:,3) = PCC(inputAudio(:,i))
end



