function CORE_eeg_trial_regression_statistics_condor
% Analysis script for Encoding and Decoding models
% This is a general script that can be tailored to specific analyses

% Encoding performs various forms of regression over trials (with or without cross-validation)
% The regression models for encoding can also be used to either generate corrected
% p-values (for cases where the tests are intended to be inferential) or to create cross-validated 
% parameter estimates.

% Encoding options:
% 1. Spearman correlation (SC) (with FDR and/or TFCE correction) - robust
% to outliers. TFCE only supports time (not chan) clustering presently.
% 2. linear multiple regression (MR) (with FDR and/or TFCE correction) -
% not robust to outliers, not robust to collinearity. TFCE only supports time (not chan) clustering presently.
% 3. non-hierarchical Bayesian linear regression: Parametric Empirical Bayes
% (PEB). This is used to obtain estimates of Log Model Evidence (LME) for model comparison, rather
% than for inferential tests against a null hypothesis.
% 4. Ridge regression (RR) for multiple collinear predictors. Includes
% cross-validation to select optimal lambda (penalisation). Only needed if
% there are a number of predictors in the model.
% 5. Bayesian regularised regression (BRR) with priors including Ridge and
% LASSO, useful for grouping together potentially collinear predictors,
% plus allows use of non-Gaussian distributions for robustness to outliers.
% Does not require cross-validation to optimise regularisation, but can
% test for predictive accuracy on test data if desired. Also outputs WAIC
% for model comparison.
% For info on BRR priors: 
% https://www4.stat.ncsu.edu/~reich/ABA/notes/BLR.pdf
% https://projecteuclid.org/download/pdfview_1/euclid.ba/1378729924

% Decoding options:
% 1. BIEM: Bayesian inverted encoding model. Inverts the encoding model and cross-validates on test data. Currently implements the model published here:
    % Schoenmakers, S., Barth, M., Heskes, T., & van Gerven, M. (2013). Linear 
    % reconstruction of perceived images from human brain activity. NeuroImage,
    % 83, 951-961.
% 2. MVPA: Implements Gaussian Process Regression (GPR). 

% Input data can be epoched EEG .set files or .mat files with corresponding
% trial info files. Data can also be EEG or ICA components
% Predictor variables are RTs or HGF-estimated belief and prediction error
% trajectories.

close all
dbstop if error % optional instruction to stop at a breakpoint if there is an error - useful for debugging
restoredefaultpath

% condor settings - if on, input files are saved for Condor, but stats not
% run yet
S.condor.on = 1;
S.condor.chunksize = 2500; % max value: auto re-adjusts into equal portions

%- use parallel processing
S.parallel=0;


%% SET PATHS
S.path=struct;% clears the field
S.path.hgf = 'C:\Data\CORE\behaviour\hgf\fitted'; 
S.file.hgf = 'D_fit_r1_it5_pm3_rm4.mat';
S.file.get_dt = 'CORE_fittedparameters_percmodel2_respmodel4_fractrain0_20190211T074650.mat';
% S.path.hgf = 'C:\Data\CORE\behaviour\hgf\fitted\CORE_fittedparameters_percmodel3_bayesopt_20190112T075922.mat';

