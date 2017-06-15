/*********************************************************************************************
 The purpose of this program is to create more sophisticated measures of cost for select low
 value procedures according to the recommendations of Dr. Rachel Reid. These improvements 
 include capturing all costs on the same day for procedures that are accompanied by several
 varied complementary services, select costs on the same day for procedures that always have 
 predictable complementary services, and all costs within the same hospitalization for services
 that necessitate an entire stay's worth of services. 

 The costs are collapsed down to the bene-year level, and merged back onto the main dataset in 
 the next program, year_num_denom.sas. In addition to updating our cost measures, this program
 also outputs a workbook with the frequencies and average costs of the additional procedures that 
 are being incorporated into our updated cost measure for documentation purposes.
*********************************************************************************************/

libname dat "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";

data low_value_costs;
	set dat.low_val_procs 
	(keep=enrolid svcdate /*conf_id*/ year diag: proc: pay age gdr_cd non_inpatient
 
		   lv_bone homoc 
		   coag pth chest_x 
		   cardio_x arthro pft stress ct_sinus scan_sync scan_head eeg_head back 
		   carotid_scan_asymp carotid_scan_sync cardio_stress coronary renal_angio carotid_end
		   ivc vertebro neuro diagnostic preoperative musculo cardio lv 
		   t3_test spine_inj pf_image OH_vitamin vit_d pap cyst hpv

		   lv_bone_s homoc_s 
		   coag_s pth_s chest_x_s 
		   cardio_x_s arthro_s pft_s stress_s ct_sinus_s scan_sync_s scan_head_s eeg_head_s back_s 
		   carotid_scan_asymp_s carotid_scan_sync_s cardio_stress_s coronary_s renal_angio_s carotid_end_s
		   ivc_s vertebro_s neuro_s diagnostic_s preoperative_s musculo_s cardio_s lv_s 
		   t3_test_s spine_inj_s pf_image_s OH_vitamin_s /*vit_d_s pap_s*/ cyst_s hpv_s);

	if lv=. then lv=0;
	if 18<=age<65;
run;

proc freq data=low_value_costs;
	tables lv_bone homoc 
		   coag pth chest_x 
		   cardio_x arthro pft stress ct_sinus scan_sync scan_head eeg_head back 
		   carotid_scan_asymp carotid_scan_sync cardio_stress coronary renal_angio carotid_end
		   ivc vertebro neuro diagnostic preoperative musculo cardio lv 
		   t3_test spine_inj pf_image OH_vitamin vit_d pap cyst hpv

		   lv_bone_s homoc_s 
		   coag_s pth_s chest_x_s 
		   cardio_x_s arthro_s pft_s stress_s ct_sinus_s scan_sync_s scan_head_s eeg_head_s back_s 
		   carotid_scan_asymp_s carotid_scan_sync_s cardio_stress_s coronary_s renal_angio_s carotid_end_s
		   ivc_s vertebro_s neuro_s diagnostic_s preoperative_s musculo_s cardio_s lv_s 
		   t3_test_s spine_inj_s pf_image_s OH_vitamin_s /*vit_d_s pap_s*/ cyst_s hpv_s;
run;

proc sort data=low_value_costs; by enrolid svcdate descending lv;

data low_value_costs;
	set low_value_costs;
	retain any_lv;
	by enrolid svcdate;
	if first.svcdate then any_lv=(lv~=0);
	if any_lv=1; 
run;

proc print data=low_value_costs (obs=100); run;

proc format;
	value $proc 
	'36415' = 'homoc_s and pth_s'
	'83890'-'83914' = 'coag_s'
	'93303'-'93352' = 'cardio_x_s and cardio_stress_s'
	'94010'-'94799' = 'pft_s'
	'93720'-'93722' = 'pft_s'
	'93000'-'93042' = 'cardio_stress_s'
	'78414'-'78499' = 'cardio_stress_s'
	'75552'-'75564' = 'cardio_stress_s'
	'75571'-'75574' = 'cardio_stress_s'
	'A9500'-'A9700' = 'cardio_stress_s'
	'J0150' = 'cardio_stress_s'
	'J0152' = 'cardio_stress_s'
	'J0280' = 'cardio_stress_s'
	'J1245' = 'cardio_stress_s'
	'J1250' = 'cardio_stress_s'
	'J2785' = 'cardio_stress_s'
	'36010' = 'ivc_s'
	'37620' = 'ivc_s'
	'75825' = 'ivc_s'
	'76937' = 'ivc_s';
