load job.mat
P = matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans;
Q = {
'H:\PET study\EEG session\mspm_P1__3_1.nii'
'H:\PET study\EEG session\mspm_P1__3_2.nii'
'H:\PET study\EEG session\mspm_P2__3_1.nii'
'H:\PET study\EEG session\mspm_P2__3_2.nii'
'H:\PET study\EEG session\mspm_P5__3_1.nii'
'H:\PET study\EEG session\mspm_P5__3_2.nii'
'H:\PET study\EEG session\mspm_P6__3_1.nii'
'H:\PET study\EEG session\mspm_P6__3_2.nii'
'H:\PET study\EEG session\mspm_P7__3_1.nii'
'H:\PET study\EEG session\mspm_P7__3_2.nii'
'H:\PET study\EEG session\mspm_P8__3_1.nii'
'H:\PET study\EEG session\mspm_P8__3_2.nii'
'H:\PET study\EEG session\mspm_P15__3_1.nii'
'H:\PET study\EEG session\mspm_P15__3_2.nii'
'H:\PET study\EEG session\mspm_P16__3_1.nii'
'H:\PET study\EEG session\mspm_P16__3_2.nii'
'H:\PET study\EEG session\mspm_S1__3_1.nii'
'H:\PET study\EEG session\mspm_S1__3_2.nii'
'H:\PET study\EEG session\mspm_S2__3_1.nii'
'H:\PET study\EEG session\mspm_S2__3_2.nii'
'H:\PET study\EEG session\mspm_S3__3_1.nii'
'H:\PET study\EEG session\mspm_S3__3_2.nii'
'H:\PET study\EEG session\mspm_S5__3_1.nii'
'H:\PET study\EEG session\mspm_S5__3_2.nii'
'H:\PET study\EEG session\mspm_S6__3_1.nii'
'H:\PET study\EEG session\mspm_S6__3_2.nii'
'H:\PET study\EEG session\mspm_S8__3_1.nii'
'H:\PET study\EEG session\mspm_S8__3_2.nii'
'H:\PET study\EEG session\mspm_S9__3_1.nii'
'H:\PET study\EEG session\mspm_S9__3_2.nii'
'H:\PET study\EEG session\mspm_S10__3_1.nii'
'H:\PET study\EEG session\mspm_S10__3_2.nii'
'H:\PET study\EEG session\mspm_S11__3_1.nii'
'H:\PET study\EEG session\mspm_S11__3_2.nii'
'H:\PET study\EEG session\mspm_S18__3_1.nii'
'H:\PET study\EEG session\mspm_S18__3_2.nii'
'H:\PET study\EEG session\mspm_S20__3_1.nii'
'H:\PET study\EEG session\mspm_S20__3_2.nii'
};
matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans = Q;
save job.mat matlabbatch