% S.path.main = 'C:\Data\CORE\eeg\ana';
% S.path.eeg = [S.path.main '\prep\cleaned\part2'];
% S.path.stats = [S.path.main '\stats']; % folder to save outputs
% S.path.datfile = 'C:\Data\CORE\Participants\Participant_data.xlsx'; % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
% S.path.chanlocs = 'C:\Data\CORE\eeg\ana\prep\chanlocs.mat';
% S.path.GSNlocs = 'C:\Data\CORE\eeg\GSN-HydroCel-128-Flipmap.mat';
% S.fname.parts = {'subject','suffix','ext'}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
% S.fname.ext = {'set'}; 
% S.select.subjects = {}; % either a single subject, or leave blank to process all subjects in folder
% S.select.sessions = {};
% S.select.blocks = {}; % blocks to load (each a separate file) - empty means all of them, or not defined
% S.select.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
% S.load.suffixes = {'2_merged_cleaned'}; 
% save(fullfile(S.path.main,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% SET DATA PATHS/NAMES: ICs
% clear S
% S.path=struct;% clears the field
% S.path.main = 'C:\Data\CORE\eeg\ana';
% S.path.eeg = [S.path.main '\groupICA\test'];
% S.path.stats = [S.path.main '\stats']; % folder to save outputs
% S.path.hgf = ['C:\Data\CORE\behaviour\hgf\fitted\First draft\CORE_fittedparameters_percmodel6_respmodel3_20180710T131802.mat']; 
% S.path.design = ['C:\Data\CORE\design']; % 
% S.path.datfile = 'C:\Data\CORE\Participants\Participant_data.xlsx'; % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
% S.fname.parts = {'subject','suffix','ext'}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
% S.fname.ext = {'mat'}; 
% S.select.subjects = {}; % either a single subject, or leave blank to process all subjects in folder
% S.select.sessions = {};
% S.select.blocks = {}; % blocks to load (each a separate file) - empty means all of them, or not defined
% S.select.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
% S.load.suffixes = {'2_merged_cleaned_grp-ica_c', '2_merged_cleaned_grp-fileinfo_'}; 
% save(fullfile(S.path.main,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% SET DATA PATHS/NAMES: Residuals
% S.path.main = 'C:\Data\CORE\eeg\ana';
% S.path.stats = [S.path.main '\stats']; % folder to save outputs
% S.path.eeg = [S.path.stats '\residuals'];
% S.path.design = ['C:\Data\CORE\design']; % 
% S.path.datfile = 'C:\Data\CORE\Participants\Participant_data.xlsx'; % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
% S.path.chanlocs = 'C:\Data\CORE\eeg\ana\prep\chanlocs.mat';
% S.fname.parts = {'subject','suffix','ext'}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
% S.fname.ext = {'mat'}; 
% S.select.subjects = {}; % either a single subject, or leave blank to process all subjects in folder
% S.select.sessions = {};
% S.select.blocks = {}; % blocks to load (each a separate file) - empty means all of them, or not defined
% S.select.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
% S.load.suffixes = {'2_merged_cleaned_resid_comp1_con1_20190131T065454'}; 
% save(fullfile(S.path.main,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% CONDOR PATHS
if S.condor.on 
    
    pth='/condor_data/cab79/CORE_EEG_stats/';
    S.path.main = pth;
    S.path.data = fullfile(pth, 'Data');
    S.path.hgf = S.path.data; 
    S.path.eeg = S.path.data;
    S.path.stats = pwd; %
    S.path.datfile = fullfile(S.path.data,'Participant_data.xlsx'); % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
    S.path.chanlocs = fullfile(S.path.data,'chanlocs.mat');
    S.path.GSNlocs = fullfile(S.path.data,'GSN-HydroCel-128-Flipmap.mat');
    S.fname.parts = {'subject','suffix','ext'}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
    S.select.subjects = {}; % either a single subject, or leave blank to process all subjects in folder
    S.select.sessions = {};
    S.select.blocks = {}; % blocks to load (each a separate file) - empty means all of them, or not defined
    S.select.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
    save(fullfile(S.path.data,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable
    
    % ERP
%     S.load.suffixes = {'2_merged_cleaned'}; 
%     S.fname.ext = {'set'}; 
    
    % FREQ
    S.load.suffixes = {'2_merged_cleaned_TF'}; 
    S.fname.ext = {'mat'};
    S.select.freq = 1; 
    
    delete('input*.mat');
    delete('output*.mat');
    delete('*.out');
    delete('*.log');
    delete('*.err');
end


%% add toolbox paths
if ~S.condor.on 
    run('C:\Data\Matlab\Matlab_files\CORE\CORE_addpaths')
else
    addpath(genpath(fullfile(S.path.main, 'dependencies_supp')))
    addpath(genpath(fullfile(S.path.main, 'Data')))
end

%%
% layouts for cosmo
S.cfglayout = 'C:\Data\Matlab\Matlab_files\CORE\cosmo\modified functions\GSN92.sfp';
S.cfgoutput = 'C:\Data\Matlab\Matlab_files\CORE\cosmo\modified functions\GSN92.lay';

% DATA TYPE (in order of speed)
% multicomp: all ICs considered as a group in a single multivariate analysis
% all_chan or recon: all ICs reconstructed into one set of channels; channels considered in a single multivariate analysis
% comp or chan: each IC or chan timecourse considered in separate analyses or as GFP
% comp_recon: each IC reconstructed into channels separately; each set of channels considered in a separate multivariate analyses
S.data_type='all_chan';

%S.data_form = {'GFP','alldata'};
S.data_form = {'alldata'};

% ENCODING ANALYSIS TYPE (see options at the top) - leave empty for MVPA
S.analysis_type='BRR'; 

S.cond_idx = {
    [1 2 9 10 17 18] %left hand, mismatch
    [3 4 11 12 19 20] %left hand, standard
    [5 6 13 14 21 22] %right hand, mismatch
    [7 8 15 16 23 24]
    }; %right hand, standard

% which rows to subtract? (second cell must contain meaned data)
%S.row_subtract = {[1 3],[2 4]}; % mismatch trials minus mean of standards
%S.row_subtract = {}; % mismatch trials minus mean of standards

% rows of cond_idx to contrast
S.contrast_rows = {}; % empty - all pooled into one (e.g. for regression)
%S.contrast_rows = {[1 3],[2 4]}; % e.g. fixed effects analysis
%S.contrast_rows = {[1 3]}; % include mismatch only (e.g. if correlating with RT)
%S.contrast_rows = {[1 3],[1:4]}; % training and testing
%S.contrast_rows = {[1:4]}; % include all (e.g. correlating with HGF traj)
%S.contrast_rows = {[1:4],[1:4]}; % include all (e.g. correlating with HGF traj) and test on all


if strfind(S.path.eeg,'residuals')
    % other EEG data operations: residuals
    S.flipchan = []; % rows of S.cond_idx containing trial types to flip channels right to left 
    S.total_samples = 0:20:600; %residuals
    S.select_samples = 0:600;
    S.smooth_samples = 0;
    S.dsample = 0;
    S.zscore = 1;
    S.ndec=8; % trim data to a number of decimal places
    
    % Multiple regression settings
    S.save_residuals=0;
elseif isfield(S.select,'freq')
    % other EEG data operations
    S.flipchan = [3 4]; % rows of S.cond_idx containing trial types to flip channels right to left 
    S.total_samples = -200:8:792;
    S.select_samples = 0:799;
    S.smooth_samples = 10;
    S.dsample = 0;
    S.zscore = 1;
    S.ndec=8; % trim data to a number of decimal places
    
    % Multiple regression settings
    S.save_residuals=0;
else
    % other EEG data operations
    S.flipchan = [3 4]; % rows of S.cond_idx containing trial types to flip channels right to left 
    S.total_samples = -200:799;
    S.select_samples = 0:799;
    S.smooth_samples = 10;
    S.dsample = 4;
    S.zscore = 1;
    S.ndec=8; % trim data to a number of decimal places
    
    % Multiple regression settings
    S.save_residuals=0;
end

% transforms
S.transform = 'notrans'; % EEG transform: arcsinh or notrans
S.pred_transform = 'arcsinh'; % Predictor transform: arcsinh, rank or notrans

% run options
% for testing decoders: random, 0.5 fraction, balanced, 10 runs.
S.traintest = 'random'; % method to split data into training and testing. options: 'random' selection of trials (S.trainfrac must be >0); 'cond': select by condition
S.trainfrac = 1; % fraction of trials to use as training data (taken at random). Remainder used for testing. E.g. training for encoding vs. testing for decoding. Or, MPVA training vs. MVPA testing.
S.balance_conds =1; % random training trials balanced across conditions
S.num_runs = 1; % run analysis this many times, each time with a different random choice of training/test data

% Predictor variables
S.pred_type = {'HGF'}; % null, cond, RT or HGF
S.pred_type_traintest = {'train'}; % 'train' or 'test' for each pred_type. 'train' also performs testing if set by S.traintest.
%S.pred_type = {'cond'}; % cond, RT or HGF
% if S.pred_type='cond':

% S.cond = {[2 4],[1 3]};
S.cond = {[1 3]};

% if S.pred_type = 'HGF': HGF trajectories, grouped
%S.traj{1} = {
    %{'PL'},{'epsi'},{[0]},{[1:3]}; %3rd col: absolute values; 
    %{'PL'},{'da','dau','psi','epsi'},{[0 0 0 0]},{[],[],[],[]}; %3rd col: 1=abs, 2=rect; 4th col: levels (empty=all)
    %{'PR'},{'da','dau','psi','epsi'};
%    }; % prediction errors, updates and learning rates
 S.traj{1} = {
%     {'PL'},{'dau'},{[0]},{[]};
%     {'PL'},{'da'},{[0]},{[1]};
%     {'PL'},{'da'},{[0]},{[2]};
%       {'PL'},{'epsi'},{[0]},{[1]};
%      {'PL'},{'epsi'},{[0]},{[2]};
%      {'PL'},{'epsi'},{[0]},{[3]};
%      {'PL'},{'epsi'},{[1]},{[1]};
%      {'PL'},{'epsi'},{[1]},{[2]};
%      {'PL'},{'epsi'},{[1]},{[3]};
%      {'PL'},{'dau','da'},{[0,0]},{[],[1:2]};
%      {'PL'},{'epsi'},{[0]},{[]};
%     {'PL'},{'ud'},{[0]},{[1]};
%     {'PL'},{'ud'},{[0]},{[2]};
%     {'PL'},{'ud'},{[0]},{[3]};
%     {'PL'},{'mu'},{[0]},{[]};
     {'PL'},{'dau','da','epsi'},{[0,0,0]},{[],[1:2],[]};
%      {'PL'},{'dau','da','epsi','mu','sa','ud'},{[0,0,0,0,0,0]},{[],[1:2],[],[],[],[]};
     }; % beliefs and their variance
% S.traj{2} = {
%     {'PL'},{'da','dau','ud','psi','epsi','wt'};
%     {'PR'},{'da','dau','ud','psi','epsi','wt'};
%     }; % prediction errors, updates and learning rates

% TFCE settings
S.tfce_on = 0; % for clustering over time only
S.cosmo_tfce_on = 0; % use cosmo if analysing clusters over channels/frequencies (+/- time). NB Cosmo does NOT implement regression/ccrrelation.
%S.tfce_test = S.analysis_type; % set to SC or MR above
S.tfce_tail = 2;
S.tfce_nperm=100; % for initial testing, between 100 and 1000. 5000 is most robust, but slow

% Ridge regression settings
S.rr.df_num = 100; % number of lambdas to do cross-val on
S.rr.folds = 5; % number of folds in the traindata for cross-validation
S.rr.z = 1; % determines which method to use. Either 1 or 0.
S.rr.sigma=0; % save sigma? RESULTS IN LARGE MATRICES AND MEMORY PROBLEMS

% Bayesian regularised regression (BRR) settings
S.brr.folds = 0;            % number of folds in the traindata. Set to 0 to not conduct predictive cross-validation.
S.brr.model = 't';   % error distribution - string, one of {'gaussian','laplace','t','binomial'}
S.brr.prior = 'ridge';        %- string, one of {'g','ridge','lasso','horseshoe','horseshoe+'}
S.brr.nsamples = 100;   %- number of posterior MCMC samples (Default: 1000)  
S.brr.burnin = 100;     %- number of burnin MCMC samples (Default: 1000)
S.brr.thin = 5;       %- level of thinning (Default: 5)
S.brr.catvars = find(strcmp(S.pred_type,'cond'));    %- vector of variables (as column numbers of X) to treat
%                       as categorical variables, with appropriate expansion. 
%                       See examples\br_example5 (Default: none)
S.brr.nogrouping = false; %- stop automatic grouping of categorical predictors
%                       that is enabled with the 'catvars' options. (Default: false)
S.brr.usegroups = 0;     % ****Specified by S.traj cells**** - create groups of predictors. Grouping of variables
%                       works only with HS, HS+ and lasso prior
%                       distributions. The same variable can appear in
%                       multiple groups. See examples\br_example[9,10,11,12]  (Default: { [] } )  
S.brr.waic = true;       %- whether to calculate the WAIC -- disabling can lead
%                       to large speed-ups, especially for Gaussian models with large n
%                       (default: true)

% %BIEM settings
S.biem_on=0;
S.biem_prior = 'subject_training'; % options: 'group_training', 'subject_training', 'uniform'
S.biem_groupweights = '';%'stats_grp_MR_all_chan_cond_arcsinh_20180804T144006.mat'; % repeat of MR mismatch, with decoding';%'stats_grp_RR_all_chan_RT_arcsinh_20180802T130052.mat'; % file containing beta and sigma values from a previous encoding run, group averaged.
S.biem_pred = 1; % specify which predictor variable(s) to correlate with input

% MVPA settings: regression
% S.mvpa_on=1;
% S.mvpa_type='regress'; %'class' or 'regress'
% S.SL_type = 'time';
% S.search_radius = Inf; % data points, not ms.  Set to Inf to analyse all data points at once.
% S.use_measure = 'crossvalidation';
% S.balance_dataset_and_partitions =0; % turn on for classification, off for regression
% S.parti='take-one-out'; % 'take-one-out', 'splithalf', 'oddeven', 'nchunks'
% S.use_classifier = 'GP'; 
% S.use_chunks = 'none'; % 'balance_targets' (over chunks) or 'none'. Not needed for 'take-one-out' option.
% S.nchunks=0;
% S.average_train_count = 1;
% S.average_train_resamplings = 1;

% MVPA settings: classification
S.mvpa_on=0;
S.mvpa_type='regress'; %'class' or 'regress'
S.SL_type = 'time';
S.search_radius = 25; % data points, not ms.  Set to Inf to analyse all data points at once.
S.use_measure = 'crossvalidation';
S.balance_dataset_and_partitions =0; % turn on for classification, off for regression
S.parti='take-one-out'; % 'take-one-out' (for regression), 'splithalf', 'oddeven', 'nchunks' (for classification)
S.use_classifier = 'GP'; 
S.use_chunks = 'none'; % 'balance_targets' (over chunks) or 'none'. Not needed for 'take-one-out' option.
S.nchunks=0; % for classification, 10 chunks; for regression, 0.
S.average_train_count = 1;
S.average_train_resamplings = 1;

% savename
S.sname=datestr(now,30);

% subject-level statistics (over trials)
[S,D,stats] = CORE_eeg_trial_statistics(S);

if 0
%plot SC
figure;imagesc(stats.spear.GFP(con).fdr_masked);
figure;imagesc(sum(stats.spear.alldata(con).fdr_masked,3));
% plot RR
imagesc(stats.RR.gfp.b{1, 1});
imagesc(squeeze(mean(stats.RR.alldata.b{1, 1},1)));

load('stats_MVPA_all_chan_cond_arcsinh_20180815T124954.mat'); mvpastats=stats;
load('stats_MVPA_all_chan_condRT_arcsinh_20180815T141558.mat'); mvpastats2=stats;
load('stats_RR_all_chan_RT_arcsinh_20180730T174602.mat'); biemstats=stats;
load('stats_BRR_all_chan_RT_arcsinh_20180802T073556.mat'); biemBRRstats=stats;
load('stats_RR_all_chan_RT_arcsinh_20180802T151948.mat'); biemflipstats=stats; 
load('stats_MR_all_chan_RT_arcsinh_20180803T153041.mat'); biemMRstats=stats; 
load('stats_MR_all_chan_condRT_arcsinh_20180815T155650.mat'); biemMRstats2=stats; 

% plot MVPA predictions
figure; hold on
ds = size(mvpastats.mvpa.alldata);
x=mean(reshape([mvpastats.mvpa.alldata.testdata_corr],ds(1),ds(2)),2);
y=mean(reshape([mvpastats.mvpa.alldata.samples],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('test data predictive accuracy'); 
ylabel('training data predictive accuracy');

% plot MVPA vs. MVPA2 using transweights
figure; hold on
ds = size(mvpastats.mvpa.alldata);
x=mean(reshape([mvpastats.mvpa.alldata.testdata_corrtrans],ds(1),ds(2)),2);
ds = size(mvpastats2.mvpa.alldata);
y=mean(reshape([mvpastats2.mvpa.alldata.testdata_corrtrans],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MVPA test data predictive accuracy'); 
ylabel('MVPA2 test data predictive accuracy');

% plot MVPA weight vs. transweight predictions
figure; hold on
ds = size(mvpastats.mvpa.alldata);
x=mean(reshape([mvpastats.mvpa.alldata.testdata_corr],ds(1),ds(2)),2);
y=mean(reshape([mvpastats.mvpa.alldata.testdata_corrtrans],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MVPA weights test data predictive accuracy'); 
ylabel('MVPA transweights test data predictive accuracy');

% plot MVPA predictions vs. BIEM MR
figure; hold on
ds = size(mvpastats2.mvpa.alldata);
x=mean(reshape([mvpastats2.mvpa.alldata.testdata_corrtrans],ds(1),ds(2)),2);
ds = size(biemMRstats2.biem.alldata.rho);
y=mean(reshape([biemMRstats2.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MVPA test data predictive accuracy'); 
ylabel('BIEM MR test data predictive accuracy');

% plot BIEM RR vs. BIEM BRR 
figure; hold on
ds = size(biemBRRstats.biem.alldata.rho);
x=mean(reshape([biemBRRstats.biem.alldata.rho],ds(1),ds(2)),2);
ds = size(biemstats.biem.alldata.rho);
y=mean(reshape([biemstats.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('BIEM BRR test data predictive accuracy'); 
ylabel('BIEM RR test data predictive accuracy');

% plot BIEM MR vs. BIEM BRR 
figure; hold on
ds = size(biemBRRstats.biem.alldata.rho);
x=mean(reshape([biemBRRstats.biem.alldata.rho],ds(1),ds(2)),2);
ds = size(biemMRstats.biem.alldata.rho);
y=mean(reshape([biemMRstats.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('BIEM BRR test data predictive accuracy'); 
ylabel('BIEM MR test data predictive accuracy');

% plot BIEM RR vs. BIEM RR flip
figure; hold on
ds = size(biemflipstats.biem.alldata.rho);
x=mean(reshape([biemflipstats.biem.alldata.rho],ds(1),ds(2)),2);
ds = size(biemstats.biem.alldata.rho);
y=mean(reshape([biemstats.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('BIEM RR flip test data predictive accuracy'); 
ylabel('BIEM RR test data predictive accuracy');

% plot BIEM subject vs. group weight predictions
figure; hold on
ds = size(biemflipstats.biem.alldata.grprho);
x=mean(reshape([biemflipstats.biem.alldata.grprho],ds(1),ds(2)),2);
ds = size(biemflipstats.biem.alldata.rho);
y=mean(reshape([biemflipstats.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('BIEM group weights predictive accuracy'); 
ylabel('BIEM subject weights predictive accuracy');
% plot BIEM subject vs. max of subject/group weight predictions
figure; hold on
scatter(max(x,y),y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('BIEM max group/subject weights predictive accuracy'); 
ylabel('BIEM subject weights predictive accuracy');

% mismatch predictions
%load('stats_MR_all_chan_cond_arcsinh_20180803T142036.mat'); MRstats=stats;
load('stats_BRR_all_chan_cond_arcsinh_20180802T203757.mat'); BRRstats=stats;
load('stats_RR_all_chan_cond_arcsinh_20180802T115759.mat'); RRstats=stats; 
load('stats_MVPA_all_chan_cond_arcsinh_20180815T072924.mat'); mvpastats=stats; 

% plot MR vs. RR
figure; hold on
ds = size(MRstats.biem.alldata.rho);
x=mean(reshape([MRstats.biem.alldata.rho],ds(1),ds(2)),2);
ds = size(RRstats.biem.alldata.rho);
y=mean(reshape([RRstats.biem.alldata.rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MR mismatch predictive accuracy'); 
ylabel('RR mismatch predictive accuracy');
% plot MR vs. BRR
figure; hold on
ds = size(MRstats.biem.alldata.rho);
x=mean(reshape([MRstats.biem.alldata.rho],ds(1),ds(2)),2);
ds = size(BRRstats.biem.alldata(1).rho);
y=mean(reshape([BRRstats.biem.alldata(1).rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MR mismatch predictive accuracy'); 
ylabel('BRR mismatch predictive accuracy');
% plot MVPA vs. BRR
figure; hold on
ds = size(mvpastats.mvpa.alldata);
x=mean(reshape([mvpastats.mvpa.alldata.testdata_corr],ds(1),ds(2)),2);
ds = size(BRRstats.biem.alldata(1).rho);
y=mean(reshape([BRRstats.biem.alldata(1).rho],ds(1),ds(2)),2);
scatter(x,y); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MVPA mismatch predictive accuracy'); 
ylabel('BRR mismatch predictive accuracy');
% 
% xticks=0:4:600;
% load('C:\Data\CORE\eeg\ana\prep\chanlocs.mat')
% 
% % plot MVPA weights
% grp_weights=mean(cat(1,stats.mvpa(:).weights),1);
% grp_weights = reshape(grp_weights,[],length(xticks));
% [~,mi]=max(std(abs(grp_weights),[],1));
% figure; imagesc(xticks,[],grp_weights); colormap jet; hold on; 
% line(xticks([mi mi]),[1 92],'color','k','linewidth',2); title('weights')
% figure; topoplot(grp_weights(:,mi),chanlocs); title('weights')
% 
% % plot MVPA transformed weights
% grp_transweights=mean(cat(1,stats.mvpa(:).transweights),1);
% grp_transweights = reshape(grp_transweights,[],length(xticks));
% [~,mi]=max(std(grp_transweights,[],1));
% figure; imagesc(xticks,[],grp_transweights); colormap jet; hold on; 
% line(xticks([mi mi]),[1 92],'color','k','linewidth',2); title('transformed weights')
% figure; topoplot(grp_transweights(:,mi),chanlocs); title('transformed weights')

% plot MVPA time-searchlight accuracy
xticks=0:4:600;
grp_acc=mean(cat(1,stats.mvpa(:).samples),1);
grp_std=std(cat(1,stats.mvpa(:).samples),[],1);
nsub = length(stats.mvpa); 
SEM = grp_std/sqrt(nsub);
tscore = -tinv(0.025,nsub-1);
CI = tscore*SEM;
upper = grp_acc+CI;
lower = grp_acc-CI;
figure; hold on
fill([xticks, fliplr(xticks)], [(upper), fliplr((lower))], ...
'b', 'EdgeAlpha', 0, 'FaceAlpha', 0.15);
plot(xticks,grp_acc,'b'); 

end