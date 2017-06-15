options compress=yes;
goptions  NODISPLAY;

/**************************************************************************************************
Updates:
		10/15/2015 - Replaced 4 cancer procs with 4 specific imaging procs. BR
		10/20/2015 - This program is adapted from the Ingenix program of the same name. Now runs
					 with Optum data.
		12/10/2015 - Added all specific measures
		12/22/2015 - Changed metric from eligible stays to eligible beneficiary
		01/12/2016 - Added in total cost of all procedures from continuously enrolled beneficiaries in a given year
		02/18/2016 - Merge in updated costs for select procedures. Updated costs come from calc_costs.sas
		03/01/2016 - Added in 8 new procedures, both sensitive and specific
		03/23/2016 - Regrouped the procedures, removed annual pap and vitamin D screening from sensitive measures
		03/31/2016 - Winsorized the cost variables at the 5th and 95th percentiles
***************************************************************************************************/


/***********************************
Set Macros
***********************************/
%let out = /disk/agedisk3/mktscan.work/sood/rabideau/Output;
%let graph = /disk/agedisk3/mktscan.work/sood/rabideau/Output;
libname dat "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
libname out "&out.";
%let windsorize = outliers; /*Can take on the value outliers, which windorizes at the 5th and 95th percentile, or median, which sets all costs to the median cost*/

proc format;
	value $proc
		'tot_lv'='Total LV Procedures'
		'tot_neuro'='All Head and Neurological Procedures'
		'tot_back'='Back Scan'
		'tot_diagnostic'='All Diagnostic Procedures'
		'tot_lv_bone'='Bone Density Testing'
		'tot_cardio'='All Cardio Procedures'
		'tot_cardio_stress'='Stress Testing for Coronary Disease'
		'tot_scan_head'='Head Imaging'
		'tot_carotid_scan_asymp'='Cartoid Scanning for Asymptomatic'
		'tot_ct_sinus'='CT for rhinosinusitus'
		'tot_homoc'='Homocysteine Testing'
		'tot_pth'='PTH testing in CKD'
		'tot_musculo'='All Musculoskeletal Procedures'
		'tot_arthro'='Arthroscopic Surgery'
		'tot_preoperative'='All Preoperative Procedures'
		'tot_scan_sync'='Head Imaging for Syncope'
		'tot_chest_x'='Preoperative Radiography'
		'tot_carotid_scan_sync'='Carotid Artery Screen for Syncope'
		'tot_coronary'='Stenting for Coronary Disease'
		'tot_renal_angio'='Renal Stenting'
		'tot_coag'='Hypercoagulability in DVT'
		'tot_pft'='Preoperative PFT'
		'tot_cancer'='All Cancer Procedures'
		'tot_eeg_head'='EEG for headache'
		'tot_stress'='Preoperative Stress Testing'
		'tot_cardio_x'='Preoperative echocardiography'
		'tot_vertebro'='Vertebroplasty'
		'tot_ivc'='IVC Filter Placement'
		'tot_carotid_end'='Carotid Endarterectomy'
		'tot_t3_test'='T3 Measurments in hypothyroidism'
		'tot_spine_inj'='Spinal injections for low back pain'
		'tot_pf_image'='Imaging for plantar fasciitis'
		'tot_OH_vitamin'='1,25 OH Vitamin Testing'
		'tot_vit_d'='Vitamin D screening'
		'tot_pap'='Annual Pap'
		'tot_cyst'='Adnexal Cyst Imaging'
		'tot_hpv'='HPV testing in women < 30'
		'tot_new'='All New Procedures'

		'tot_lv_s'='Specific Total LV Procedures'
		'tot_neuro_s'='Specific All Head and Neurological Procedures'
		'tot_back_s'='Specific Back Scan'
		'tot_diagnostic_s'='Specific All Diagnostic Procedures'
		'tot_lv_bone_s'='Specific Bone Density Testing'
		'tot_cardio_s'='Specific All Cardio Procedures'
		'tot_cardio_stress_s'='Specific Stress Testing for Coronary Disease'
		'tot_scan_head_s'='Specific Head Imaging'
		'tot_carotid_scan_asymp_s'='Specific Cartoid Scanning for Asymptomatic'
		'tot_ct_sinus_s'='Specific CT for rhinosinusitus'
		'tot_homoc_s'='Specific Homocysteine Testing'
		'tot_pth_s'='Specific PTH testing in CKD'
		'tot_musculo_s'='Specific All Musculoskeletal Proceudres'
		'tot_arthro_s'='Specific Arthroscopic Surgery'
		'tot_preoperative_s'='Specific All Preoperative Procedures'
		'tot_scan_sync_s'='Specific Head Imaging for Syncope'
		'tot_chest_x_s'='Specific Preoperative Radiography'
		'tot_carotid_scan_sync_s'='Specific Carotid Artery Screen for Syncope'
		'tot_coronary_s'='Specific Stenting for Coronary Disease'
		'tot_renal_angio_s'='Specific Renal Stenting'
		'tot_coag_s'='Specific Hypercoagulability in DVT'
		'tot_pft_s'='Specific Preoperative PFT'
		'tot_cancer_s'='Specific All Cancer Procedures'
		'tot_eeg_head_s'='Specific EEG for headache'
		'tot_stress_s'='Specific Preoperative Stress Testing'
		'tot_cardio_x_s'='Specific Preoperative echocardiography'
		'tot_vertebro_s'='Specific Vertebroplasty'
		'tot_ivc_s'='Specific IVC Filter Placement'
		'tot_carotid_end_s'='Specific Carotid Endarterectomy'
		'tot_t3_test_s'='Specific T3 Measurments in hypothyroidism'
		'tot_spine_inj_s'='Specific Spinal injections for low back pain'
		'tot_pf_image_s'='Specific Imaging for plantar fasciitis'
		'tot_OH_vitamin_s'='Specific 1,25 OH Vitamin Testing'
		'tot_vit_d_s'='Specific Vitamin D screening'
		'tot_pap_s'='Specific Annual Pap'
		'tot_cyst_s'='Specific Adnexal Cyst Imaging'
		'tot_hpv_s'='Specific HPV testing in women < 30'
		'tot_new_s'='Specific All New Procedures'
		'tot_imaging='='All Imaging Procedures'
		'tot_lv_imaging'='Low Value Imaging Procedures'
		'tot_laboratory'='All Laboratory Procedures'
		'tot_lv_laboratory'='Low Value Laboratory Procedures'
		'tot_non_inpatient'='All Non-Inpatient Procedures'
		'tot_lv_non_inpatient'='Low Value Non-Inpatient Procedures'
		'tot_less_sensitive'='LV Procs Less Sensitive to Patient Preferences'
		'tot_more_sensitive'='LV Procs More Sensitive to Patient Preferences';
run;

