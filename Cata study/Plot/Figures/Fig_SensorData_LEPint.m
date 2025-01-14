close all
addpath('C:\Data\Matlab\export_fig')
%% figure options
fontsize = 12;
save_figs=1;
savefigspath = 'C:\Users\cab79\Google Drive\1. Liverpool University\Publications\Cata anticipation 2017\Figure_images\LEPint';

%% prepare SPM EEG data
S.spm_path = 'C:\Data\Catastrophising study\SPMstats\Include1\Within\t-500_1500_b-500_0_m_Att_Int_Exp_Subject_orig_cleaned_trialNmatch_spm';
%cluster directory name, which also specifies the constrast that will be
%plotted (i.e. the characters before the underscore)
S.clusdir='Int_clusters';
%factor(s) to plot - if more than one, first factor levels will be on separate plots
%must be the same characters as used to name the factors in design_batch
%P.facplot={'Exp','Grp'};
S.facplot={'Int'};
% clusters to plot
S.plotclus = {'c3_spm','c1_spm','c4_spm'};
S.wavetype = 'sensor'; % source or sensor?
S.wfname = 'cluster_data.mat'; %generic cluster waveform file name
S.batch = 'matlabbatch.mat'; %name of batch .mat file saved from design_batch.m and within same folder
S.subfactname = 'Subject'; %name of 'subject' factor in the SPM design
S.fact_names = {
    'Intensity'
    };
S.cval={ %condition labels, i.e. levels of each condition, in the same order as in the SPM design matrix. One row per factor. second column is plotting order
    {'Low','High'},[1 2]
    };
S.xlimits = [-200 1500];% time in ms
D = gplotprepare_spmeegsensorcluster(S)

%% prepare weights data for gplot
clear S
S.path = 'C:\Data\Catastrophising study\SPMstats\pronto\t-5500_1500_b-5500_-5000_m_0_1500_Grp_Exp_Subject_orig_cleaned_trialNmatch_prt_Int_gpc_ROI_perm1000weights';
S.fname = 'weight_timeseries.xlsx';
S.nhead = 1;
S.xvalhead = 'time';
S.yvalhead = {'wimg_val','pwimg_val'};
S.condhead = {'wimg_stdev','pwimg_stdev'};
S.colormaprange = [-3:3]; % should include all cond values 
W = gplotprepare_xlsxdata(S)

%% set up ERP gplot
clear P
% Subplots 1 to 4: SPM EEG clusters 1 to 4
for p = 1:length(D);
    P(p).xy = [p,1];
    P(p).x = D(p).x;
    P(p).y = D(p).y;
    P(p).cond = D(p).cond;
    P(p).condsize = []; % line/marker size
    P(p).xlinesolid = D(p).P_val;
    P(p).poly = D(p).E_val;% polygon times
    P(p).ptitle = [];%D(p).ptitle;
    P(p).fact_names = D(p).fact_names;
    P(p).colours = [0.2 0.5 1; 1 0.2 0.2]; % blue, red %CURRENTLY DOES NOT SUPPORT PLOTTING MORE THAN TWO FACTORS
    P(p).xlinedashed = [0];% vertical dashed lines to indicate events, time in ms
    P(p).timezero = 0;% change zero latency to this time
    P(p).xaxisname = {'post-stimulus time (ms)'};
    P(p).yaxisname = {'amplitude (uV)'};
    P(p).plottype = 'stat_summary';
    if p~=1
        P(p).legend = 0;
    end