run;

/*Variables that need additional coding: homoc coag	pth	cardio_x pft cardio_stress stress coronary ivc*/

/*For these procedures, sum up all costs for specific procedures on the same day as the low value procedure, defined by the format statement above*/
%macro total_cost(var);
	proc sort data=low_value_costs; by enrolid svcdate descending &var.; 

	data costs_&var. (keep=year &var._day tot_cost tot_cost_op pay enrolid svcdate proc1 rename=(&var._day=&var.))
		 same_day_&var. (keep=proc1 pay);
		length proc1 $30;
		set low_value_costs;

		format proc1 $proc.;
		proc1_f=vvalue(proc1);

		retain tot_cost tot_cost_op &var._day;
		by enrolid svcdate;
		if first.svcdate then do;
			tot_cost=0;
			tot_cost_op=0;
			&var._day=0;
			if &var.=1 then do;
				&var._day=1;
			end;
		end;
		if &var._day=1 then do; /*Sum up the costs of the claim with the lv proc and the claims with supplmental procs on the same day*/
			if index(proc1_f,"&var.")>0 | 
			   &var.=1 then tot_cost=sum(tot_cost,pay);

			if (index(proc1_f,"&var.")>0 |  /*For our aggregate measures in the CDHP project we are only interested in outpatient procedures. BR 1-6-17*/
			   &var.=1) & non_inpatient=1 then tot_cost_op=sum(tot_cost_op,pay);
		end;
		/*Output all obs on the same day with an indicated procedure code*/
		if &var._day=1 & (index(proc1_f,"&var.")>0 | &var.=1) then output same_day_&var.;

		/*Collapse down to the day level with the collapsed costs*/
		if last.svcdate & &var._day=1 then output costs_&var.;
	run;

	/*Collapse down to the patient-year level*/
	proc sort data=costs_&var.; by enrolid year; run;

	data costs_&var. (keep=enrolid year cst_&var. cst_&var._op);
		set costs_&var.;
		retain cst_&var. cst_&var._op;
		by enrolid year;
		if first.year then do;
			cst_&var.=0;
			cst_&var._op=0;
		end;
		cst_&var.=sum(cst_&var.,tot_cost);
		cst_&var._op=sum(cst_&var._op,tot_cost_op); /*For our aggregate measures in the CDHP project we are only interested in outpatient procedures. BR 1-6-17*/
		if last.year then output;
	run;

	proc univariate data=costs_&var.;
		var cst_&var.;
		ods output quantiles=quant_&var.;
	run;

	/*Strip formats from the CPT dataset so we can see the CPT codes*/
    proc datasets lib=work memtype=data;
    	modify same_day_&var.; 
    	attrib _all_ label=' '; 
     	attrib _all_ format=;
	run;

	proc freq data=same_day_&var.;
		tables proc1 / out=cpt_freqs_&var.;
	run;

	/*Add on the total cost and average cost of each CPT code associated with the procedure*/
	proc sort data=same_day_&var.; by proc1; run;

	data proc_costs_&var. (keep=proc1 proc_cost avg_cost);
		set same_day_&var.;
		retain proc_cost total_count;
		by proc1;
		if first.proc1 then do;
			proc_cost=0;
			total_count=0;
		end;
		proc_cost=sum(proc_cost,pay);
		total_count=total_count+1;
		avg_cost=proc_cost/total_count;
		if last.proc1 then output;
	run;

	/*Merge the costs and the counts of each procedure*/
	data cpt_freqs_&var.;
		merge cpt_freqs_&var.
			  proc_costs_&var.;
		by proc1;
	run;

	data cpt_freqs_&var.;
		set cpt_freqs_&var.;
		if proc1~='';
		if COUNT<11 then do;
			COUNT=.;
			PERCENT=.;
			avg_cost=.;
		end;
	run;

	proc sort data=cpt_freqs_&var.; by descending proc_cost; run;
%mend;
%total_cost(homoc);
%total_cost(coag);
%total_cost(pth);
%total_cost(cardio_x);
%total_cost(pft);
%total_cost(cardio_stress);
%total_cost(stress);
%total_cost(ivc);
%total_cost(homoc_s);
%total_cost(coag_s);
%total_cost(pth_s);
%total_cost(cardio_x_s);
%total_cost(pft_s);
%total_cost(cardio_stress_s);
%total_cost(stress_s);
%total_cost(ivc_s);