%macro keyvars;
   /*Any Numerators*/
   any_lv_bone any_homoc 
   any_coag any_pth any_chest_x 
   any_cardio_x any_arthro any_pft any_stress any_ct_sinus any_scan_sync any_scan_head any_eeg_head any_back 
   any_carotid_scan_asymp any_carotid_scan_sync any_cardio_stress any_coronary any_renal_angio any_carotid_end
   any_ivc any_vertebro any_neuro any_diagnostic any_preoperative any_musculo any_cardio any_lv 
   any_t3_test any_spine_inj any_pf_image any_OH_vitamin any_vit_d any_pap any_cyst any_hpv  		/*Annual Pap and Vitamind D Screening are no longer specific measures*/

   any_lv_bone_s any_homoc_s 
   any_coag_s any_pth_s any_chest_x_s 
   any_cardio_x_s any_arthro_s any_pft_s any_stress_s any_ct_sinus_s any_scan_sync_s any_scan_head_s any_eeg_head_s any_back_s 
   any_carotid_scan_asymp_s any_carotid_scan_sync_s any_cardio_stress_s any_coronary_s any_renal_angio_s any_carotid_end_s
   any_ivc_s any_vertebro_s any_neuro_s any_diagnostic_s any_preoperative_s any_musculo_s any_cardio_s any_lv_s 
   any_t3_test_s any_spine_inj_s any_pf_image_s any_OH_vitamin_s /*any_vit_d_s any_pap_s*/ any_cyst_s any_hpv_s
   any_imaging any_laboratory any_non_inpatient any_lv_imaging any_lv_laboratory any_lv_non_inpatient 
   any_less_sensitive any_more_sensitive

   /*Total Numerators*/
   tot_lv_bone tot_homoc 
   tot_coag tot_pth tot_chest_x 
   tot_cardio_x tot_arthro tot_pft tot_stress tot_ct_sinus tot_scan_sync tot_scan_head tot_eeg_head tot_back 
   tot_carotid_scan_asymp tot_carotid_scan_sync tot_cardio_stress tot_coronary tot_renal_angio tot_carotid_end
   tot_ivc tot_vertebro tot_neuro tot_diagnostic tot_preoperative tot_musculo tot_cardio tot_lv 
   tot_t3_test tot_spine_inj tot_pf_image tot_OH_vitamin tot_vit_d tot_pap tot_cyst tot_hpv

   tot_lv_bone_s tot_homoc_s 
   tot_coag_s tot_pth_s tot_chest_x_s 
   tot_cardio_x_s tot_arthro_s tot_pft_s tot_stress_s tot_ct_sinus_s tot_scan_sync_s tot_scan_head_s tot_eeg_head_s tot_back_s 
   tot_carotid_scan_asymp_s tot_carotid_scan_sync_s tot_cardio_stress_s tot_coronary_s tot_renal_angio_s tot_carotid_end_s
   tot_ivc_s tot_vertebro_s tot_neuro_s tot_diagnostic_s tot_preoperative_s tot_musculo_s tot_cardio_s tot_lv_s 
   tot_t3_test_s tot_spine_inj_s tot_pf_image_s tot_OH_vitamin_s /*tot_vit_d_s tot_pap_s*/ tot_cyst_s tot_hpv_s
   tot_imaging tot_laboratory tot_non_inpatient tot_lv_imaging tot_lv_laboratory tot_lv_non_inpatient
   tot_less_sensitive tot_more_sensitive 

   /*Denominators*/
   den_lv_bone den_homoc 
   den_coag den_pth den_chest_x 
   den_cardio_x den_arthro den_pft den_stress den_ct_sinus den_scan_sync den_scan_head den_eeg_head den_back 
   den_carotid_scan_asymp den_carotid_scan_sync den_cardio_stress den_coronary den_renal_angio den_carotid_end
   den_ivc den_vertebro den_neuro den_diagnostic den_preoperative den_musculo den_cardio den_lv 
   den_t3_test den_spine_inj den_pf_image den_OH_vitamin den_vit_d den_pap den_cyst den_hpv 

   den_lv_bone_s den_homoc_s 
   den_coag_s den_pth_s den_chest_x_s 
   den_cardio_x_s den_arthro_s den_pft_s den_stress_s den_ct_sinus_s den_scan_sync_s den_scan_head_s den_eeg_head_s den_back_s 
   den_carotid_scan_asymp_s den_carotid_scan_sync_s den_cardio_stress_s den_coronary_s den_renal_angio_s den_carotid_end_s
   den_ivc_s den_vertebro_s den_neuro_s den_diagnostic_s den_preoperative_s den_musculo_s den_cardio_s den_lv_s 
   den_t3_test_s den_spine_inj_s den_pf_image_s den_OH_vitamin_s /*den_vit_d_s den_pap_s*/ den_cyst_s den_hpv_s
   den_imaging den_laboratory den_non_inpatient den_lv_imaging den_lv_laboratory den_lv_non_inpatient 
   den_less_sensitive den_more_sensitive

   /*Standard Cost Numerators*/
   cst_lv_bone cst_homoc 
   cst_coag cst_pth cst_chest_x 
   cst_cardio_x cst_arthro cst_pft cst_stress cst_ct_sinus cst_scan_sync cst_scan_head cst_eeg_head cst_back 
   cst_carotid_scan_asymp cst_carotid_scan_sync cst_cardio_stress cst_coronary cst_renal_angio cst_carotid_end
   cst_ivc cst_vertebro cst_neuro cst_diagnostic cst_preoperative cst_musculo cst_cardio cst_lv 
   cst_t3_test cst_spine_inj cst_pf_image cst_OH_vitamin cst_vit_d cst_pap cst_cyst cst_hpv

   cst_lv_bone_s cst_homoc_s 
   cst_coag_s cst_pth_s cst_chest_x_s 
   cst_cardio_x_s cst_arthro_s cst_pft_s cst_stress_s cst_ct_sinus_s cst_scan_sync_s cst_scan_head_s cst_eeg_head_s cst_back_s 
   cst_carotid_scan_asymp_s cst_carotid_scan_sync_s cst_cardio_stress_s cst_coronary_s cst_renal_angio_s cst_carotid_end_s
   cst_ivc_s cst_vertebro_s cst_neuro_s cst_diagnostic_s cst_preoperative_s cst_musculo_s cst_cardio_s cst_lv_s 
   cst_t3_test_s cst_spine_inj_s cst_pf_image_s cst_OH_vitamin_s /*cst_vit_d_s cst_pap_s*/ cst_cyst_s cst_hpv_s
   cst_imaging cst_laboratory cst_non_inpatient cst_lv_imaging cst_lv_laboratory cst_lv_non_inpatient 
   cst_less_sensitive cst_more_sensitive

   /*Outpatient Standard Cost Numerators*/
   cst_lv_bone_op cst_homoc_op 
   cst_coag_op cst_pth_op cst_chest_x_op 
   cst_cardio_x_op cst_arthro_op cst_pft_op cst_stress_op cst_ct_sinus_op cst_scan_sync_op cst_scan_head_op cst_eeg_head_op cst_back_op 
   cst_carotid_scan_asymp_op cst_carotid_scan_sync_op cst_cardio_stress_op cst_coronary_op cst_renal_angio_op cst_carotid_end_op
   cst_ivc_op cst_vertebro_op cst_neuro_op cst_diagnostic_op cst_preoperative_op cst_musculo_op cst_cardio_op cst_lv_op 
   cst_t3_test_op cst_spine_inj_op cst_pf_image_op cst_OH_vitamin_op cst_vit_d_op cst_pap_op cst_cyst_op cst_hpv_op

   cst_lv_bone_s_op cst_homoc_s_op 
   cst_coag_s_op cst_pth_s_op cst_chest_x_s_op 
   cst_cardio_x_s_op cst_arthro_s_op cst_pft_s_op cst_stress_s_op cst_ct_sinus_s_op cst_scan_sync_s_op cst_scan_head_s_op cst_eeg_head_s_op cst_back_s_op 
   cst_carotid_scan_asymp_s_op cst_carotid_scan_sync_s_op cst_cardio_stress_s_op cst_coronary_s_op cst_renal_angio_s_op cst_carotid_end_s_op
   cst_ivc_s_op cst_vertebro_s_op cst_neuro_s_op cst_diagnostic_s_op cst_preoperative_s_op cst_musculo_s_op cst_cardio_s_op cst_lv_s_op 
   cst_t3_test_s_op cst_spine_inj_s_op cst_pf_image_s_op cst_OH_vitamin_s_op /*cst_vit_d_s_op cst_pap_s_op*/ cst_cyst_s_op cst_hpv_s_op
   cst_imaging_op cst_laboratory_op cst_non_inpatient_op cst_lv_imaging cst_lv_laboratory_op cst_lv_non_inpatient_op 
   cst_less_sensitive_op cst_more_sensitive_op

   /*Copay,Deductible, Coinsurance Cost Numerators*/
   cpy_lv_bone cpy_homoc 
   cpy_coag cpy_pth cpy_chest_x 
   cpy_cardio_x cpy_arthro cpy_pft cpy_stress cpy_ct_sinus cpy_scan_sync cpy_scan_head cpy_eeg_head cpy_back 
   cpy_carotid_scan_asymp cpy_carotid_scan_sync cpy_cardio_stress cpy_coronary cpy_renal_angio cpy_carotid_end
   cpy_ivc cpy_vertebro cpy_neuro cpy_diagnostic cpy_preoperative cpy_musculo cpy_cardio cpy_lv 
   cpy_t3_test cpy_spine_inj cpy_pf_image cpy_OH_vitamin cpy_vit_d cpy_pap cpy_cyst cpy_hpv

   cpy_lv_bone_s cpy_homoc_s 
   cpy_coag_s cpy_pth_s cpy_chest_x_s 
   cpy_cardio_x_s cpy_arthro_s cpy_pft_s cpy_stress_s cpy_ct_sinus_s cpy_scan_sync_s cpy_scan_head_s cpy_eeg_head_s cpy_back_s 
   cpy_carotid_scan_asymp_s cpy_carotid_scan_sync_s cpy_cardio_stress_s cpy_coronary_s cpy_renal_angio_s cpy_carotid_end_s
   cpy_ivc_s cpy_vertebro_s cpy_neuro_s cpy_diagnostic_s cpy_preoperative_s cpy_musculo_s cpy_cardio_s cpy_lv_s 
   cpy_t3_test_s cpy_spine_inj_s cpy_pf_image_s cpy_OH_vitamin_s /*cpy_vit_d_s cpy_pap_s*/ cpy_cyst_s cpy_hpv_s
   cpy_imaging cpy_laboratory cpy_non_inpatient cpy_lv_imaging cpy_lv_laboratory cpy_lv_non_inpatient 
   cpy_less_sensitive cpy_more_sensitive
