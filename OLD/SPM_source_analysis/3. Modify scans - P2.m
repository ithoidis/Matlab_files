load job.mat
P = matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans;
Q = {
'H:\PET study\EEG session\mspm_P1__6_1.nii'
'H:\PET study\EEG session\mspm_P1__7_2.nii'
'H:\PET study\EEG session\mspm_P2__6_1.nii'
'H:\PET study\EEG session\mspm_P2__7_2.nii'
'H:\PET study\EEG session\mspm_P5__6_1.nii'
'H:\PET study\EEG session\mspm_P5__7_2.nii'
'H:\PET study\EEG session\mspm_P6__6_1.nii'
'H:\PET study\EEG session\mspm_P6__7_2.nii'
'H:\PET study\EEG session\mspm_P7__6_1.nii'
'H:\PET study\EEG session\mspm_P7__7_2.nii'
'H:\PET study\EEG session\mspm_P8__6_1.nii'
'H:\PET study\EEG session\mspm_P8__7_2.nii'
'H:\PET study\EEG session\mspm_P15__6_1.nii'
'H:\PET study\EEG session\mspm_P15__7_2.nii'
'H:\PET study\EEG session\mspm_P16__6_1.nii'
'H:\PET study\EEG session\mspm_P16__7_2.nii'
'H:\PET study\EEG session\mspm_S1__6_1.nii'
'H:\PET study\EEG session\mspm_S1__7_2.nii'
'H:\PET study\EEG session\mspm_S2__6_1.nii'
'H:\PET study\EEG session\mspm_S2__7_2.nii'
'H:\PET study\EEG session\mspm_S3__6_1.nii'
'H:\PET study\EEG session\mspm_S3__7_2.nii'
'H:\PET study\EEG session\mspm_S5__6_1.nii'
'H:\PET study\EEG session\mspm_S5__7_2.nii'
'H:\PET study\EEG session\mspm_S6__6_1.nii'
'H:\PET study\EEG session\mspm_S6__7_2.nii'
'H:\PET study\EEG session\mspm_S8__6_1.nii'
'H:\PET study\EEG session\mspm_S8__7_2.nii'
'H:\PET study\EEG session\mspm_S9__6_1.nii'
'H:\PET study\EEG session\mspm_S9__7_2.nii'
'H:\PET study\EEG session\mspm_S10__6_1.nii'
'H:\PET study\EEG session\mspm_S10__7_2.nii'
'H:\PET study\EEG session\mspm_S11__6_1.nii'
'H:\PET study\EEG session\mspm_S11__7_2.nii'
'H:\PET study\EEG session\mspm_S18__6_1.nii'
'H:\PET study\EEG session\mspm_S18__7_2.nii'
'H:\PET study\EEG session\mspm_S20__6_1.nii'
'H:\PET study\EEG session\mspm_S20__7_2.nii'
};
matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans = Q;
save job.mat matlabbatch