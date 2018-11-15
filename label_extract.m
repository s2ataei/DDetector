function labels = label_extract(labelDir, videoDir)
    [num,text,raw] = xlsread(labelDir);
    vids = dir([videoDir,'*.mp4']);
    labs = zeros(size(raw,1)-1,1);
    for i = 2:size(raw,1)
        if contains(raw{i,41},'deceptive')
            labs(i,1) = 0;
        else
            labs(i,1) = 1;
        end
    end
    labels = zeros(size(vids,1),1);
    for i = 1:size(vids,1)
        for j = 2:size(text,1)
            if contains(text{j,1}(11:13),vids(i).name(11:13))
                labels(i,1)=labs(j,1);
            end
        end
    end

end