/*For these procedures, sum up all costs for all procedures on the same day as the low value procedure*/
%macro total_cost_all(var);
	proc sort data=low_value_costs; by enrolid svcdate descending &var.; 

	data costs_&var. (keep=year &var._day tot_cost tot_cost_op pay enrolid svcdate proc1 rename=(&var._day=&var.))
		 same_day_&var. (keep=proc1 pay);
		length proc1_f $30;
		set low_value_costs;

		format proc1 $proc.;
		proc1_f=vvalue(proc1);

		retain tot_cost tot_cost_op &var._day;
		by enrolid svcdate;
		if first.svcdate then do;
			tot_cost=0;
			tot_cost_op=0;
			&var._day=0;
			if &var.=1 then do;
				&var._day=1;
			end;
		end;
		if &var._day=1 then do; /*Sum up the costs of the claim with the lv proc and the claims every other proc on the same day*/
			tot_cost=sum(tot_cost,pay);
			tot_cost_op=sum(tot_cost_op,pay); /*For our aggregate measures in the CDHP project we are only interested in outpatient procedures. BR 1-6-17*/
		end;
		if &var._day=1 then output same_day_&var.;
		if last.svcdate & &var._day=1 then output costs_&var.;
	run;

	/*Collapse down to the patient-year level*/
	proc sort data=costs_&var.; by enrolid year; run;

	data costs_&var. (keep=enrolid year cst_&var. cst_&var._op);
		set costs_&var.;
		retain cst_&var. cst_&var._op;
		by enrolid year;
		if first.year then do;
			cst_&var.=0;
			cst_&var._op=0;
		end;
		cst_&var.=sum(cst_&var.,tot_cost);
		cst_&var._op=sum(cst_&var._op,tot_cost_op); /*For our aggregate measures in the CDHP project we are only interested in outpatinet procedures. BR 1-6-17*/
		if last.year then output;
	run;

	proc univariate data=costs_&var.;
		var cst_&var.;
		ods output quantiles=quant_&var.;
	run;

	/*Strip formats from the CPT dataset so we can see the CPT codes*/
    proc datasets lib=work memtype=data;
    	modify same_day_&var.; 
    	attrib _all_ label=' '; 
     	attrib _all_ format=;
	run;

	proc freq data=same_day_&var.;
		tables proc1 / out=cpt_freqs_&var.;
	run;

	/*Add on the total cost and average cost of each CPT code associated with the procedure*/
	proc sort data=same_day_&var.; by proc1; run;

	data proc_costs_&var. (keep=proc1 proc_cost avg_cost);
		set same_day_&var.;
		retain proc_cost total_count;
		by proc1;
		if first.proc1 then do;
			proc_cost=0;
			total_count=0;
		end;
		proc_cost=sum(proc_cost,pay);
		total_count=total_count+1;
		avg_cost=proc_cost/total_count;
		if last.proc1 then output;
	run;

	/*Merge the costs and the counts of each procedure*/
	data cpt_freqs_&var;
		merge cpt_freqs_&var.
			  proc_costs_&var.;
		by proc1;
	run;

	data cpt_freqs_&var.;
		set cpt_freqs_&var.;
		if proc1~='';
		if COUNT<11 then do;
			COUNT=.;
			PERCENT=.;
			avg_cost=.;
		end;
	run;

	proc sort data=cpt_freqs_&var.; by descending proc_cost; run;
%mend;
%total_cost_all(arthro);
%total_cost_all(vertebro);
%total_cost_all(spine_inj);
%total_cost_all(renal_angio);
%total_cost_all(arthro_s);
%total_cost_all(vertebro_s);
%total_cost_all(spine_inj_s);
%total_cost_all(renal_angio_s);


/*For these procedures, sum up all costs for all procedures during the hospital stay associated with the low value procedure*/
%macro inpatient_cost(var); 

