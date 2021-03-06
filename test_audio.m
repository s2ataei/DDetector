function [prob] = test_audio(method)

% removed PART argument because unused
run([pwd, '/vlfeat/toolbox/vl_setup'])

trainVideoDir = 'G:\My Drive\MASc\Multimedia\Project\DARE-master\Video_chunks\';
testVideoDir = '/';

%% Get features

%Feature extract using METHOD instead of MFCC 
% extracted features are previously saved in a .mat file in a folder called
% newfeatures, otherwise, perform feature extraction whicfunction [prob] = test_audio(method)

% removed PART argument because unused
% added code to run vlfeat and libsvm toolboxes
% (https://github.com/cjlin1/libsvm.git)    (not working yet, don't try
% linearsvm or kernelsvm)
run([pwd, '/vlfeat/toolbox/vl_setup'])

trainVideoDir = 'G:\My Drive\MASc\Multimedia\Project\DARE-master\Video_chunks\';        % where is stored my videos, don't need if you have features already (sergiu)
testVideoDir = '/';

%% Get features

%Feature extract using METHOD instead of MFCC 
% extracted features are previously saved in a .mat file in a folder called
% newfeatures, otherwise, perform feature extraction which takes a long
% time
featureFolder = '../newfeatures/';
if exist([featureFolder 'pccFeat.mat'])
    load([featureFolder 'pccFeat.mat']);
    [audio_feat] = pscFeat;
    disp('Dater is loader');
else
    [audio_feat] = audio_feat_extract(trainVideoDir);
end

lab = label_extract('Labels.xlsx',trainVideoDir);

% Encoding DATA and LABELS
numClusters = 64; %idk why
if exist([featureFolder 'pccTrainFea.mat'])        % loading the encoded features
    load([featureFolder 'pccTrainFea.mat']);
    disp('She loaded');
