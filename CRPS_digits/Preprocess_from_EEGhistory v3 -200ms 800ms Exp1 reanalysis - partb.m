clear all
if isunix
    filepath = '/scratch/cb802/Data';
    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
else
    filepath = 'W:\Data';
    run('W:\Matlab_files\CRPS_digits\loadsubj.m');
end
raw_path = fullfile(filepath,'CRPS_raw/Raw');
cd(raw_path);
files = dir('*Exp1.set');
combine_all=0; % combining left and right stimulations, or that of different experiments, may be unwise for ICA purposes.

for f = 1:length(files)
    
    [pth nme ext] = fileparts(files(f).name); 
    C = strsplit(nme,'_');
    EEGc = pop_loadset('filename',files(f).name,'filepath',raw_path);
    %EEGc = pop_reref( EEGc, []); % only if not run before rejectgn epochs
    
    if combine_all == 1;
           
           correctRank = EEG.nbchan-1;
           EEGc = pop_runica(EEGc, 'extended',1,'interupt','on','pca',20);
           sname = [C{1} '_Exp1_ICA.set'];
           %EEGc = pop_saveset(EEGc,'filename',sname,'filepath',raw_path); 
           %save([C{1} '_trials_30Hz.mat'],'trials');
    else
        selectfnum =1:5;
        EEG=EEGc;
        part1analysis
       correctRank = EEG.nbchan-1;
       EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',20);
       sname = [C{1} '_Exp1_left.set'];
       EEG = pop_saveset(EEG,'filename',sname,'filepath',raw_path); 
       %trials = n1l_trials;
       %save([C{1} '_Exp1_left_trials_30Hz.mat'],'trials');

       selectfnum =6:10;
       EEG=EEGc;
        part1analysis
       correctRank = EEG.nbchan-1;
       EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',20);
       sname = [C{1} '_Exp1_right.set'];
       EEG = pop_saveset(EEG,'filename',sname,'filepath',raw_path); 
       %trials = n1r_trials;
       %save([C{1} '_Exp1_right_trials_30Hz.mat'],'trials');

       %    EEG = pop_reref( EEGn2l, []);
       %    correctRank = EEG.nbchan-1;
       %    EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',20);
       %    sname = [C{1} '_Exp2_left_ICA_30Hz.set'];
       %    EEG = pop_saveset(EEG,'filename',sname,'filepath',raw_path); 
       %    trials = n2l_trials;
       %    save([C{1} '_Exp2_left_trials_30Hz.mat'],'trials');

       %    EEG = pop_reref( EEGn2r, []);
       %    correctRank = EEG.nbchan-1;
       %    EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',20);
       %    sname = [C{1} '_Exp2_right_ICA_30Hz.set'];
       %    EEG = pop_saveset(EEG,'filename',sname,'filepath',raw_path); 
       %    trials = n2r_trials;
       %    save([C{1} '_Exp2_right_trials_30Hz.mat'],'trials');
    end
end