 function [out,S] = run_cosmo_machine(cos,S)
% multivariate classification between two groups
% using linear discriminant analysis
dbstop if error

cos.samples=round(cos.samples,S.ndec);
rm=all(isnan(cos.samples),1) | all(diff(cos.samples)==0); % remove nans and constants
cos.samples(:,rm)=[];
cos.fa.chan(rm)=[];
cos.fa.time(rm)=[];

if isempty(cos.samples)
    out.empty=1;
    return
end

% balance trials
if S.balance_dataset_and_partitions
    if isempty(S.balance_idx)
        [cos,S.balance_idx,classes]=cosmo_balance_dataset(cos);
    else
        idx = (S.balance_idx(:));
        cos.sa.trialinfo = cos.sa.trialinfo(idx,:);
        cos.sa.targets = cos.sa.targets(idx);
        cos.sa.chunks = cos.sa.chunks(idx);
        cos.samples = cos.samples(idx,:);
    end
else
    S.balance_idx=[];
end

% get rid of features with at least one NaN value across samples
fa_nan_mask=sum(isnan(cos.samples),1)>0;
fprintf('%d / %d features have NaN\n', ...
            sum(fa_nan_mask), numel(fa_nan_mask));
cos=cosmo_slice(cos, ~fa_nan_mask, 2);

% balance targets over chunks
if strcmp(S.use_chunks,'balance_targets') 
    cos.sa.chunks=cosmo_chunkize(cos,S.nchunks);
end

% just to check everything is ok before analysis
%cosmo_check_dataset(cos);
fprintf('The input has feature dimensions %s\n', ...
        cosmo_strjoin(cos.a.fdim.labels,', '));
    
% Set partition scheme. odd_even is fast; for publication-quality analysis
% nfold_partitioner is recommended.
% Alternatives are:
% - cosmo_nfold_partitioner    (take-one-chunk-out crossvalidation)
% - cosmo_nchoosek_partitioner (take-K-chunks-out  "             ").
if strcmp(S.parti,'take-one-out')
    % do a take-one-fold out cross validation.
    % except when using a splithalf correlation measure it is important that
    % the partitions are *balanced*, i.e. each target (or class) is presented
    % equally often in each chunk
    partitions=cosmo_nchoosek_partitioner(cos,1);
    if S.balance_dataset_and_partitions
        partitions=cosmo_balance_partitions(partitions, cos);
    end
elseif strcmp(S.parti,'splithalf')
    % split-half, if there are just two chunks
    % (when using a classifier, do not use 'half' but the number of chunks to
    % leave out for testing, e.g. 1).
    partitions= cosmo_nchoosek_partitioner(cos,'half');
    partitions=cosmo_balance_partitions(partitions, cos);
elseif strcmp(S.parti,'oddeven')
    partitions = cosmo_oddeven_partitioner(cos);
    partitions=cosmo_balance_partitions(partitions, cos);
elseif strcmp(S.parti,'nchunks')
    partitions=cosmo_nfold_partitioner(cos);
    if S.balance_dataset_and_partitions
        partitions=cosmo_balance_partitions(partitions, cos);
    end
end

npartitions=numel(partitions);
fprintf('There are %d partitions\n', numel(partitions.train_indices));
fprintf('# train samples:%s\n', sprintf(' %d', cellfun(@numel, ...
                                        partitions.train_indices)));
fprintf('# test samples:%s\n', sprintf(' %d', cellfun(@numel, ...
                                        partitions.test_indices)));
                                    
measure_args=struct();
if strcmp(S.use_measure,'crossvalidation')
    % Use the cosmo_cross_validation_measure and set its parameters
    % (classifier and partitions) in a measure_args struct.
    measure = @cosmo_crossvalidation_measure_CAB;
    %try
        measure_args.average_train_count = S.average_train_count; 
        measure_args.average_train_resamplings =S.average_train_resamplings;
    %end
    measure_args.priors = []; % leave blank to calculate from data
    if ~S.balance_dataset_and_partitions
        measure_args.check_partitions=0;
        %average_train_count = 1; % average over this many trials
        %average_train_resamplings = 1; % reuse trials this many times
    end
    %measure_args.priors = [sum(ti(:,1)==1),sum(ti(:,1)==2)];