else
    for i = 1:length(audio_feat)
        X = sprintf('Encoding feature %d',i);disp(X);       % added a counter to see the encoding progress
        tmpdata = audio_feat{1,i};
        tmpdata = tmpdata(:, sum(isnan(tmpdata),1)==0); %idk why
        [means, covariances, priors] = vl_gmm(tmpdata', numClusters);
        encoding = vl_fisher(tmpdata', means, covariances, priors');
        train_fea(i,:) = encoding';
        train_lab(i) = lab(i);             
    end
end
train_lab = train_lab';

%% Test Phase -  use any model already made ie 'NN' etc. with train_fea & train_lab

% THIS IS ALL THE SAME AS TEST_MFCC FROM HERE DOWN (mostly)

% TESTING DATA and LABELS
% [audio_feat_test] = audio_feat_extract(testVideoDir) % changed this to
% use features that are already extracted, testing on 1 thing for now
% (sergiu)
% this needs to be done
k = randi(numel(train_lab));
[audio_feat_test] = audio_feat{1,k};

% for i = 1:length(audio_feat_test)
    test_data = audio_feat_test;
    test_data = test_data(:, sum(isnan(test_data),1)==0); %idk why
    [means, covariances, priors] = vl_gmm(test_data', numClusters);
    encoding = vl_fisher(test_data', means, covariances, priors');
    test_fea(1,:) = encoding';
    test_lab(k) = lab(k); 
    X = sprintf('Testing clip %d. If 0 deceptive, if 1 truth, currently: %d',k,lab(k));disp(X); % added to see which clip is tested (sergiu)
% end
switch(method)
case 'NN'               % tested, works
    net = feedforwardnet(10);
    net.trainFcn = 'trainscg';
    net = configure(net, train_fea', train_lab');
    net = train(net, train_fea', train_lab');
    prob = net(test_fea');
case 'tree'             % tested, works
    tc = fitctree(train_fea, train_lab);
    [label,score,node,cnum] = predict(tc, test_fea);
    prob = score(:,1);
case 'randforest'       % tested, works
    BaggedEnsemble = TreeBagger(50,train_fea,train_lab,'OOBPred','On');
    [label,scores] = predict(BaggedEnsemble, test_fea);
    prob = scores(:,1);
case 'bayes'            % tested, doesn't work (posterior error)
    flag = bitand(var(train_fea(train_lab==1,:))>1e-10,var(train_fea(train_lab==0,:))>1e-10); %clear 0 variance features
    O1 = fitcnb(train_fea(:,flag), train_lab);
    C1 = posterior(O1, test_fea(:,flag));
    prob = C1(:,1);
case 'log'              % tested, works
    B = glmfit(train_fea, [train_lab ones(size(train_lab,1),1)], 'binomial', 'link', 'logit');
    Z = repmat(B(1), size(test_lab,1),1) + test_fea*B(2:end);
    prob = 1 ./ (1 + exp(-Z));
    prob = 1-prob;
case 'boost'            % tested, works
    ens = fitensemble(train_fea,train_lab,'AdaBoostM1',100,'Tree')
    [~, prob] = predict(ens,test_fea)
    prob = prob(:,1);
case 'linearsvm'        % tested, needs external library LIBSVM.....
    run('../libsvm-master/matlab/make');
    %model = svmtrain(train_lab, tmptrain_fea, '-t 0 -q -b 1');
    %fprintf('Finished training.\n');
    %[pred, acc, prob] = svmpredict(test_lab, tmptest_fea, model, '-q -b 1');
    %prob = prob(:,2);
    model = svmtrain(train_lab, train_fea, '-t 0 -q');
    [pred, acc, prob] = svmpredict(test_lab, test_fea, model, '-q');

    lie_id = find(prob<0);
    if ~isempty(lie_id)
        if pred(lie_id(1)) == 0
            isign = -1;
        else
            isign = 1;
        end
    else
        if pred(1) == 1
            isign = -1;
        else
            isign = 1;
        end
    end
    prob = isign*prob;
case 'kernelsvm'        % tested needs external library, LIBSVM
    ogDir = pwd;
    cd('../libsvm-master/matlab/');
    run('make');
    %model = svmtrain(train_lab, tmptrain_fea, '-t 0 -q -b 1');
    %fprintf('Finished training.\n');
    %[pred, acc, prob] = svmpredict(test_lab, tmptest_fea, model, '-q -b 1');
    %prob = prob(:,2); '-t 1 -c 1 -g 1 -q'
    model = svmtrain(train_lab, train_fea, '-t 0 -q');
    model = fitcsvm(train_fea,train_lab);
    [pred, acc, prob] = svmpredict(test_lab, test_fea, model);

    lie_id = find(prob<0);
    if ~isempty(lie_id)
        if pred(lie_id(1)) == 0
            isign = -1;
        else
            isign = 1;
        end
    else
        if pred(1) == 1
            isign = -1;
        else
            isign = 1;
        end
    end
    prob = isign*prob;
    cd(ogDir);
end


endh takes a long
% time
featureFolder = '../newfeatures/';
if exist([featureFolder 'pccFeat.mat'])
    load([featureFolder 'pccFeat.mat']);
    [audio_feat] = pccFeat;
else
    [audio_feat] = audio_feat_extract(trainVideoDir);
end

%Need features plus gmm of features (means, cov, priors) and then fisher
%still have not run vl_gmm or vl_fisher yet
lab = label_extract('Labels.xlsx',trainVideoDir);


%TRAINING DATA and LABELS
numClusters = 64; %idk why
for i = 1:length(audio_feat)
    X = sprintf('Encoding feature %d',i);       % added a counter to see the progress
    disp(X);
    tmpdata = audio_feat{1,i};
    tmpdata = tmpdata(:, sum(isnan(tmpdata),1)==0); %idk why
    [means, covariances, priors] = vl_gmm(tmpdata', numClusters);
    encoding = vl_fisher(tmpdata', means, covariances, priors');
    train_fea(i,:) = encoding';
    train_lab(i) = lab(i);             
end

%% Test Phase -  use any model already made ie 'NN' etc. with train_fea & train_lab

% THIS IS ALL THE SAME AS TEST_MFCC FROM HERE DOWN (mostly)

% TESTING DATA and LABELS
% [audio_feat_test] = audio_feat_extract(testVideoDir) % changed this to
% use features that are already extracted, testing on first 5 chunks
[audio_feat_test] = audio_feat{1,1:2};

for i = 1:length(audio_feat_test)
    test_data = audio_feat_test{1,i};
    test_data = test_data(:, sum(isnan(test_data),1)==0); %idk why
    [means, covariances, priors] = vl_gmm(test_data', numClusters);
    encoding = vl_fisher(test_data', means, covariances, priors');
    test_fea(i,:) = encoding';
    test_lab(i) = lab(i); 
end
switch(method)
case 'NN'
    net = feedforwardnet(10);
    net.trainFcn = 'trainscg';
    net = configure(net, train_fea', train_lab');
    net = train(net, train_fea', train_lab');
    prob = net(test_fea');
case 'tree'
    tc = fitctree(train_fea, train_lab);
    [label,score,node,cnum] = predict(tc, test_fea);
    prob = score(:,1);
case 'randforest'
    BaggedEnsemble = TreeBagger(50,train_fea,train_lab,'OOBPred','On');
    [label,scores] = predict(BaggedEnsemble, test_fea);
    prob = scores(:,1);
case 'bayes'
    flag = bitand(var(train_fea(train_lab==1,:))>1e-10,var(train_fea(train_lab==0,:))>1e-10); %clear 0 variance features
    O1 = fitNaiveBayes(train_fea(:,flag), train_lab);
    C1 = posterior(O1, test_fea(:,flag));
    prob = C1(:,1);
case 'log'
    B = glmfit(train_fea, [train_lab ones(size(train_lab,1),1)], 'binomial', 'link', 'logit');
    Z = repmat(B(1), size(test_lab,1),1) + test_fea*B(2:end);
    prob = 1 ./ (1 + exp(-Z));
    prob = 1-prob;
case 'boost'
    ens = fitensemble(train_fea,train_lab,'AdaBoostM1',100,'Tree')
    [~, prob] = predict(ens,test_fea)
    prob = prob(:,1);
case 'linearsvm'
    %model = svmtrain(train_lab, tmptrain_fea, '-t 0 -q -b 1');
    %fprintf('Finished training.\n');
    %[pred, acc, prob] = svmpredict(test_lab, tmptest_fea, model, '-q -b 1');
    %prob = prob(:,2);
    model = svmtrain(train_lab, train_fea, '-t 0 -q');
    [pred, acc, prob] = svmpredict(test_lab, test_fea, model, '-q');

    lie_id = find(prob<0);
    if ~isempty(lie_id)
        if pred(lie_id(1)) == 0
            isign = -1;
        else
            isign = 1;
        end
    else
        if pred(1) == 1
            isign = -1;
        else
            isign = 1;
        end
    end
    prob = isign*prob;
case 'kernelsvm'
    %model = svmtrain(train_lab, tmptrain_fea, '-t 0 -q -b 1');
    %fprintf('Finished training.\n');
    %[pred, acc, prob] = svmpredict(test_lab, tmptest_fea, model, '-q -b 1');
    %prob = prob(:,2);
    model = svmtrain(train_lab, train_fea, '-t 1 -c 1 -g 1 -q');
    [pred, acc, prob] = svmpredict(test_lab, test_fea, model, '-q');

    lie_id = find(prob<0);
    if ~isempty(lie_id)
        if pred(lie_id(1)) == 0
            isign = -1;
        else
            isign = 1;
        end
    else
        if pred(1) == 1
            isign = -1;
        else
            isign = 1;
        end
    end
    prob = isign*prob;
end


end