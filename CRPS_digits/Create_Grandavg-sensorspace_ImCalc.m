%clear all;
grplist = [33 34 31 32]; outputname = {'Healthy_Aff_Grandavg_Exp2_flip','Healthy_Unaff_Grandavg_Exp2_flip','Patient_Aff_Grandavg_Exp2_flip','Patient_Unaff_Grandavg_Exp2_flip'};
%grplist = [35 36 37 38]; outputname = {'Healthy_Left_Grandavg_Exp1','Healthy_Right_Grandavg_Exp1','Patient_Left_Grandavg_Exp1','Patient_Right_Grandavg_Exp1'};
%grplist = [47:50]; outputname = {'Healthy_Left_Grandavg_Exp2','Healthy_Right_Grandavg_Exp2','Patient_Left_Grandavg_Exp2','Patient_Right_Grandavg_Exp2'};
%grplist = [35 36 37 38]; outputname = {'Healthy_Left_Grandavg_Exp1','Healthy_Right_Grandavg_Exp1','Patient_Left_Grandavg_Exp1','Patient_Right_Grandavg_Exp1'};
clear fnames;
cdir = pwd;

%if isunix
%    filepath = '/scratch/cb802/Data/CRPS_Digit_Perception_exp1/SPM image files/Sensorspace_images';
%    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
%else
%    filepath = 'W:\Data\CRPS_Digit_Perception_exp1\SPM image files\Sensorspace_images';
%    run('W:\Matlab_files\CRPS_digits\loadsubj.m');
%end

if isunix
    filepath = '/scratch/cb802/Data/CRPS_Digit_Perception/SPM image files/Sensorspace_images';
    run('/scratch/cb802/Matlab_files/CRPS_digits/loadsubj.m');
else
    filepath = 'W:\Data\CRPS_Digit_Perception\SPM image files\Sensorspace_images';
    run('W:\Matlab_files\CRPS_digits\loadsubj.m');
end


subjects = subjlists(grplist);

cd(filepath)


for s = 1:length(subjects)
    Ns=0;
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

        tmp_nme = ['maspm8_' tmp_nme];
        if strfind(tmp_nme, 'right')
            fnames{Ns,1} = fullfile(filepath,tmp_nme,'smean_flip_reorient.img');
        else
            fnames{Ns,1} = fullfile(filepath,tmp_nme,'smean.img');
        end
    end
    Output = spm_imcalc_ui(fnames,fullfile(filepath,[outputname{s} '.nii']),'mean(X)',{1,[],[],[]})
end


    