%mend;

/*Total the number of low value procedures and beneficiaries eligible for those lv procedures at the bene-stay-physician level*/
proc sort data=dat.low_val_procs; by enrolid /*svcdate*/year; run;

proc freq data=dat.low_val_procs;
	tables non_inpatient laboratory imaging lv_non_inpatient lv_laboratory lv_imaging less_sensitive more_sensitive ;
run;

data dat.low_val_beneyear;
	set dat.low_val_procs (where=(18<=age<65));





	/*SENSITIVITY ANALYSIS - KEEP COSTS FOR ONLY Q2 AND Q3. ONLY TEMP 2-19-17 BR*/
	*if 4<=month(svcdate)<=9;








	/*Terminology - Numerator is the total number of a certain low-value procedure performed.
					Denominator is the total number of eligible patient-stays that a certain low-value procedure 
					could have been performed on*/

	/*Currently existing variables indicating claim is part of the numerator of a particular low value procedure*/
	array numer {*} lv_bone homoc coag pth chest_x cardio_x arthro pft
					stress ct_sinus scan_sync scan_head eeg_head back carotid_scan_asymp carotid_scan_sync 
					cardio_stress coronary renal_angio carotid_end ivc vertebro neuro diagnostic
				    preoperative musculo cardio lv t3_test spine_inj pf_image OH_vitamin vit_d pap cyst hpv

					lv_bone_s homoc_s coag_s pth_s chest_x_s cardio_x_s pft_s 
					stress_s ct_sinus_s scan_sync_s scan_head_s eeg_head_s back_s 
					carotid_scan_asymp_s carotid_scan_sync_s cardio_stress_s coronary_s 
					renal_angio_s carotid_end_s ivc_s vertebro_s arthro_s  
					neuro_s diagnostic_s preoperative_s musculo_s cardio_s lv_s
					t3_test_s spine_inj_s pf_image_s OH_vitamin_s /*vit_d_s pap_s*/ cyst_s hpv_s
					imaging laboratory non_inpatient lv_imaging lv_laboratory lv_non_inpatient
					less_sensitive more_sensitive;

	/*Values to be retained - indicates at least 1 claim in a stay contributed to the procedure's numerator*/
	array anynumer {*} any_lv_bone any_homoc any_coag any_pth any_chest_x 
					   any_cardio_x any_arthro any_pft any_stress any_ct_sinus any_scan_sync any_scan_head any_eeg_head any_back 
					   any_carotid_scan_asymp any_carotid_scan_sync any_cardio_stress any_coronary any_renal_angio any_carotid_end 
					   any_ivc any_vertebro any_neuro any_diagnostic any_preoperative any_musculo any_cardio any_lv 
					   any_t3_test any_spine_inj any_pf_image any_OH_vitamin any_vit_d any_pap any_cyst any_hpv

					   any_lv_bone_s any_homoc_s any_coag_s any_pth_s any_chest_x_s any_cardio_x_s any_pft_s 
					   any_stress_s any_ct_sinus_s any_scan_sync_s any_scan_head_s any_eeg_head_s any_back_s 
					   any_carotid_scan_asymp_s any_carotid_scan_sync_s any_cardio_stress_s any_coronary_s 
					   any_renal_angio_s any_carotid_end_s any_ivc_s any_vertebro_s any_arthro_s 
					   any_neuro_s any_diagnostic_s any_preoperative_s any_musculo_s any_cardio_s any_lv_s
					   any_t3_test_s any_spine_inj_s any_pf_image_s any_OH_vitamin_s /*any_vit_d_s any_pap_s*/ any_cyst_s any_hpv_s
					   any_imaging any_laboratory any_non_inpatient any_lv_imaging any_lv_laboratory any_lv_non_inpatient
					   any_less_sensitive any_more_sensitive;

	/*Values to be retained - total the number of claims in a stay that contributed to the procedure's numerator*/
	array totnumer {*} tot_lv_bone tot_homoc tot_coag tot_pth tot_chest_x 
					   tot_cardio_x tot_arthro tot_pft tot_stress tot_ct_sinus tot_scan_sync tot_scan_head tot_eeg_head tot_back 
					   tot_carotid_scan_asymp tot_carotid_scan_sync tot_cardio_stress tot_coronary tot_renal_angio tot_carotid_end 
					   tot_ivc tot_vertebro tot_neuro tot_diagnostic tot_preoperative tot_musculo tot_cardio tot_lv
					   tot_t3_test tot_spine_inj tot_pf_image tot_OH_vitamin tot_vit_d tot_pap tot_cyst tot_hpv

					   tot_lv_bone_s tot_homoc_s tot_coag_s tot_pth_s tot_chest_x_s tot_cardio_x_s tot_pft_s 
					   tot_stress_s tot_ct_sinus_s tot_scan_sync_s tot_scan_head_s tot_eeg_head_s tot_back_s 
					   tot_carotid_scan_asymp_s tot_carotid_scan_sync_s tot_cardio_stress_s tot_coronary_s 
					   tot_renal_angio_s tot_carotid_end_s tot_ivc_s tot_vertebro_s tot_arthro_s 
					   tot_neuro_s tot_diagnostic_s tot_preoperative_s tot_musculo_s tot_cardio_s tot_lv_s
					   tot_t3_test_s tot_spine_inj_s tot_pf_image_s tot_OH_vitamin_s /*tot_vit_d_s tot_pap_s*/ tot_cyst_s tot_hpv_s
					   tot_imaging tot_laboratory tot_non_inpatient tot_lv_imaging tot_lv_laboratory tot_lv_non_inpatient
					   tot_less_sensitive tot_more_sensitive;

	/*Currently existing variables indicating claim is part of the denominator of a particular low value procedure*/
	array denom {*} lv_bone_den homoc_den coag_den pth_den chest_x_den cardio_x_den arthro_den pft_den stress_den ct_sinus_den 
					scan_sync_den scan_head_den eeg_head_den back_den carotid_scan_asymp_den carotid_scan_sync_den 
					cardio_stress_den coronary_den renal_angio_den carotid_end_den ivc_den vertebro_den 
					neuro_den diagnostic_den preoperative_den musculo_den cardio_den lv_den 
					t3_test_den spine_inj_den pf_image_den OH_vitamin_den vit_d_den pap_den cyst_den hpv_den

					lv_bone_den_s homoc_den_s coag_den_s pth_den_s chest_x_den_s cardio_x_den_s pft_den_s stress_den_s 
					ct_sinus_den_s scan_sync_den_s scan_head_den_s eeg_head_den_s back_den_s carotid_scan_asymp_den_s 
					carotid_scan_sync_den_s cardio_stress_den_s coronary_den_s renal_angio_den_s carotid_end_den_s 
					ivc_den_s vertebro_den_s arthro_den_s neuro_den_s diagnostic_den_s preoperative_den_s 
					musculo_den_s cardio_den_s lv_den_s 
					t3_test_den_s spine_inj_den_s pf_image_den_s OH_vitamin_den_s /*vit_d_den_s pap_den_s*/ cyst_den_s hpv_den_s
				    imaging_den laboratory_den non_inpatient_den lv_imaging_den lv_laboratory_den lv_non_inpatient_den
				    less_sensitive_den more_sensitive_den;

	/*Value to be retained - indicates at least 1 claim in a stay contributed to the procedure's denominator*/
	array anydenom {*} den_lv_bone den_homoc den_coag den_pth den_chest_x 
					   den_cardio_x den_arthro den_pft den_stress den_ct_sinus den_scan_sync den_scan_head den_eeg_head den_back 
					   den_carotid_scan_asymp den_carotid_scan_sync den_cardio_stress den_coronary den_renal_angio den_carotid_end 
					   den_ivc den_vertebro den_neuro den_diagnostic den_preoperative den_musculo den_cardio den_lv
					   den_t3_test den_spine_inj den_pf_image den_OH_vitamin den_vit_d den_pap den_cyst den_hpv

					   den_lv_bone_s den_homoc_s den_coag_s den_pth_s den_chest_x_s den_cardio_x_s den_pft_s 
					   den_stress_s den_ct_sinus_s den_scan_sync_s den_scan_head_s den_eeg_head_s den_back_s 
					   den_carotid_scan_asymp_s den_carotid_scan_sync_s den_cardio_stress_s den_coronary_s 
					   den_renal_angio_s den_carotid_end_s den_ivc_s den_vertebro_s den_arthro_s 
					   den_neuro_s den_diagnostic_s den_preoperative_s den_musculo_s den_cardio_s den_lv_s
					   den_t3_test_s den_spine_inj_s den_pf_image_s den_OH_vitamin_s /*den_vit_d_s den_pap_s*/ den_cyst_s den_hpv_s
					   den_imaging den_laboratory den_non_inpatient den_lv_imaging den_lv_laboratory den_lv_non_inpatient
					   den_less_sensitive den_more_sensitive;

	/*Values to be retained - total standard costs of claims that contributed to the procedure's numerator*/
	array cstnumer {*} cst_lv_bone cst_homoc cst_coag cst_pth cst_chest_x 
					   cst_cardio_x cst_arthro cst_pft cst_stress cst_ct_sinus cst_scan_sync cst_scan_head cst_eeg_head cst_back 
					   cst_carotid_scan_asymp cst_carotid_scan_sync cst_cardio_stress cst_coronary cst_renal_angio cst_carotid_end 
					   cst_ivc cst_vertebro cst_neuro cst_diagnostic cst_preoperative cst_musculo cst_cardio cst_lv 
					   cst_t3_test cst_spine_inj cst_pf_image cst_OH_vitamin cst_vit_d cst_pap cst_cyst cst_hpv

					   cst_lv_bone_s cst_homoc_s cst_coag_s cst_pth_s cst_chest_x_s cst_cardio_x_s cst_pft_s 
					   cst_stress_s cst_ct_sinus_s cst_scan_sync_s cst_scan_head_s cst_eeg_head_s cst_back_s 
					   cst_carotid_scan_asymp_s cst_carotid_scan_sync_s cst_cardio_stress_s cst_coronary_s 
					   cst_renal_angio_s cst_carotid_end_s cst_ivc_s cst_vertebro_s cst_arthro_s 
					   cst_neuro_s cst_diagnostic_s cst_preoperative_s cst_musculo_s cst_cardio_s cst_lv_s
					   cst_t3_test_s cst_spine_inj_s cst_pf_image_s cst_OH_vitamin_s /*cst_vit_d_s cst_pap_s*/ cst_cyst_s cst_hpv_s
					   cst_imaging cst_laboratory cst_non_inpatient cst_lv_imaging cst_lv_laboratory cst_lv_non_inpatient
					   cst_less_sensitive cst_more_sensitive;

	/*Values to be retained - total standard costs of claims that contributed to the procedure's numeratorin the outpatient setting only*/
	array cstop {*} cst_lv_bone_op cst_homoc_op cst_coag_op cst_pth_op cst_chest_x_op cst_cardio_x_op cst_arthro_op cst_pft_op
					cst_stress_op cst_ct_sinus_op cst_scan_sync_op cst_scan_head_op cst_eeg_head_op cst_back_op cst_carotid_scan_asymp_op cst_carotid_scan_sync_op
					cst_cardio_stress_op cst_coronary_op cst_renal_angio_op cst_carotid_end_op cst_ivc_op cst_vertebro_op cst_neuro_op cst_diagnostic_op
				    cst_preoperative_op cst_musculo_op cst_cardio_op cst_lv_op cst_t3_test_op cst_spine_inj_op cst_pf_image_op cst_OH_vitamin_op cst_vit_d_op 
					cst_pap_op cst_cyst_op cst_hpv_op

					cst_lv_bone_s_op cst_homoc_s_op cst_coag_s_op cst_pth_s_op cst_chest_x_s_op cst_cardio_x_s_op cst_pft_s_op
					cst_stress_s_op cst_ct_sinus_s_op cst_scan_sync_s_op cst_scan_head_s_op cst_eeg_head_s_op cst_back_s_op
					cst_carotid_scan_asymp_s_op cst_carotid_scan_sync_s_op cst_cardio_stress_s_op cst_coronary_s_op
					cst_renal_angio_s_op cst_carotid_end_s_op cst_ivc_s_op cst_vertebro_s_op cst_arthro_s_op
					cst_neuro_s_op cst_diagnostic_s_op cst_preoperative_s_op cst_musculo_s_op cst_cardio_s_op cst_lv_s_op
					cst_t3_test_s_op cst_spine_inj_s_op cst_pf_image_s_op cst_OH_vitamin_s_op /*vit_d_s_op cst_pap_s*/ cst_cyst_s_op cst_hpv_s_op
					cst_imaging_op cst_laboratory_op cst_non_inpatient_op cst_lv_imaging_op cst_lv_laboratory_op cst_lv_non_inpatient_op
					cst_less_sensitive_op cst_more_sensitive_op;

	/*Values to be retained - total out of pocket costs of claims that contributed to the procedure's numerator*/
	array cpynumer {*} cpy_lv_bone cpy_homoc cpy_coag cpy_pth cpy_chest_x 
					   cpy_cardio_x cpy_arthro cpy_pft cpy_stress cpy_ct_sinus cpy_scan_sync cpy_scan_head cpy_eeg_head cpy_back 
					   cpy_carotid_scan_asymp cpy_carotid_scan_sync cpy_cardio_stress cpy_coronary cpy_renal_angio cpy_carotid_end 
					   cpy_ivc cpy_vertebro cpy_neuro cpy_diagnostic cpy_preoperative cpy_musculo cpy_cardio cpy_lv
					   cpy_t3_test cpy_spine_inj cpy_pf_image cpy_OH_vitamin cpy_vit_d cpy_pap cpy_cyst cpy_hpv

					   cpy_lv_bone_s cpy_homoc_s cpy_coag_s cpy_pth_s cpy_chest_x_s cpy_cardio_x_s cpy_pft_s 
					   cpy_stress_s cpy_ct_sinus_s cpy_scan_sync_s cpy_scan_head_s cpy_eeg_head_s cpy_back_s 
					   cpy_carotid_scan_asymp_s cpy_carotid_scan_sync_s cpy_cardio_stress_s cpy_coronary_s 
					   cpy_renal_angio_s cpy_carotid_end_s cpy_ivc_s cpy_vertebro_s cpy_arthro_s 
					   cpy_neuro_s cpy_diagnostic_s cpy_preoperative_s cpy_musculo_s cpy_cardio_s cpy_lv_s
					   cpy_t3_test_s cpy_spine_inj_s cpy_pf_image_s cpy_OH_vitamin_s /*cpy_vit_d_s cpy_pap_s*/ cpy_cyst_s cpy_hpv_s
					   cpy_imaging cpy_laboratory cpy_non_inpatient cpy_lv_imaging cpy_lv_laboratory cpy_lv_non_inpatient
					   cpy_less_sensitive cpy_more_sensitive;

	retain %keyvars tot_procs all_costs;

	by enrolid /*svcdate*/year;

	/*Reset the variables of interest to 0 for each new patient-stay-physician*/
	if first.year then do;
		do i=1 to dim(anynumer);
			anynumer[i]=0;
			totnumer[i]=0;
			anydenom[i]=0;
			*cstnumer[i]=0;
			cstop[i]   =0;
			cpynumer[i]=0;
		end;
		tot_procs=0;
		all_costs=0;
	end;

	/*Populate the variables of interest where appropriate*/
	do j=1 to dim(numer);
		if numer[j]>=1 then anynumer[j]=1;
		if numer[j]>=1 then totnumer[j]+numer[j];
		if denom[j]>=1 then anydenom[j]=1;
		*if numer[j]>=1 then cstnumer[j]=sum(cstnumer[j],pay); 
		if numer[j]>=1 & non_inpatient=1 then cstop[j]=sum(cstop[j],pay); /*Calculate the total outpatient costs for each procedure*/
		*if numer[j]>=1 then cpynumer[j]=sum(cpynumer[j],copay,deduct,coins);

	end;
	tot_procs+1;
	all_costs=sum(all_costs,pay);

	/*After aggregating to the patient-year level, output*/
	if last.year then output;