/*Create a var_day flag to group all claims that happen the same day as the low value procedure*/
proc sort data=low_value_costs; by enrolid svcdate descending &var.; 

	data costs_&var.;
		length proc1_f $30;
		set low_value_costs;

		retain &var._day;
		by enrolid svcdate;
		if first.svcdate then do;
			&var._day=0;
			if &var.=1 & conf_id="" then do; /*Only flag days that are not inpatient stays. Inpatient stays are summed below using a different method*/
				&var._day=1;
			end;
		end;

	/*Create a var_conf flag to flag all claims that happen in the same inpatient confinement as the low value procedure*/
	proc sort data=costs_&var.; by enrolid conf_id descending &var.; 

	data costs_&var. (keep=year &var._conf tot_cost pay enrolid conf_id rename=(&var._conf=&var.))
		 same_day_&var. (keep=proc1 pay);
		set costs_&var.;

		retain tot_cost &var._conf;
		by enrolid conf_id;
		if first.conf_id then do;
			tot_cost=0;
			&var._conf=0;
			if &var.=1 & conf_id~="" then &var._conf=1;
		end;
		/*Sum up the costs of all claims that happen on the same day of an op procedure OR during the same hospital stay as the low value procedure*/
		if &var._conf=1 | &var._day=1 then tot_cost=sum(tot_cost,pay);
		if &var._conf=1 then output same_day_&var.;
		if last.conf_id & (&var._conf=1 | tot_cost>0) then output costs_&var.;
	run;

	/*Collapse down to the patient-year level*/
	proc sort data=costs_&var.; by enrolid year; run;

	data costs_&var. (keep=enrolid year cst_&var.);
		set costs_&var.;
		retain cst_&var.;
		by enrolid year;
		if first.year then do;
			cst_&var.=0;
		end;
		cst_&var.=sum(cst_&var.,tot_cost);
		if last.year then output;
	run;

	proc univariate data=costs_&var.;
		var cst_&var.;
		ods output quantiles=quant_&var.;
	run;

	/*Strip formats from the CPT dataset so we can see the CPT codes*/
    proc datasets lib=work memtype=data;
    	modify same_day_&var.; 
    	attrib _all_ label=' '; 
     	attrib _all_ format=;
	run;

	proc freq data=same_day_&var.;
		tables proc1 / out=cpt_freqs_&var.;
	run;

	/*Add on the total cost and average cost of each CPT code associated with the procedure*/
	proc sort data=same_day_&var.; by proc1; run;

	data proc_costs_&var. (keep=proc1 proc_cost avg_cost);
		set same_day_&var.;
		retain proc_cost total_count;
		by proc1;
		if first.proc1 then do;
			proc_cost=0;
			total_count=0;
		end;
		proc_cost=sum(proc_cost,pay);
		total_count=total_count+1;
		avg_cost=proc_cost/total_count;
		if last.proc1 then output;
	run;

	/*Merge the costs and the counts of each procedure*/
	data cpt_freqs_&var;
		merge cpt_freqs_&var.
			  proc_costs_&var.;
		by proc1;
	run;

	data cpt_freqs_&var.;
		set cpt_freqs_&var.;
		if proc1~='';
		if COUNT<11 then do;
			COUNT=.;
			PERCENT=.;
			avg_cost=.;
		end;
	run;

	proc sort data=cpt_freqs_&var.; by descending proc_cost; run;
%mend;
%inpatient_cost(carotid_end);
%inpatient_cost(carotid_end_s);
%inpatient_cost(coronary);
%inpatient_cost(coronary_s);

data dat.costs_totalled;
	merge costs_:;
	by enrolid year;
run;

proc print data=dat.costs_totalled (obs=100); run;

proc univariate data=dat.costs_totalled; 
	var cst_homoc cst_coag cst_pth	cst_cardio_x cst_pft cst_cardio_stress cst_stress cst_coronary  cst_ivc
	    cst_homoc_s cst_coag_s cst_pth cst_cardio_x_s cst_pft_s cst_cardio_stress_s cst_stress_s cst_coronary_s 
		cst_ivc_s cst_arthro cst_vertebro cst_spine_inj cst_renal_angio cst_arthro_s cst_vertebro_s 
		cst_renal_angio_s cst_carotid_end cst_carotid_end_s

		cst_homoc_op cst_coag_op cst_pth_op	cst_cardio_x_op cst_pft_op 
		cst_cardio_stress_op cst_stress_op cst_ivc_op cst_homoc_s_op cst_coag_s_op 
		cst_pth_op cst_cardio_x_s_op cst_pft_s_op cst_cardio_stress_s_op 
		cst_stress_s_op cst_ivc_s_op cst_arthro_op cst_vertebro_op cst_spine_inj_op 
		cst_renal_angio_op cst_arthro_s_op cst_vertebro_s_op cst_renal_angio_s_op;
run;

/************************************************************************************
PRINT CHECK
************************************************************************************/

