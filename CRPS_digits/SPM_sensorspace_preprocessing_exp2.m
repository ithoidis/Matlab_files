clear all;
%if isunix
%    filepath = '/scratch/cb802/Data/CRPS_Digit_Perception_exp1/alltrials';
%    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
%else
    filepath = 'C:\Data\CRPS-DP\CRPS_Digit_Perception\';
    run('C:\Data\Matlab\Matlab_files\CRPS_digits\loadsubj.m');
%end
cd(filepath);
%grplists = {39; 40; 41; 42}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp1
grplists = {1; 29; 2; 30}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp2
%grplists = {47;48;49;50}; %sublist_side = {'L','R','L','R'}; %Affected vs unaffected exp2
%grplists = {35;37};
%grplists = {37};
ngrps = 4;
subspergrp = 13;
templist = 1:subspergrp;
start = 1;
use_flipped=0;
suffix = '';
%suffix = '_change';

for g = 1:ngrps
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
            
            if use_flipped==1
                if strfind(tmp_nme, 'left')
                    fnames{Ns} = ['spm8_' tmp_nme suffix];
                elseif strfind(tmp_nme, 'right')
                    fnames{Ns} = ['spm8_flip_' tmp_nme suffix];
                end
            else
                fnames{Ns} = ['spm8_' tmp_nme suffix];
            end
            
            
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
            if (~isempty(strfind(fname, 'left')) || ~isempty(strfind(fname, 'Left'))); 
                continue
            end
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
            %save(D);
        %end
%    end
%end

        % Convert to 3D images (2 space and 1 time dimension)
        %==========================================================================
        clear S D;
        S.images.fmt = 'channels';
        %S.images.elecs =
        %S.images.region_no =
        %S.images.freqs =
        %S.images.t_win =
        S.n = 32;
        S.interpolate_bad = 1;
        %for i = 1:subspergrp % [1:9 11:13]
            fprintf('Converting to images: subject %i\n',i);
            fname = ['ma' fnames{i}]
            load(fname);
            D.sensors.eeg.pnt = D.sensors.eeg.pnt(:,[2 1 3]);
            %D.sensors.eeg.elecpos = D.sensors.eeg.elecpos(:,[2 1 3]);
            D.fiducials.pnt = D.fiducials.pnt(:,[2 1 3]);
            D.fiducials.fid.pnt = D.fiducials.fid.pnt(:,[2 1 3]);
            D=meeg(D);
            S1 = [];
            S1.task = 'project3D';
            S1.modality = 'EEG';
            S1.updatehistory = 0;
            S1.D = D;
            D = spm_eeg_prep(S1);
            save(D);
        %end
    %end

     %   

            S.D = fullfile(pwd,fname);
            %S.mode = 'scalp x time';
            [D, S, Pout] = spm_eeg_convert2images(S) % spm8
            %images = spm_eeg_convert2images(S) % spm12
        %end



    %%
        % Smooth images
        %==========================================================================
        load('batch_smooth');
        matlabbatch{1,1}.spm.spatial.smooth.fwhm = [20 20 0]; % space space time
        matlabbatch{1,1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1,1}.spm.spatial.smooth.im = 1; % implicit mask
        %for is = start:length(fnames)
            fname = ['ma' fnames{i}];
            d = dir(fullfile(pwd,fname,'type*'));%spm12
            isub = [d(:).isdir]; %# returns logical vector%spm8
            nameFolds = {d(isub).name}';%spm8
            %nameFolds = {d.name}';%spm12
            nameFolds(ismember(nameFolds,{'.','..'})) = [];%spm8
            for nf = 1:length(nameFolds)
                imfile = dir(fullfile(pwd,fname,nameFolds{nf},'trial*.img'));%spm8
                %imfile = dir(fullfile(pwd,fname,nameFolds{nf}));%spm12
                imfile = imfile.name;
                matlabbatch{1,1}.spm.spatial.smooth.data = {fullfile(pwd,fname,nameFolds{nf},[imfile ',1'])};
                spm_jobman('initcfg')
                spm_jobman('run',matlabbatch);
            end
        %end
    end
end
    matlabmail
