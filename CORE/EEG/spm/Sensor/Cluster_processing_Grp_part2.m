%% Cluster processing script 
% calls functions (need to be in Matlab search path): 
% Extract_clusters, Extract_cluster_waveforms, Convert_VOI_to_excel
clear all
addpath('C:\Data\Matlab\Matlab_files\_generic_spm_batch')
 
%% generic directories for all analyses for this study
%-------------------------------------------------------------
% load .xlsx file containing 'Subject', 'Group', and covariates
S.pdatfile = 'C:\Data\CORE\Participants\Participant_data.xlsx';
% root directory in which subject-specific folders are located
S.data_path = 'C:\Data\CORE\EEG\ana\spm\SPMdata\sensorimages';
% directory in which SPM analysis is saved 
S.spmstats_path = 'C:\Data\CORE\EEG\ana\spm\SPMstats';
% specific folder containing the SPM stats for this analysis
% S.spm_dir = 't-200_899_b-200_0_m_0_800_Side_Grp_Odd_Subject_2_merged_cleaned_stats_BRR_all_chan_condHGF_notrans_20190221T154622_pred4_spm_n30';
% S.spm_dir = 't-200_899_b-200_0_m_0_800_Side_Grp_Subject_2_merged_cleaned_spm_n30_grpeffectmask_odd'; % set S.clusformthresh to 1 to use this
S.spm_dir = 't-200_899_b-200_0_m_0_800_Side_Grp_Odd_Subject_2_merged_cleaned_spm_n30'; 
%name of batch .mat file saved from design_batch.m and within same folder
%as SPM.mat
S.batch = 'matlabbatch.mat';
%name of subject information file in SPM directory (produced by
%design_batch)
S.subinfo = 'sub_info.mat';

%% contrast, factor and level information
%-------------------------------------------------------------
%contrast name to process - must match that in Matlabbatch (i.e. from design-batch script)
S.contrasts={}; % leave empty to proccess ALL contrasts in Matlabbatch
S.tf =1; % 1 if F-contrast, 2 or T-contrast, blank if not using S.contrasts
% contrasts={'Exp'}; % example to enter one contrast only

% stats to save in a table for each contrast and cluster
S.clustab{1} = {'cluster','cluster','cluster','peak','peak','peak','','','',''; 
            'label','p(FWE-corr)','equivk','p(FWE-corr)','F','equivZ','x,y,z {mm}','x','y','z'}; 
        
S.clustab{2} = {'cluster','cluster','cluster','peak','peak','peak','','','',''; 
            'label','p(FWE-corr)','equivk','p(FWE-corr)','T','equivZ','x,y,z {mm}','x','y','z'}; 
        
% Factors and levels: for saving VOI information for later plotting
% 1: factor name in design matrix, 2: output factor name 3: factor levels. 
% Factors can be in order of desired output, not necessarily of
% input into SPM design matrix. Levels must be in the same order as SPM
% design, but characters don't need to match anything.
S.factlev = {
        {'Side'},{'Side'},{'Aff','Unaff'};
        {'Grp'},{'Group'},{'CRPS','HC'};
        {'Odd'},{'Odd'},{'Odd','Stan'};
%         {'DC'},{'DC'},{'DC1','DC3'};
        {'Subject'},{'Subject'},{}; % can leave Subject levels empty as these will be populated by sub_info file.
    };
S.subrow = 4; % row of above factlev containing the subject factor

% specific mask image (with fill path and extension) or leave empty
S.imgmask = '';
% cluster forming threshold
S.thresDesc = 'none'; % 'FWE' or 'none'
S.clusformthresh = 0.001; % set to 1 to extract masked ROI data
S.clusterextent =1; % 1 = only significant if above cluster extent threshold

%% run functions (sit back and relax)
Extract_clusters(S);
Extract_cluster_waveforms(S);
Convert_VOImat_to_excel(S);
%Extract_cluster_residuals(S);
%Normality_test_residuals(S)