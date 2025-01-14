clear all
close all

%grplist = [51 52 53 54]; sublist_side = {'L','R','L','R'}; sublist_grp = {'H','H','P','P'}; filepath = 'C:\Data\CRPS-DP\CRPS_Digit_Perception_exp1\alltrials\';%Exp1 left v right
grplist = [1 2 29 30]; sublist_side = {'L','R','L','R'}; sublist_grp = {'H','H','P','P'}; filepath = 'C:\Data\CRPS-DP\CRPS_Digit_Perception\';%Exp2
cd(filepath);
run('M:\Matlab\Matlab_files\CRPS_digits\loadsubj.m');
subjects = subjlists(grplist);
load('timefreq_limits_ERP_evoked_FNUM_CNUM');
load cov_RT_HL-HR-PL-PR;

grplistselect = 1:4;
statall = cell(1);
for i = grplistselect

    %select data
    %statmode = 'subj_corr'; %options: 'subj' 'subj_corr'
    statmode = 'subj_corr'%'subj'% 'corr'; %

    subjinfo = subjects(i);
    condlist = sublist_grp(i);
    condcont = [1]; % contrast. All '1' mean common condition values will be collapsed. '1 -1' will subtract common condition values.
    covariate = cov(:,i); condlist = [condlist 'cov'];

    %define latencies
    latency =  [0 0.3];%timefreq_limits.limits_all{:};%
    peakdef =  [1 1];% defines which peak the latencies refer to.  %timefreq_limits.bins; %

    %set parameters
    alpha = 0.05;
    numrand = 1000; 
    ttesttail = 0;
    testgfp = 'off'; gfpbasecorrect=0;
    singlesource = 'off';
    testmean = 'off';
    testlat = 'off';
    timeshift =0;

    stat = FTstats(statmode,subjinfo,condlist,condcont,latency,covariate,filepath,'alpha',alpha,'numrand',numrand,'ttesttail',ttesttail,'testgfp',testgfp,...
        'singlesource',singlesource,'testmean',testmean,'testlat',testlat,'timeshift',timeshift,'peakdef',peakdef);

    statall{i} = stat;


    %if iscell(latency)
    %    clusidx = stat.posclusterslabelmat>=1;
    %    latind = [latency{:}];
    %    times = -0.2:0.004:0.796;
    %    times(latind(clusidx))
    %end

end
close all
for i = grplistselect
    stat=statall{1,i};
    if strcmp(testgfp,'on');
        plotclusters(stat);
    else
        cfg = [];
        cfg.zlim = [-6 6]; %Tvalues
        cfg.alpha = 0.05;
        cfg.elecfile = 'FT_layout.mat';
        ft_clusterplot(cfg,stat)
    end
    
    
end