run;

title "Check Distribution of Outcome Vars";
proc univariate data=dat.low_val_beneyear;
	var cst_imaging_op cst_laboratory_op cst_non_inpatient_op cst_lv_imaging_op cst_lv_laboratory_op cst_less_sensitive_op cst_more_sensitive_op;
run;
title;

proc means data=dat.low_val_beneyear;
	vars all_costs cst_lv;
	output out=sum1 sum=;
run;

/*Merge on the special costs for select procedures with additional pricing codes. This dataset comes from calc_costs.sas*/
data dat.low_val_beneyear;
	merge dat.low_val_beneyear 
		 (drop=cst_homoc cst_coag cst_pth	
		  cst_cardio_x cst_pft cst_cardio_stress cst_stress cst_coronary cst_ivc
	      cst_homoc_s cst_coag_s cst_pth cst_cardio_x_s cst_pft_s cst_cardio_stress_s cst_stress_s cst_coronary_s 
		  cst_ivc_s cst_arthro cst_vertebro cst_spine_inj cst_renal_angio cst_arthro_s cst_vertebro_s 
		  cst_renal_angio_s cst_carotid_end cst_carotid_end_s

		  cst_homoc_op cst_coag_op cst_pth_op cst_cardio_x_op cst_pft_op cst_cardio_stress_op cst_stress_op cst_ivc_op
	      cst_homoc_s_op cst_coag_s_op cst_pth_op cst_cardio_x_s_op cst_pft_s_op cst_cardio_stress_s_op cst_stress_s_op 
		  cst_ivc_s_op cst_arthro_op cst_vertebro_op cst_spine_inj_op cst_renal_angio_op cst_arthro_s_op cst_vertebro_s_op 
		  cst_renal_angio_s_op) /*These variables were recreated in the costs_totalled dataset that is being merged on*/

		  dat.costs_totalled;
	by enrolid year;