/*Output a sample of each of the datasets to an excel workbook*/
ods tagsets.excelxp file="/disk/agedisk3/mktscan.work/sood/rabideau/Output/calc_costs.xml" style=sansPrinter;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="arthro" frozen_headers='yes');
proc print data=quant_arthro ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="arthro_s" frozen_headers='yes');
proc print data=quant_arthro_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="vertebro" frozen_headers='yes');
proc print data=quant_vertebro ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="vertebro_s" frozen_headers='yes');
proc print data=quant_vertebro_s;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="spine_inj" frozen_headers='yes');
proc print data=quant_spine_inj ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="renal_angio" frozen_headers='yes');
proc print data=quant_renal_angio ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="renal_angio_s" frozen_headers='yes');
proc print data=quant_renal_angio_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="homoc" frozen_headers='yes');
proc print data=quant_homoc ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="homoc_s" frozen_headers='yes');
proc print data=quant_homoc_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coag" frozen_headers='yes');
proc print data=quant_coag ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coag_s" frozen_headers='yes');
proc print data=quant_coag_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="pth" frozen_headers='yes');
proc print data=quant_pth ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="pth_s" frozen_headers='yes');
proc print data=quant_pth_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="cardio_stress" frozen_headers='yes');
proc print data=quant_cardio_stress ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="cardio_stress_s" frozen_headers='yes');
proc print data=quant_cardio_stress_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="stress" frozen_headers='yes');
proc print data=quant_stress ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="stress_s" frozen_headers='yes');
proc print data=quant_stress_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coronary" frozen_headers='yes');
proc print data=quant_coronary ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coronary_s" frozen_headers='yes');
proc print data=quant_coronary_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="ivc" frozen_headers='yes');
proc print data=quant_ivc ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="ivc_s" frozen_headers='yes');
proc print data=quant_ivc_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="carotid_end" frozen_headers='yes');
proc print data=quant_carotid_end ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="carotid_end_s" frozen_headers='yes');
proc print data=quant_carotid_end_s ;
run;
ods tagsets.excelxp close;






ods tagsets.excelxp file="/disk/agedisk3/mktscan.work/sood/rabideau/Output/same_day_cpt.xml" style=sansPrinter;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="arthro" frozen_headers='yes');
proc print data=cpt_freqs_arthro ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="arthro_s" frozen_headers='yes');
proc print data=cpt_freqs_arthro_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="vertebro" frozen_headers='yes');
proc print data=cpt_freqs_vertebro ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="vertebro_s" frozen_headers='yes');
proc print data=cpt_freqs_vertebro_s;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="spine_inj" frozen_headers='yes');
proc print data=cpt_freqs_spine_inj ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="renal_angio" frozen_headers='yes');
proc print data=cpt_freqs_renal_angio ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="renal_angio_s" frozen_headers='yes');
proc print data=cpt_freqs_renal_angio_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="homoc" frozen_headers='yes');
proc print data=cpt_freqs_homoc ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="homoc_s" frozen_headers='yes');
proc print data=cpt_freqs_homoc_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coag" frozen_headers='yes');
proc print data=cpt_freqs_coag ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coag_s" frozen_headers='yes');
proc print data=cpt_freqs_coag_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="pth" frozen_headers='yes');
proc print data=cpt_freqs_pth ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="pth_s" frozen_headers='yes');
proc print data=cpt_freqs_pth_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="cardio_stress" frozen_headers='yes');
proc print data=cpt_freqs_cardio_stress ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="cardio_stress_s" frozen_headers='yes');
proc print data=cpt_freqs_cardio_stress_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="stress" frozen_headers='yes');
proc print data=cpt_freqs_stress ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="stress_s" frozen_headers='yes');
proc print data=cpt_freqs_stress_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coronary" frozen_headers='yes');
proc print data=cpt_freqs_coronary ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="coronary_s" frozen_headers='yes');
proc print data=cpt_freqs_coronary_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="ivc" frozen_headers='yes');
proc print data=cpt_freqs_ivc ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="ivc_s" frozen_headers='yes');
proc print data=cpt_freqs_ivc_s ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="carotid_end" frozen_headers='yes');
proc print data=cpt_freqs_carotid_end ;
run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="carotid_end_s" frozen_headers='yes');
proc print data=cpt_freqs_carotid_end_s ;
run;
ods tagsets.excelxp close;

/*********************
CHECK END
*********************/





