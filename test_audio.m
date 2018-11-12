function [prob] = test_audio(method)

% removed PART argument because unused
run([pwd, '/vlfeat/toolbox/vl_setup'])

trainVideoDir = '../Video_chunks';
testVideoDir = '/';

%% Get features

%Feature extract using METHOD instead of MFCC 
[audio_feat] = audio_feat_extract(trainVideoDir);

%Need features plus gmm of features (means, cov, priors) and then fisher
%still have not run vl_gmm or vl_fisher yet
lab = label_extract('Labels.xlsx');


%TRAINING DATA and LABELS
numClusters = 64; %idk why
for i = 1:length(audio_feat);
    tmpdata = audio_feat{1,i};
    tmpdata = tmpdata(:, sum(isnan(tmpdata),1)==0); %idk why
    [means, covariances, priors] = vl_gmm(tmpdata', numClusters);
    encoding = vl_fisher(tmpdata', means, covariances, priors');
    train_fea(i,:) = encoding';
%     train_lab(i) = lab;             %need a solution for labels !!!!!
end

%% Test Phase -  use any model already made ie 'NN' etc. with train_fea & train_lab

% THIS IS ALL THE SAME AS TEST_MFCC FROM HERE DOWN (mostly)

% TESTING DATA and LABELS
[audio_feat_test] = audio_feat_extract(testVideoDir)
test_data = audio_feat_test;
test_data = test_data(:, sum(isnan(test_data),1)==0); %idk why
[means, covariances, priors] = vl_gmm(test_data, numClusters);
encoding = vl_fisher(test_data, means, covariances, priors);
test_fea(i,:) = encoding';
test_lab(i) = lab; % don tknow what to do for lab yet

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