run;

proc means data=dat.low_val_beneyear;
	vars all_costs cst_lv;
	output out=sum2 sum=;
run;


proc sort data=dat.low_val_beneyear; by enrolid; run;

/*Winsorize the cost data - All costs within a procedures < cost of the 5th percentile becomes 5th percentile,
  all costs within a procedure > cost of 95th percentile become 95th percentile.*/
%macro winsorize(var);
	%if "&windsorize."="outliers" %then %do;
		/*Determine the 5th and 95th percentile costs for each procedure*/
		proc univariate data=dat.low_val_beneyear;
			var cst_&var.;
			where cst_&var.>0 & cst_&var.~=.;
			ods output quantiles=univ_&var.;
		run;

		%if %sysfunc(exist(univ_&var.))=1 %then %do;
			proc contents data=univ_&var.; run;
			
			data _NULL_;
				set univ_&var.;
				if trim(left(quantile))='5%' then call symput("&var._5",Estimate);
				if trim(left(quantile))='95%' then call symput("&var._95",Estimate);
			run;
			/*Apply the 5th and 95th percentile costs to outliers*/
			data dat.low_val_beneyear;
				set dat.low_val_beneyear;
				if cst_&var.~=. & cst_&var.~=0 & cst_&var.<&&&var._5. then cst_&var.=&&&var._5.; /*If the cost is below the 5th percentile for this procedure, set it to the 5th percentile*/
				if cst_&var.~=. & cst_&var.~=0 & cst_&var.>&&&var._95. then cst_&var.=&&&var._95.; /*If the cost is above the 95th percentile for this procedure, set it to the 95th percentile*/
			run;

			/*Check to see if the costs have been winsorized*/
			proc univariate data=dat.low_val_beneyear;
				var cst_&var.;
				where cst_&var.>0 & cst_&var.~=.;
			run;
		%end;
	%end;

	%else %if "&windsorize."="median" %then %do;
		/*Determine the 5th and 95th percentile costs for each procedure*/
		proc univariate data=dat.low_val_beneyear;
			var cst_&var.;
			where cst_&var.>0 & cst_&var.~=.;
			ods output quantiles=univ_&var.;
		run;

		%if %sysfunc(exist(univ_&var.))=1 %then %do;
			proc contents data=univ_&var.; run;
			
			data _NULL_;
				set univ_&var.;
				if trim(left(quantile))='50% Median' then call symput("&var._50",Estimate);
			run;
			/*Apply the median cost to all*/
			data dat.low_val_beneyear;
				set dat.low_val_beneyear;
				if cst_&var.~=. & cst_&var.>0 then cst_&var.=&&&var._50.; /*If the bene incurred a cost for a given proc, set it to the 50th percentile*/
			run;

			/*Check to see if the costs have been winsorized*/
			proc univariate data=dat.low_val_beneyear;
				var cst_&var.;
				where cst_&var.>0 & cst_&var.~=.;
			run;
		%end;
	%end;

	%else PUTLOG 'Please specify either median or outliers for the macrovariable windsorize';