elseif strcmp(S.use_measure,'correlation')

    %% measure: correlation
    % for illustration purposes use the split-half measure because it is
    % relatively fast - but clasifiers can also be used
    measure=@cosmo_correlation_measure;
    measure_args.corr_type='Spearman';
end

%if |isfield
if strcmp(S.use_classifier,'LDA')
    % Define which classifier to use, using a function handle.
    % Alternatives are @cosmo_classify_{svm,matlabsvm,libsvm,nn,naive_bayes}
    measure_args.matlab_lda = S.matlab_lda;
    measure_args.logist = S.logist;
    measure_args.classifier = @cosmo_classify_lda_CAB;
    measure_args.regularization =S.regularization;
    measure_args.output_weights = S.output_weights;
elseif strcmp(S.use_classifier,'GP')
    measure_args.classifier=@cosmo_gpml_CAB;
elseif strcmp(S.use_classifier,'Bayes')
    measure_args.classifier=@cosmo_classify_naive_bayes;
elseif strcmp(S.use_classifier,'SVM')
    measure_args.classifier=@cosmo_classify_svm;
end
measure_args.partitions=partitions;

if S.search_radius==Inf
    
    % get predictions for each fold
    %[pred,accuracy]=cosmo_crossvalidate(cos, measure_args.classifier, measure_args.partitions);
    %cosmo_crossvalidation_measure_CAB;
    out=measure(cos, measure_args);
    %out.accuracy=accuracy;
    %out.predictions=pred;
else
    % print measure and arguments
    fprintf('Measure:\n');
    cosmo_disp(measure);
    fprintf('Measure arguments:\n');
    cosmo_disp(measure_args);

    % define neighborhood
    time_nbrhood=cosmo_interval_neighborhood(cos,'time',...
                                            'radius',S.search_radius);

    if strcmp(S.SL_type,'time')
        nbrhood=time_nbrhood;
        nbrhood_nfeatures=cellfun(@numel,nbrhood.neighbors);
        center_ids=find(nbrhood_nfeatures>0);
    elseif strcmp(S.SL_type,'time_chan')

        % define the neighborhood for channels
        cfg.senstype ='EEG';
        cfg.method = 'triangulation';
        cfg.elecfile=S.cfglayout;
        cfg.layout=S.cfgoutput;
        ft_nbrs = ft_prepare_neighbours(cfg);
        chan_nbrhood=cosmo_meeg_chan_neighborhood(cos, ft_nbrs);

        % cross neighborhoods for chan-time searchlight
        nbrhood=cosmo_cross_neighborhood(cos,{chan_nbrhood,...
                                            time_nbrhood});
        % print some info
        nbrhood_nfeatures=cellfun(@numel,nbrhood.neighbors);
        fprintf('Features have on average %.1f +/- %.1f neighbors\n', ...
                    mean(nbrhood_nfeatures), std(nbrhood_nfeatures));

        % only keep features with at least 10 neighbors
        center_ids=find(nbrhood_nfeatures>10);
    end


    % run the searchlight using the measure, measure arguments, and
    % neighborhood defined above.
    % Note that while the input has both 'chan' and 'time' as feature
    % dimensions, the output only has 'time' as the feature dimension

    out=cosmo_searchlight_CAB(cos,nbrhood,measure,measure_args,...
                                              'center_ids',center_ids);
end
% % get confusion matrix for each fold
% confusion_matrix_folds=cosmo_confusion_matrix(ds.sa.targets,pred);
% 
% % sum confusion for each ground-truth target and prediction,
% % resulting in an nclasses x nclasses matrix
% confusion_matrix=sum(confusion_matrix_folds,3);
% figure
% imagesc(confusion_matrix,[0 10])
% cfy_label=underscore2space(func2str(classifier));
% title_=sprintf('%s using %s: accuracy=%.3f', ...
%                 underscore2space(mask_label), cfy_label, accuracy);
% title(title_)
% set(gca,'XTick',1:nlabels,'XTickLabel',labels);
% set(gca,'YTick',1:nlabels,'YTickLabel',labels);
% ylabel('target');
% xlabel('predicted');