end
% Subplots 5 to 6: Weight and projection plots from MVPA
for w = 1:length(W);
    p = p+1;
    P(p).xy = [p,1];
    P(p).x = [W(w).x; nan(length(S.colormaprange),1)]; % added a hack to get legend to a fixed range
    P(p).y = [W(w).y*100/sum(W(w).y); nan(length(S.colormaprange),1)];
    P(p).cond = [W(w).cond; S.colormaprange'];
    P(p).condsize = P(p).cond;
    P(p).xlinesolid = [];
    P(p).poly = [];% polygon times
    P(p).ptitle = [];%W(w).ptitle;
    P(p).fact_names = {'SDs from mean'};
    P(p).colours = 'lch'; % blue, red %CURRENTLY DOES NOT SUPPORT PLOTTING MORE THAN TWO FACTORS
    P(p).xlinedashed = [0];% vertical dashed lines to indicate events, time in ms
    P(p).timezero = 0;% change zero latency to this time
    P(p).xaxisname = {'post-stimulus time (ms)'};
    P(p).yaxisname = {'contribution (%)'};
    P(p).plottype = 'geom_point';
    if w~=1
        P(p).legend = 0;
    end
end

%% draw gplot
g=gramm();
for p = 1:length(P)
    if ~isfield(P(p),'timezero'); 
        P(p).timezero = [];
    end
    if ~isempty(P(p).timezero)
        P(p).xlinedashed = P(p).xlinedashed-P(p).timezero; % change zero time
        P(p).xlinesolid = P(p).xlinesolid-P(p).timezero;
        P(p).x = P(p).x-P(p).timezero;
        P(p).poly = P(p).poly-P(p).timezero;
    end
    g = gplot_timeseries(g,P(p));
end
%g.set_title('title');
fig=figure;%('Position',[100 100 800 550]);
adjustment = 1.1; % need to play with this to get it the same as other figures
plotheightratio = length(g)/6 / adjustment; % compared to other figures, so each subplot is the same height across figures
set(fig, 'Units', 'normalized', 'Position', [0,0,0.4,1*plotheightratio]);
g.set_text_options('base_size',fontsize,'legend_title_scaling',1);
g.draw();
drawnow
gap = 1.2; % 1.3 = 30% gap between plots
g=align_gplots(g,gap); % custom function
figname = 'ERP_plot';
if save_figs; export_fig(fullfile(savefigspath,[figname '.png']), '-r1200'); end

%% Prepare EEGLAB data for topos
clear S
S.eeglab_path = 'C:\Data\Catastrophising study\Preprocessed\Jitter corrected';
S.eventtypes = {'c1','c3','c5','c7','c2','c4','c6','c8'};
S.st_string='mspm12_';
S.en_string='\scond';
S.ERPsavename = 'ERP_DAT_LEP.mat';
S.overwriteEEG =0;
if ~exist(fullfile(S.eeglab_path,S.ERPsavename),'file') || S.overwriteEEG
    E=gplotprepare_eeglabdata_from_spm(S,D(1))
else
    load(fullfile(S.eeglab_path,S.ERPsavename));
end

%% plot topographies
clear P
P.topotype='eeglab';
P.no_plot_ele=[];
P.topo_subtimewin=2000;%[-2265 -2265]; % time window length. single value: plots multiple topos in consecutive windows with this length. 2 values: specifies a window. 0 = whole cluster mean.
P.fontsize=fontsize;
for d = 1:length(D)
    E.E_val = D(d).E_val
    plot_topo(P,E)
    set(gcf,'color','w');
    set(gca,'fontsize', fontsize);
    set(gcf, 'Units', 'normalized', 'Position', [0.5,0.5,0.15,0.25]);
    figname = ['Topo_plot_' num2str(E.E_val(1)) '-' num2str(E.E_val(end))];
    if save_figs; export_fig(fullfile(savefigspath,[figname '.png']), '-r1200'); end
end

%% prepare ROC curve data
clear S
S.path = 'C:\Data\Catastrophising study\SPMstats\pronto\t-5500_1500_b-5500_-5000_m_0_1500_Grp_Exp_Subject_orig_cleaned_trialNmatch_prt_Int_gpc_ROI_perm1000weights';
S.fname = 'PRT.mat';
load(fullfile(S.path,S.fname));
[fp,tp,A] = prt_plot_ROC(PRT, 1, 1)
figure
plot(fp,tp,'LineWidth',2)
hold on
area(fp,tp,'FaceColor',lines(1),'FaceAlpha',0.2)
xlabel('False positive rate')
ylabel('True positive rate')
text(0.3,0.3,['AUC = ' num2str(A)])
hold off
set(gcf,'color','w');
set(gca,'fontsize', fontsize);
set(gcf, 'Units', 'normalized', 'Position', [0.5,0.5,0.15,0.25]);
figname = 'ROCplot';
if save_figs; export_fig(fullfile(savefigspath,[figname '.png']), '-r1200'); end

% plot weight topos
clear S
S.path = 'C:\Data\Catastrophising study\SPMstats\pronto\t-5500_1500_b-5500_-5000_m_0_1500_Grp_Exp_Subject_orig_cleaned_trialNmatch_prt_Int_gpc_ROI_perm1000weights';
S.fname = 'weight_image_topos.mat';
load(fullfile(S.path,S.fname));
field = {'wimg','pwimg'};
figure
fn=0
for f = 1:length(field)
    for f2 = 1:length(field)
        fn = fn+1;
        subplot(1,4,fn);
        %imagesc(rot90(topo))
        pcolor(rot90(topo.(field{f2}).(field{f}).map,3)), shading interp
        axis off
        colormap(jet)
        title([field{f2} ': max ' field{f} ' @ ' num2str(topo.(field{f2}).(field{f}).peaktime) 'ms'])
        %colorbar
    end
end
set(gcf,'color','w');
set(gca,'fontsize', fontsize);
set(gcf, 'Units', 'normalized', 'Position', [0,0.5,0.5,0.20])
figname = 'Weight_topoplots';
if save_figs; export_fig(fullfile(savefigspath,[figname '.png']), '-r1200'); end