%mend;
/*%winsorize(lv_bone_op);
%winsorize(homoc_op);
%winsorize(coag_op);
%winsorize(pth_op);
%winsorize(chest_x_op);
%winsorize(cardio_x_op);
%winsorize(pft_op); 
%winsorize(stress_op);
%winsorize(ct_sinus_op);
%winsorize(scan_sync_op);
%winsorize(scan_head_op);
%winsorize(eeg_head_op);
%winsorize(back_op);
%winsorize(carotid_scan_asymp_op);
%winsorize(carotid_scan_sync_op);
%winsorize(cardio_stress_op);
%winsorize(coronary_op);
%winsorize(renal_angio_op);
%winsorize(carotid_end_op);
%winsorize(ivc_op);
%winsorize(vertebro_op);
%winsorize(arthro_op);
%winsorize(t3_test_op);
%winsorize(spine_inj_op);
%winsorize(pf_image_op);
%winsorize(OH_vitamin_op);
%winsorize(vit_d_op);
%winsorize(pap_op);
%winsorize(cyst_op);
%winsorize(hpv_op);*/

%winsorize(lv_bone_s_op);
%winsorize(homoc_s_op);
%winsorize(coag_s_op);
%winsorize(pth_s_op);
%winsorize(chest_x_s_op);
%winsorize(cardio_x_s_op);
%winsorize(pft_s_op); 
%winsorize(stress_s_op);
%winsorize(ct_sinus_s_op);
%winsorize(scan_sync_s_op);
%winsorize(scan_head_s_op);
%winsorize(eeg_head_s_op);
%winsorize(back_s_op);
%winsorize(carotid_scan_asymp_s_op);
%winsorize(carotid_scan_sync_s_op);
%winsorize(cardio_stress_s_op);
%winsorize(coronary_s_op);
%winsorize(renal_angio_s_op);
%winsorize(carotid_end_s_op);
%winsorize(ivc_s_op);
%winsorize(vertebro_s_op);
%winsorize(arthro_s_op);
%winsorize(t3_test_s_op);
%winsorize(spine_inj_s_op);
%winsorize(pf_image_s_op);
%winsorize(OH_vitamin_s_op);
*%winsorize(vit_d_s_op);
*%winsorize(pap_s_op);
%winsorize(cyst_s_op);
%winsorize(hpv_s_op);
%winsorize(imaging_op);
%winsorize(laboratory_op);
%winsorize(non_inpatient_op);
%winsorize(lv_imaging_op);
%winsorize(lv_laboratory_op);
%winsorize(lv_non_inpatient_op);
%winsorize(less_sensitive_op);
%winsorize(more_sensitive_op);

