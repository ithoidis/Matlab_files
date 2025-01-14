clear all;
if isunix
    filepath = '/scratch/cb802/Data/CRPS_Digit_Perception';
    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
else
    filepath = 'W:\Data\CRPS_Digit_Perception';
    run('W:\Matlab_files\CRPS_digits\loadsubj.m');
end
cd(filepath);
grplists = {2;30}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp1
%grplists = {1; 29; 2; 30}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp2
%grplists = {47;48;49;50}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp2
%grplists = {37};
ngrps = 2;
subspergrp = 13;
templist = 1:subspergrp;
start = 1;

for g = 2:ngrps
    clear functions D;
    grpind = (g-1)*subspergrp+templist
    grplist = grplists{g,:}
    subjects = subjlists(grplist);
    cd(filepath)
    Ns=0;
    for s = 1:length(subjects)
        for s2 = 1:length(subjects{s,1})
            Ns=Ns+1;
            tmp_nme = subjects{s,1}{s2,1};
            tmp_nme = strrep(tmp_nme, '.left', '_left');
            tmp_nme = strrep(tmp_nme, '.Left', '_left');
            tmp_nme = strrep(tmp_nme, '.right', '_right');
            tmp_nme = strrep(tmp_nme, '.Right', '_right');
            tmp_nme = strrep(tmp_nme, '.flip', '_flip');
            tmp_nme = strrep(tmp_nme, '.Flip', '_flip');
            tmp_nme = strrep(tmp_nme, '.aff', '_aff');
            tmp_nme = strrep(tmp_nme, '.Aff', '_aff');
            tmp_nme = strrep(tmp_nme, '.Unaff', '_unaff');
            tmp_nme = strrep(tmp_nme, '.unaff', '_unaff');
            tmp_nme = strrep(tmp_nme, '_Left', '_left');
            tmp_nme = strrep(tmp_nme, '_Right', '_right');
            tmp_nme = strrep(tmp_nme, '_Flip', '_flip');
            tmp_nme = strrep(tmp_nme, '_Aff', '_aff');
            tmp_nme = strrep(tmp_nme, '_Unaff', '_unaff');
            tmp_nme = strrep(tmp_nme, '.Exp1', '_Exp1');
            tmp_nme = strrep(tmp_nme, '.Exp2', '_Exp2');
            fnames{Ns} = ['spm8_flip_' tmp_nme];
        end
    end
    swd   = pwd;
    for i = 1:subspergrp
        % Artefact rejection
        %==========================================================================
        %load batch_artefact;
        %S = matlabbatch{1,1}.spm.meeg.preproc;
        clear S;
        S.badchanthresh = 0.2;
        S.methods(1).channels = 'all';
        S.methods(1).fun = 'jump';
        S.methods(1).settings.threshold = 75;
        S.methods(2).channels = 'all';
        S.methods(2).fun = 'peak2peak';
        S.methods(2).settings.threshold = 200;
        %S.artefact.External_list = 0;
        %S.artefact.out_list = [];
        %S.artefact.in_list = [];
        %S.artefact.Weighted = 0;
        %S.artefact.Check_Threshold = 0;
       % for i = 1:subspergrp
            fprintf('Artefact rejection: subject %i\n',i);
            fname = fnames{i};
            S.D = fullfile(pwd,fname)
            D = spm_eeg_artefact(S);
            %D     = spm_eeg_load(fullfile(pwd,fname));
            %save(D);
       % end%%

        % Average over trials per condition
        %==========================================================================
        clear S D;
        S.robust = 0;
        S.review = 0;
        %for i = 1:subspergrp
            fprintf('Averaging: subject %i\n',i);
            fname = ['a' fnames{i}];
            S.D = fullfile(pwd,fname)
            D = spm_eeg_average(S);
        %end

     
    end
end
    matlabmail
