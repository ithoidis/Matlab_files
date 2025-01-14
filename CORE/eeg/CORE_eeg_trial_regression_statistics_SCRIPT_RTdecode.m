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

clear all
close all
dbstop if error % optional instruction to stop at a breakpoint if there is an error - useful for debugging
restoredefaultpath

%% add toolbox paths
run('C:\Data\Matlab\Matlab_files\CORE\CORE_addpaths')

%% SET DATA PATHS/NAMES: EEG .set files
clear S
S.path=struct;% clears the field
S.path.main = 'C:\Data\CORE\eeg\ana';
S.path.eeg = [S.path.main '\prep\cleaned\part2'];
S.path.stats = [S.path.main '\stats']; % folder to save outputs
S.path.hgf = ['C:\Data\CORE\behaviour\hgf\fitted\CORE_fittedparameters_percmodel12_respmodel2_fractrain0_20180821T134505.mat']; 
S.path.design = ['C:\Data\CORE\design']; % 
S.path.datfile = 'C:\Data\CORE\Participants\Participant_data.xlsx'; % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
S.path.chanlocs = 'C:\Data\CORE\eeg\ana\prep\chanlocs.mat';
S.fname.parts = {'subject','suffix','ext'}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
S.fname.ext = {'set'}; 
S.select.subjects = {}; % either a single subject, or leave blank to process all subjects in folder
S.select.sessions = {};
S.select.blocks = {}; % blocks to load (each a separate file) - empty means all of them, or not defined
S.select.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
S.load.suffixes = {'2_merged_cleaned'}; 
save(fullfile(S.path.main,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

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
S.analysis_type='MR'; 

S.cond_idx = {
    [1 2 9 10 17 18] %left hand, mismatch
    [3 4 11 12 19 20] %left hand, standard
    [5 6 13 14 21 22] %right hand, mismatch
    [7 8 15 16 23 24] %right hand, standard
    };

% which rows to subtract? (second cell must contain meaned data)
%S.row_subtract = {[1 3],[2 4]}; % mismatch trials minus mean of standards
%S.row_subtract = {}; % mismatch trials minus mean of standards

% rows of cond_idx to contrast
%S.contrast_rows = {}; % empty - all pooled into one (e.g. for regression)
%S.contrast_rows = {[1 3],[2 4]}; % e.g. fixed effects analysis
%S.contrast_rows = {[1 3]}; % include mismatch only (e.g. if correlating with RT)
%S.contrast_rows = {[1 3],[1:4]}; % training and testing
%S.contrast_rows = {[1:4]}; % include all (e.g. correlating with HGF traj)
S.contrast_rows = {[1:4],[1:4]}; % include all (e.g. correlating with HGF traj) and test on all
%S.contrast_rows = {[1 3],[1 3]}; % include all (e.g. correlating with HGF traj) and test on mismatch

% other EEG data operations
S.flipchan = [3 4]; % rows of S.cond_idx containing trial types to flip channels right to left 
S.total_samples = -200:799;
S.select_samples = 0:600;
S.smooth_samples = 10;
S.dsample = 4;
S.transform = 'arcsinh'; % arcsinh or notrans
S.zscore = 1;
S.ndec=8; % trim data to a number of decimal places

% run options
% for testing decoders: random, 0.5 fraction, balanced, 10 runs.
S.traintest = 'cond'; % method to split data into training and testing. options: 'random' selection of trials (S.trainfrac must be >0); 'cond': select by condition
S.trainfrac = 1; % fraction of trials to use as training data (taken at random). Remainder used for testing. E.g. training for encoding vs. testing for decoding. Or, MPVA training vs. MVPA testing.
S.balance_conds =1; % random training trials balanced across conditions
S.num_runs = 1; % run analysis this many times, each time with a different random choice of training/test data

% Predictor variables
S.pred_type = {'HGF','RT'}; % cond, RT or HGF
S.pred_type_traintest = {'train','test'}; % 'train' or 'test' for each pred_type. 'train' also performs testing if set by S.traintest.
%S.pred_type = {'cond'}; % cond, RT or HGF
% if S.pred_type='cond':
S.cond = {[2 4],[1 3]};
% if S.pred_type = 'HGF': HGF trajectories, grouped
%S.traj{1} = {
    %{'PL'},{'epsi'},{[0]},{[1:3]}; %3rd col: absolute values; 
    %{'PL'},{'da','dau','psi','epsi'},{[0 0 0 0]},{[],[],[],[]}; %3rd col: 1=abs, 2=rect; 4th col: levels (empty=all)
    %{'PR'},{'da','dau','psi','epsi'};
%    }; % prediction errors, updates and learning rates
 S.traj{1} = {
     %{'PL'},{'dau'},{[0]},{[]};
     %{'PL'},{'dau','epsi'},{[0,0]},{[],[2]};
     {'PL'},{'dau','da','epsi'},{[0,0,0]},{[],[1:2],[]};
     }; % beliefs and their variance
% S.traj{2} = {
%     {'PL'},{'da','dau','ud','psi','epsi','wt'};
%     {'PR'},{'da','dau','ud','psi','epsi','wt'};
%     }; % prediction errors, updates and learning rates
S.pred_transform = 'notrans'; % arcsinh, rank or notrans

% TFCE settings
S.tfce_on = 0; % for clustering over time only
S.cosmo_tfce_on = 0; % use cosmo if analysing clusters over channels/frequencies (+/- time). NB Cosmo does NOT implement regression/ccrrelation.
%S.tfce_test = S.analysis_type; % set to SC or MR above
S.tfce_tail = 2;
S.tfce_nperm=100; % for initial testing, between 100 and 1000. 5000 is most robust, but slow

% Multiple regression settings
S.save_residuals=0;

% Ridge regression settings
S.rr.df_num = 100; % number of lambdas to do cross-val on
S.rr.folds = 5; % number of folds in the traindata for cross-validation
S.rr.z = 1; % determines which method to use. Either 1 or 0.
S.rr.sigma=0; % save sigma? RESULTS IN LARGE MATRICES AND MEMORY PROBLEMS

% Bayesian regularised regression (BRR) settings
S.brr.folds = 0;            % number of folds in the traindata. Set to 0 to not conduct predictive cross-validation.
S.brr.model = 'gaussian';   % error distribution - string, one of {'gaussian','laplace','t','binomial'}
S.brr.prior = 'horseshoe+';        %- string, one of {'g','ridge','lasso','horseshoe','horseshoe+'}
S.brr.nsamples = 100;   %- number of posterior MCMC samples (Default: 1000)  
S.brr.burnin = 100;     %- number of burnin MCMC samples (Default: 1000)
S.brr.thin = 5;       %- level of thinning (Default: 5)
S.brr.catvars = [];    %- vector of variables (as column numbers of X) to treat
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
S.parallel=1;       %- use parallel processing

% %BIEM settings
S.biem_on=1;
S.biem_prior = 'subject_training'; % options: 'group_training', 'subject_training', 'uniform'
S.biem_groupweights = '';%'stats_grp_MR_all_chan_cond_arcsinh_20180804T144006.mat'; % repeat of MR mismatch, with decoding';%'stats_grp_RR_all_chan_RT_arcsinh_20180802T130052.mat'; % file containing beta and sigma values from a previous encoding run, group averaged.
S.biem_pred = [1:6]; % specify which predictor variable(s) to correlate with input

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
S.mvpa_type='class'; %'class' or 'regress'
S.SL_type = 'time';
S.search_radius = Inf; % data points, not ms.  Set to Inf to analyse all data points at once.
S.use_measure = 'crossvalidation';
S.balance_dataset_and_partitions =1; % turn on for classification, off for regression
S.parti='nchunks'; % 'take-one-out', 'splithalf', 'oddeven', 'nchunks'
S.use_classifier = 'GP'; 
S.use_chunks = 'balance_targets'; % 'balance_targets' (over chunks) or 'none'. Not needed for 'take-one-out' option.
S.nchunks=10;
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
load('stats_MR_all_chan_RT_arcsinh_20180922T140745.mat'); biemRT=stats; % 100% train/test
load('stats_MR_all_chan_condRT_arcsinh_20180815T155650.mat'); biemcondRT_orig=stats; % 100% train/test
load('stats_MR_all_chan_condRT_arcsinh_20180922T141040.mat'); biemcondRT=stats; % 100% train/test
load('stats_MR_all_chan_HGFRT_arcsinh_20180922T143102.mat'); biemHGFRT=stats; % 100% train/test

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
ds = size(biemcondRT.biem.alldata.rho);
y=mean(reshape([biemcondRT.biem.alldata.rho{:}],ds(1),ds(2)),2);
xind=ismember(mvpastats2.subname,biemcondRT.subname);
yind=ismember(biemcondRT.subname,mvpastats2.subname);
scatter(x(xind),y(yind)); 
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

% plot prediction of RT from mismatch encoded patterns vs. HGF-encoded
HGFtraj = 2; % predictor to use
figure; hold on
ds = size(biemcondRT.biem.alldata.rho);
x=mean(reshape([biemcondRT.biem.alldata(1).rho{:}],ds(1),ds(2)),2);
ds = size(biemHGFRT.biem.alldata.rho);
datmat=cell2mat(biemHGFRT.biem.alldata.rho);
y=mean(reshape(datmat(:,HGFtraj),ds(1),ds(2)),2);
xind=ismember(biemcondRT.subname,biemHGFRT.subname);
yind=ismember(biemHGFRT.subname,biemcondRT.subname);
scatter(x(xind),y(yind)); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');
xlabel('MR mismatch predictive accuracy'); 
ylabel('MR HGF predictive accuracy');

% temp: comparing old and new analyses
figure; hold on
ds = size(biemcondRT.biem.alldata.rho);
x=mean(reshape([biemcondRT.biem.alldata(1).rho{:}],ds(1),ds(2)),2);
ds = size(biemcondRT_orig.biem.alldata.rho);
y=mean(reshape(biemcondRT_orig.biem.alldata.rho,ds(1),ds(2)),2);
xind=ismember(biemcondRT.subname,biemcondRT_orig.subname);
yind=ismember(biemcondRT_orig.subname,biemcondRT.subname);
scatter(x(xind),y(yind)); 
h=refline(1,0); h.Color = 'b';
line(xlim(), [0,0], 'Color', 'k');
line([0 0], ylim(), 'Color', 'k');

% predict subject differences in RTs: condRT
for d = 1:length(biemcondRT.subname)
    x=biemcondRT.biem.alldata.recons{d,1}; 
    y=biemcondRT.trialinfo{1}.pred_test{d,1}(biemcondRT.trialinfo{1}.testidx{d,1});
    rho(d)=corr(x,y,'type','Spearman');
    meandat(d,:) = [mean(x),mean(y)];
end
[rho_mean,p_mean]=corr(meandat,'type','Spearman')
figure;scatter(meandat(:,1),meandat(:,2)); title('predicted mismatch (x) vs. actual RTs (y)')

% predict subject differences in RTs: HGFRT
clear meandat rho
HGFtraj = 1; % predictor to use
for d = 1:length(biemHGFRT.subname)
    x=biemHGFRT.biem.alldata.recons{d,1}; 
    y=biemHGFRT.trialinfo{1}.pred_test{d,1}(biemHGFRT.trialinfo{1}.testidx{d,1});
    rho(d)=corr(x(:,HGFtraj),y,'type','Spearman');
    meandat(d,:) = [1,mean(x,1),mean(y)];
end
[rho_mean,p_mean]=corr(meandat(:,2:end),'type','Spearman')
[beta,~,~,~,stt] = regress(meandat(:,end),meandat(:,1:end-1))
figure;scatter(meandat(:,HGFtraj+1),meandat(:,end)); title('predicted HGF traj (x) vs. actual RTs (y)')


% predict subject differences in RTs: RTRT
for d = 1:length(biemRT.subname)
    x=biemRT.biem.alldata.recons{d,1}; 
    y=biemRT.trialinfo{1}.pred_test{d,1}(biemRT.trialinfo{1}.testidx{d,1});
    rho(d)=corr(x,y,'type','Spearman');
    meandat(d,:) = [mean(x),mean(y)];
end
[rho_mean,p_mean]=corr(meandat,'type','Spearman')
figure;scatter(meandat(:,1),meandat(:,2)); title('predicted RT (x) vs. actual RTs (y)')


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