data dat.low_val_beneyear;
	set dat.low_val_beneyear;
	/*The aggregate measures get changed with the updated costs. Re-sum them up here*/
	cst_neuro=sum(cst_ct_sinus,cst_scan_sync,cst_scan_head,cst_eeg_head);

	cst_diagnostic=sum(cst_t3_test,cst_OH_vitamin,cst_vit_d,cst_pap,cst_cyst,cst_hpv,cst_coag,cst_homoc,cst_pth);

	cst_preoperative=sum(cst_chest_x,cst_cardio_x,cst_pft,cst_stress);

	cst_musculo=sum(cst_spine_inj,cst_pf_image,cst_back,cst_lv_bone,cst_arthro,cst_vertebro);

	cst_cardio=sum(cst_cardio_stress,cst_coronary,cst_renal_angio,cst_carotid_end,cst_ivc,cst_carotid_scan_asymp,
				   cst_carotid_scan_sync);

	cst_lv=sum(cst_lv_bone,cst_homoc,cst_coag,cst_pth,cst_chest_x,
			   cst_cardio_x,cst_arthro,cst_pft,cst_stress,cst_ct_sinus,cst_scan_sync,cst_scan_head,cst_eeg_head,cst_back,
			   cst_carotid_scan_asymp,cst_carotid_scan_sync,cst_cardio_stress,cst_coronary,cst_renal_angio,cst_carotid_end,
			   cst_ivc,cst_vertebro,cst_t3_test,cst_spine_inj,cst_pf_image,cst_OH_vitamin,cst_vit_d,cst_pap,cst_cyst,cst_hpv);


	cst_neuro_s=sum(cst_ct_sinus_s,cst_scan_sync_s,cst_scan_head_s,cst_eeg_head_s);

	cst_diagnostic_s=sum(cst_t3_test_s,cst_OH_vitamin_s,/*cst_vit_d_s,cst_pap_s*/cst_cyst_s,cst_hpv_s,cst_coag_s,cst_homoc_s,cst_pth_s);

	cst_preoperative_s=sum(cst_chest_x_s,cst_cardio_x_s,cst_pft_s,cst_stress_s);

	cst_musculo_s=sum(cst_spine_inj_s,cst_pf_image_s,cst_back_s,cst_lv_bone_s,cst_arthro_s,cst_vertebro_s);

	cst_cardio_s=sum(cst_cardio_stress_s,cst_coronary_s,cst_renal_angio_s,cst_carotid_end_s,cst_ivc_s,cst_carotid_scan_asymp_s,
				     cst_carotid_scan_sync_s);

	cst_lv_s=sum(cst_lv_bone_s,cst_homoc_s,cst_coag_s,cst_pth_s,cst_chest_x_s,
		cst_cardio_x_s,cst_arthro_s,cst_pft_s,cst_stress_s,cst_ct_sinus_s,
		cst_scan_sync_s,cst_scan_head_s,cst_eeg_head_s,cst_back_s,cst_carotid_scan_asymp_s,cst_carotid_scan_sync_s,
		cst_cardio_stress_s,cst_coronary_s,cst_renal_angio_s,cst_carotid_end_s,
		cst_ivc_s,cst_vertebro_s,cst_t3_test_s,cst_spine_inj_s,cst_pf_image_s,cst_OH_vitamin_s,/*cst_vit_d_s,cst_pap_s,*/cst_cyst_s,
		cst_hpv_s); /*Annual Pap and Vitamind D Screening are not specific measures*/





	/*These are our aggregate cost outcomes for the CDHP project. Resum them now since we have updated cost variables for some procedures.
	  Updated costs come from calc_costs.sas and are merged in above in the dataset called costs_totalled.sas7bdat*/

	/*Low-value non-inpatient costs are just all LV costs not accrued in a hospital and not stenting for CAD or carotid endarterectomy*/
	cst_lv_non_inpatient=sum(cst_lv_bone_s_op,cst_homoc_s_op,cst_coag_s_op,cst_pth_s_op,cst_chest_x_s_op,
		cst_cardio_x_s_op,cst_arthro_s_op,cst_pft_s_op,cst_stress_s_op,cst_ct_sinus_s_op,cst_scan_sync_s_op,cst_scan_head_s_op,
		cst_eeg_head_s_op,cst_back_s_op,cst_carotid_scan_asymp_s_op,cst_carotid_scan_sync_s_op,cst_cardio_stress_s_op,
		cst_renal_angio_s_op,cst_ivc_s_op,cst_vertebro_s_op,cst_t3_test_s_op,cst_spine_inj_s_op,cst_pf_image_s_op,cst_OH_vitamin_s_op,
		cst_cyst_s_op,cst_hpv_s_op);

	/*These are low-value imaging measures selected by Rachel Reid*/
	  /*1.	Stress testing  (Note: not all included CPTs are imaging ones)
		2.	Carotid Screen Asx (Note: not all included CPTs are imaging ones)
		3.	Carotid Screen Syncope (Note: not all included CPTs are imaging ones)
		4.	Adnexal Cyst
		5.	Sinus CT
		6.	Head Imaging for Syncope
		7.	Head Imaging for Headache
		8.	Back Scan
		9.	Plantar Fasciitis Testing
		10.	Bone Density Testing
		11.	Preop CXR
		12.	Preop Stress testing (note: Not all included CPTs are imaging ones)*/
	cst_lv_imaging=sum(cst_stress_s_op,cst_carotid_scan_asymp_s_op,cst_carotid_scan_sync_s_op,cst_cyst_s_op,cst_ct_sinus_s_op,
		cst_scan_sync_s_op,cst_scan_head_s_op,cst_back_s_op,cst_pf_image_s_op,cst_lv_bone_s_op,cst_chest_x_s_op,cst_cardio_stress_s_op);

	/*These are low-value laboratory measures selected by Rachel Reid*/
	  /*1.	Vitamin D
		2.	Hypercoag Testing
		3.	Homocysteine testing
		4.	HPV Testing
		5.	PTH Testing
		6.	T3 testing*/
	cst_lv_laboratory=sum(cst_vit_d,cst_coag_s_op,cst_homoc_s_op,cst_hpv_s_op,cst_pth_s_op,cst_t3_test_s_op);

	/*These measures are less sensitive to patient preferences - Only looking at the specific measures. Selected by Rachel Reid*/
		/*•	Bone Mineral Density testing at Frequent Intervals
		•	Homocysteine testing in cardiovascular disease
		•	Hypercoagulability testing for patients with VTE
		•	PTH measurement for patients with stage 1-3 CKD
		•	T3 testing for patients with hypothyroidism
		•	1,25 OH vitamin D testing in the absence of hypercalcemia or decreased kidney function
		•	Pre Op CXR
		•	Pre Op Echo
		•	Pre Op PFT
		•	Pre Op Routine Stress Test
		•	EEG for headaches
		•	Screening for Carotid Artery Disease in Asymptomatic Adults
		•	Screening for Carotid Artery Disease in for syncope
		•	Renal artery angioplasty or stenting
		•	Carotid endarterectomy for asymtomacit patients
		•	IVC Filter to prevent Pes
		•	Vertebroplasty or kyphoplasty for osteoporotic fractures
		•	HPV testing younger than 30 years
		•	Imaging for adnexal cyst*/
	cst_less_sensitive=sum(cst_lv_bone_s_op,cst_homoc_s_op,cst_coag_s_op,cst_pth_s_op,cst_t3_test_s_op,cst_OH_vitamin_s_op,cst_chest_x_s_op,
		cst_cardio_x_s_op,cst_pft_s_op,cst_stress_s_op,cst_eeg_head_s_op,cst_carotid_scan_asymp_s_op,cst_carotid_scan_sync_s_op,
		cst_renal_angio_s_op,cst_carotid_end_s_op,cst_ivc_s_op,cst_vertebro_s_op,cst_hpv_s_op,cst_cyst_s_op);

	/*These measures are more sensitive to patient preferences - Only looking at the specific measures. Selected by Rachel Reid*/
		/*•	CT of sinuses for uncomplicated acute rhinosinusitis
		•	Head imaging in the evaluation of syncope
		•	Head imaging in the evaluation of uncomplicated headache
		•	Back imaging for patients with nonspecific low back pain
		•	Imaging for diagnosis of plantar fasciitis
		•	Stress testing for stable coronary artery disease
		•	PCI for stable coronary artery disease
		•	Arthroscopic surgery for knee OA
		•	Spinal injections for low back pain*/
	cst_more_sensitive=sum(cst_ct_sinus_s_op,cst_scan_sync_s_op,cst_scan_head_s_op,cst_back_s_op,cst_pf_image_s_op,cst_cardio_stress_s_op,
		cst_coronary_s_op,cst_arthro_s_op,cst_spine_inj_s_op);
