%clear all;
%grplist = [1 3 10 12]; %flipped
clear fnames;
%grplist = [33 34 31 32]; %unflipped
%grplist = [35 37 36 38]; %unflipped

grplist = [39 40 41 42]; %unflipped
%grplist = [41]; %unflipped
no_cond = 5;
epeaks = [1];
no_peaks = length(epeaks);

cdir = pwd;

if isunix
    filepath = '/scratch/cb802/Data/CRPS_Digit_Perception_exp1/SPM image files/Sensorspace_images';
    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
else
    filepath = 'W:\Data\CRPS_Digit_Perception_exp1\SPM image files\Sensorspace_images';
    run('W:\Matlab_files\CRPS_digits\loadsubj.m');
end


subjects = subjlists(grplist);

cd(filepath)
%grplist = [33 34 31 32]; %unflipped

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
        
        %tmp_nme = strrep(tmp_nme, 'left', 'left_meansub');
        %tmp_nme = strrep(tmp_nme, 'right', 'right_meansub');
        
        tmp_nme = ['aspm8_' tmp_nme];
        
        if strfind(tmp_nme, 'left')
            trials = [1:5];
        elseif strfind(tmp_nme, 'right')
            trials = [6:10];
        end
            
        for i = 1:no_cond
            for j = 1:no_peaks
                ind = (Ns-1)*no_cond*no_peaks + (j-1)*no_cond + i;
                nme = dir(fullfile(filepath,tmp_nme,['type_' num2str(trials(i))],'svar.img'));
                fnames{ind,1} = fullfile(filepath,tmp_nme,['type_' num2str(trials(i))],nme.name);
            end
        end
    end
end
cd(cdir);
load job.mat
matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans = fnames;
save job.mat matlabbatch