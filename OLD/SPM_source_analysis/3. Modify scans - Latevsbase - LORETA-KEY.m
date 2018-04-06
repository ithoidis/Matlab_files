load job.mat
P = matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans;
Q = {
'H:\PET study\EEG session\log10_P1_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P1_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P1_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P1_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P2_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P2_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P2_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P2_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P5_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P5_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P5_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P5_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P6_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P6_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P6_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P6_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P7_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P7_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P7_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P7_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P8_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P8_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P8_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P8_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P15_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P15_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P15_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P15_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P16_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P16_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P16_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_P16_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S1_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S1_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S1_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S1_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S2_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S2_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S2_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S2_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S3_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S3_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S3_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S3_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S5_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S5_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S5_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S5_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S6_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S6_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S6_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S6_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S8_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S8_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S8_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S8_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S9_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S9_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S9_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S9_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S10_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S10_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S10_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S10_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S11_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S11_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S11_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S11_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S18_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S18_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S18_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S18_2_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S20_1_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S20_2_b2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S20_1_p2_av-B2T_F0001.img'
'H:\PET study\EEG session\log10_S20_2_p2_av-B2T_F0001.img'
};
matlabbatch{1,1}.spm.stats.factorial_design.des.fblock.fsuball.specall.scans = Q;
save job.mat matlabbatch