run;

title "Check Distribution of Outcome Vars";
proc univariate data=dat.low_val_beneyear;
	var cst_imaging cst_laboratory cst_non_inpatient cst_lv_imaging cst_lv_laboratory cst_less_sensitive cst_more_sensitive;
run;
title;

/*Create 'total' and 'any' vars for each lv procedure*/
data lv_beneyear;
	set dat.low_val_beneyear;
	%macro prop(proc);
		if den_&proc.~=0 then prop&proc.=&proc./den_&proc.;
		if den_&proc.~=0 then proptot_&proc.=tot_&proc./den_&proc.;
	%mend;
	%prop(lv_bone);
	%prop(homoc);
	%prop(coag);
	%prop(pth);
	%prop(chest_x);
	%prop(cardio_x);
	%prop(pft); 
	%prop(stress);
	%prop(ct_sinus);
	%prop(scan_sync);
	%prop(scan_head);
	%prop(eeg_head);
	%prop(back);
	%prop(carotid_scan_asymp);
	%prop(carotid_scan_sync);
	%prop(cardio_stress);
	%prop(coronary);
	%prop(renal_angio);
	%prop(carotid_end);
	%prop(ivc);
	%prop(vertebro);
	%prop(arthro);
	%prop(neuro);
	%prop(diagnostic);
	%prop(preoperative);
	%prop(musculo);
	%prop(cardio);
	%prop(lv);
	%prop(t3_test);
	%prop(spine_inj);
	%prop(pf_image);
	%prop(OH_vitamin);
	%prop(vit_d);
	%prop(pap);
	%prop(cyst);
	%prop(hpv);

	%prop(lv_bone_s);
	%prop(homoc_s);
	%prop(coag_s);
	%prop(pth_s);
	%prop(chest_x_s);
	%prop(cardio_x_s);
	%prop(pft_s); 
	%prop(stress_s);
	%prop(ct_sinus_s);
	%prop(scan_sync_s);
	%prop(scan_head_s);
	%prop(eeg_head_s);
	%prop(back_s);
	%prop(carotid_scan_asymp_s);
	%prop(carotid_scan_sync_s);
	%prop(cardio_stress_s);
	%prop(coronary_s);
	%prop(renal_angio_s);
	%prop(carotid_end_s);
	%prop(ivc_s);
	%prop(vertebro_s);
	%prop(arthro_s);
	%prop(neuro_s);
	%prop(diagnostic_s);
	%prop(preoperative_s);
	%prop(musculo_s);
	%prop(cardio_s);
	%prop(lv_s);
	%prop(t3_test_s);
	%prop(spine_inj_s);
	%prop(pf_image_s);
	%prop(OH_vitamin_s);
	*%prop(vit_d_s);
	*%prop(pap_s);
	%prop(cyst_s);
	%prop(hpv_s);
	%prop(imaging);
	%prop(laboratory);
	%prop(non_inpatient);
	%prop(lv_imaging);
	%prop(lv_laboratory);
	%prop(lv_non_inpatient);
	%prop(less_sensitive);
	%prop(more_sensitive);
run;

/*Collapse down to the year level*/
proc means data=lv_beneyear nway noprint;
	class year;
	var %keyvars tot_procs;
	output out=lv_year sum=;
run;

/*Create the low value procedure proportions for each individual lv procedure*/
data lv_year;
	set lv_year (drop=_TYPE_ rename=(_FREQ_=tot_patients));
run;

/*Transpose the data to make it more manageable*/
proc transpose data=lv_year out=year_xpose name=Procedure prefix=year;
 id year;
 var tot_procs tot_patients %keyvars;
run;

/*Group the data to make building a table less of a manual effort*/
data year_xpose;
	length LV_Group $100;
	set year_xpose;

	/*Neuro*/
	if prxmatch("/ct_sinus/",procedure)>0 | prxmatch("/scan_sync/",procedure)>0 | prxmatch("/scan_head/",procedure)>0 |
	   prxmatch("/eeg_head/",procedure)>0 
	   then LV_Group="Head and Neurologic Diagnostic Imaging and Testing";



	/*Diagnostic*/
	if prxmatch("/homoc/",procedure)>0 | prxmatch("/coag/",procedure)>0 |
	   prxmatch("/t3/",procedure)>0 | prxmatch("/hpv/",procedure)>0 | prxmatch("/cyst/",procedure)>0 |
	   prxmatch("/pap/",procedure)>0 | prxmatch("/vit_d/",procedure)>0 | prxmatch("/vitamin/",procedure)>0 |
	   prxmatch("/pth/",procedure)>0
	   then LV_Group="Diagnostic and Preventive Testing";


	/*Cardio*/
	if prxmatch("/cardio_stress/",procedure)>0 | prxmatch("/coronary/",procedure)>0 | prxmatch("/renal_angio/",procedure)>0 |
	   prxmatch("/carotid_end/",procedure)>0  | prxmatch("/ivc/",procedure)>0 | prxmatch("/carotid_scan/",procedure)>0 
	   then LV_Group="Cardiovascular Testing and Procedures";


	/*Preoperative*/
	if prxmatch("/chest_x/",procedure)>0 | prxmatch("/cardio_x/",procedure)>0 | prxmatch("/pft/",procedure)>0 |
	   (prxmatch("/stress/",procedure)>0 & prxmatch("/cardio/",procedure)=0)
	   then LV_Group="Preoperative Testing";


	/*Musculo*/
	if prxmatch("/back/",procedure)>0 | prxmatch("/bone/",procedure)>0 | prxmatch("/vertebro/",procedure)>0 | 
	   prxmatch("/arthro/",procedure)>0 | prxmatch("/spine/",procedure)>0 | prxmatch("/pf_image/",procedure)>0
	   then LV_Group="Musculoskeletal Diagnostic Testing and Procedures";

	/*General*/
	if prxmatch("/physicians/",procedure)>0 | prxmatch("/tot_procs/",procedure)>0 | prxmatch("/bene_stays/",procedure)>0 |
	   prxmatch("/tot_patients/",procedure)>0  then LV_Group="_General"; 

	sorter=substr(procedure,1,3);

	format procedure $proc.;
run;

proc sort data=year_xpose; by sorter LV_Group Procedure; run;

/*********************
PRINT CHECK
*********************/
/*Output a sample of each of the datasets to an excel workbook*/
ods tagsets.excelxp file="&out./year_num_denom_cdhp.xml" style=sansPrinter;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Claim Level" frozen_headers='yes');
proc print data=out.low_val_procs (obs=100);
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Bene-Stay-Physician Level" frozen_headers='yes');
proc print data=out.low_val_beneyear_stay (obs=100);
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Beneneficiary Level" frozen_headers='yes');
proc print data=lv_beneyear (obs=100);
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Year Level" frozen_headers='yes');
proc print data=lv_year (obs=100);
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Year Transposed" frozen_headers='yes');
proc print data=year_xpose (obs=100);
run;
ods tagsets.excelxp close;
/*********************
CHECK END
*********************/






		   
