%include "/disk/agedisk3/mktscan.work/sood/rabideau/Programs/CDHP/charlson_ruleout.sas";
%include "/disk/agedisk3/mktscan.work/sood/rabideau/Programs/CDHP/charlson_calc.sas";
libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname in "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
libname out "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Final";
%let out = /disk/agedisk3/mktscan.work/sood/rabideau/Output;

/**************************************************************
 DATA PREP
**************************************************************/

/*Test to see if people are in all years of data*/
proc sort data=in.low_val_beneyear out=test; by enrolid year; run;
data test;
	set test;
	by enrolid;
	retain count;
	if first.enrolid then count=0;
	count+1;
run;

proc freq data=test;
	tables year count;
run;

data mscan_demog (keep=contributor enrolid year gdr_cd age age_cat
					   cst_neuro_s cst_diagnostic_s cst_preoperative_s cst_musculo_s cst_cardio_s cst_lv_s cst_imaging_op
					   cst_non_inpatient_op cst_laboratory_op cst_lv_imaging cst_lv_non_inpatient cst_lv_laboratory
					   cst_less_sensitive cst_more_sensitive
					   rename=(cst_imaging_op=cst_imaging cst_non_inpatient_op=cst_non_inpatient cst_laboratory_op=cst_laboratory));

	/*Benes must be 18<=age<=64 for all years of data, 2006-2013. e.g. in 2006 an bene must be between 18 and 57 in order to not be over 64 by 2013*/
	set in.low_val_beneyear (where=((year-1988)<=age<=(year-1951))); 
	/*example: 2006-1988=18, 2006-1951=57 ---> 18<=age<=57 for claims with a service date in 2006*/

	if 18<=age<=34 then age_cat='18-34';
	if 35<=age<=49 then age_cat='35-49';
	if 50<=age<=64 then age_cat='50-64';
run;

proc means data=mscan_demog;
	var cst_non_inpatient cst_lv_non_inpatient cst_imaging cst_lv_imaging 
		cst_laboratory cst_lv_laboratory cst_less_sensitive cst_more_sensitive;
run;


/**************************************************************
 ADD ON ENROLLMENT INFORMATION
**************************************************************/
data enrollment;
	set raw.ccaea2013 (in=a where=(contributor in (024,027,146,825)))
		raw.ccaea2012 (in=b where=(contributor in (024,027,146,825)))
		raw.ccaea2011 (in=c where=(contributor in (024,027,146,825)))
		raw.ccaea2010 (in=d where=(contributor in (024,027,146,825)))
		raw.ccaea2009 (in=e where=(contributor in (024,027,146,825)))
		raw.ccaea2008 (in=f where=(contributor in (024,027,146,825)))
		raw.ccaea2007 (in=g where=(contributor in (024,027,146,825)))
		raw.ccaea2006 (in=h where=(contributor in (024,027,146,825)));

	cont_cov=1;
	cdhp_count=0;
	%macro loop;
		%do i=1 %to 12;
			if plntyp&i=. then cont_cov=0;
			if plntyp&i in(8,9) then cdhp_count+1;
		%end;
	%mend;
	%loop;
	if cont_cov=1 then cdhp=0;
	if cont_cov=1 & cdhp_count>6 then cdhp=1;
	if a then year=2013;
	if b then year=2012;
	if c then year=2011;
	if d then year=2010;
	if e then year=2009;
	if f then year=2008;
	if g then year=2007;
	if h then year=2006;

	if contributor in (024,027) then full_replace=1;
	else if contributor in (146,825) then full_replace=0;
run;

proc print data=enrollment (obs=20); run;

proc freq data=enrollment; 
	tables cont_cov*cdhp / missing;
run;

/*Create a flat file for each enrollee with flags for years with 12 months of coverage*/
proc sort data=enrollment; by contributor enrolid year; run;

proc print data=enrollment (obs=50); 
	var contributor enrolid year cont_cov;
run;

proc transpose data=enrollment out=t_enrollment prefix=Y;
	by contributor enrolid;
	id year;
	var cont_cov;
run;

proc print data=t_enrollment (obs=10); run;

data sample;
	set t_enrollment (drop=_NAME_);
	%macro loop;
		%do i=2006 %to 2013;
			if Y&i.=. then Y&i.=0;
		%end;
	%mend;
	%loop;
	if contributor=024 then do;
		treatment=1;
		pre=0;
		if Y2006 & Y2007 & Y2008 then pre=1; /*Continuously enrolled before the CDHP switch*/
		if Y2006 & Y2007 & Y2008 & Y2009 & Y2010 & Y2011 & Y2012 & Y2013  then attrit=0; /*Stayed in sample the whole time*/
		if Y2006 & Y2007 & Y2008 & Y2009=0 then attrit=1; /*Attrition at the time of CDHP implementation*/
	end; 
	else if contributor=027 then do;
		treatment=1;
		pre=0;
		if Y2006 & Y2007 & Y2008 & Y2009 then pre=1; /*Continuously enrolled before the CDHP switch*/
		if Y2006 & Y2007 & Y2008 & Y2009 & Y2010 & Y2011 & Y2012 & Y2013  then attrit=0; /*Stayed in sample the whole time*/
		if Y2006 & Y2007 & Y2008 & Y2009 & Y2010=0 then attrit=1; /*Attrition at the time of 1st CDHP implementation*/
		if Y2006 & Y2007 & Y2008 & Y2009 & Y2010 & Y2011 & Y2012=0 then attrit=2; /*Attrition at the time of 2nd CDHP implementation*/
	end; 
	else if contributor=146 | contributor=825 then do;
		treatment=0;
		pre=0;
		if Y2006 & Y2007 & Y2008 then pre=1; /*Continuously enrolled for at least the first few years*/
		if Y2006 & Y2007 & Y2008 & Y2009 & Y2010 & Y2011 & Y2012 & Y2013  then attrit=0; /*Stayed in sample the whole time*/
	end; 

	if pre=1; /*Keep only enrollees who were continuously enrolled at least the first few years*/
run;

proc freq data=sample;
	tables contributor*attrit / missing;
run;

/*Create a bene-year level enrollment file so that when we merge onto the medical claims file
  we can identify benes with coverage, but no claims in each year*/
data sample_year;
	set sample;
	%macro loop_year;
		%do i=2006 %to 2013;
			year=&i.;
			output;
		%end;
	%mend;
	%loop_year;
run;

title "Check Years in Enrollment-Year File. Should be the same for all years";
proc freq data=sample_year;
	tables year / missing;
run;
title;

/*Perform a m:1 merge on enrolid Keep people in the enrollment sample even if they don't have medical claims*/
proc sort data=sample_year; by contributor enrolid year; run;
proc sort data=mscan_demog; by contributor enrolid year; run;

data mscan_demog;
	merge mscan_demog (in=a)
		  sample_year (in=b);
	by contributor enrolid year;
	if b; 
	if b & ~a then cov_only=1;

	/*Cov_only will be missing these fields, indicating $0 spent that year. Set them to 0*/
	if cst_non_inpatient=. then cst_non_inpatient=0;
	if cst_laboratory=. then cst_laboratory=0;
	if cst_imaging_op=. then cst_imaging_op=0;
	if cst_lv_non_inpatient=. then cst_lv_non_inpatient=0;
	if cst_lv_laboratory=. then cst_lv_laboratory=0;
	if cst_lv_imaging=. then cst_lv_imaging=0;
	if cst_less_sensitive=. then cst_less_sensitive=0;
	if cst_more_sensitive=. then cst_more_sensitive=0;
run;

title "Check Coverage-Only";
proc freq data=mscan_demog;
	tables cov_only*year / missing;
run;
title;


/**************************************************************
 COMPARE SPENDING BY YEAR
**************************************************************/
%macro costs_by_attrition(emp,var);
	title "Compare yearly spending and low value spending between those stay vs leave after CDHP switch. Contributor &emp.";
	proc means data=mscan_demog;
		class attrit year; /*Attrit=1 were enrolled up until the CDHP switch, then dropped after*/
		var &var.;
		where attrit~=. & contributor=&emp.;
		output out=attrit&emp.;
	run;

	proc contents data=attrit&emp.; run;
	proc print data=attrit&emp.; run;

	/*Make the output readable*/
	data attrit&emp.;
		set attrit&emp.;
		if _TYPE_=3 & trim(left(_STAT_))="MEAN";
	run;

	proc transpose data=attrit&emp. out=t_attrit&emp. prefix=Y;
		by attrit;
		id year;
		var &var.;
	run;

	data t_&var.&emp.;
		length contributor 8 variable $32;
		set t_attrit&emp. (drop=_NAME_);
		contributor=&emp.;
		variable="&var.";
	run;

	proc print data=t_&var.&emp.; run;
%mend;
%costs_by_attrition(emp=024,var=cst_non_inpatient);
%costs_by_attrition(emp=024,var=cst_lv_non_inpatient);
%costs_by_attrition(emp=027,var=cst_non_inpatient);
%costs_by_attrition(emp=027,var=cst_lv_non_inpatient);

%macro cost_by_contrib(var);
	title "Compare yearly spending and low value spending for continuously enrolled between contributors";
	proc means data=mscan_demog;
		class contributor year;
		var &var.;
		where attrit=0;
		output out=tot_spend;
	run;
	title;

	proc contents data=tot_spend; run;
	proc print data=tot_spend; run;

	/*Make the output readable*/
	data tot_spend;
		set tot_spend;
		if _TYPE_=3 & trim(left(_STAT_))="MEAN";
	run;

	proc transpose data=tot_spend out=t_tot_spend prefix=Y;
		by contributor;
		id year;
		var &var.;
	run;

	data t_tot_&var.;
		length variable $32;
		set t_tot_spend (drop=_NAME_);
		variable="&var.";
	run;

	proc print data=t_tot_&var.; run;
%mend;
%cost_by_contrib(var=cst_non_inpatient);
%cost_by_contrib(var=cst_lv_non_inpatient);

data yearly_spending;
	set t_cst_non_inpatient024
		t_cst_lv_non_inpatient024
		t_cst_non_inpatient027
		t_cst_lv_non_inpatient027
		t_tot_cst_non_inpatient
		t_tot_cst_lv_non_inpatient;
run;

title "Check Yearly Spending";
proc print data=yearly_spending; run;
title;

/**************************************************************
 ADD ON CHARLSON COMORBIDITY SCORES
**************************************************************/
%macro cci;
	%do yr=2006 %to 2006;
		data claims_&yr.;
			set in.low_val_prep (where=(year=&yr.)); /*Only count comorbidities that happen in 2006*/

			/*Add Charlson Variables*/
			if stdplac="21" then claim_type='M'; /*If inpatient, set claim_type to 'M', for MedPAR. This value is used by the Charlson Macro*/
			status='I';
			length=(tsvcdat - svcdate)+1;
			hcpcs='';
		run;

		proc sort data=claims_&yr.; by enrolid svcdate; run;

		/*We must use the ruleout macro because most of our claims are physician and outpatient - they use misleading ruleout diagnoses*/
		*%RULEOUT (SETIN=claims_&yr.,
						enrolid=enrolid,
						CLMDTE=svcdate,
						START="01jan&yr."d,
						FINISH="31dec&yr."d,
						DXVARSTR=diag1-diag5,
						NDXVAR=5,
						HCPCS=hcpcs,
						FILETYPE=claim_type);

		/*The output of ruleout is clmrecs, so input that into the actual comorbidity macro below. If not using rulouts,
		  input the claims_&yr. dataset. The output dataset is 'comorb'*/
		%COMORB  (SETIN=/*CLMRECS*/claims_&yr.,
						PATID=enrolid,
						IDXPRI=status,
						DAYS=length,
						DXVARSTR=diag1-diag2,
						NDXVAR=2,
						SXVARSTR=proc1,
						NSXVAR=1,
						HCPCS=hcpcs,
						FILETYPE=claim_type);

		data cci_&yr.;
			set comorb;
		run;
	%end;
%mend;
%cci;

data cci;
	set cci_2006 (in=a);
	charlson_count=sum(of CVPRIO01-CVPRIO18,of CVINDX01-CVINDX18);
run;

proc freq data=cci;
	tables charlson_count;
run;

proc print data=cci (obs=10); 
	var CVPRIO01-CVPRIO18 CVINDX01-CVINDX18 charlson_count;
run;

proc sort data=cci; by enrolid;
proc sort data=mscan_demog; by enrolid; 

data mscan_demog;
	merge mscan_demog (in=a)
		  cci (keep=enrolid charlson_count in=b);
	by enrolid;
	if a;

	if charlson_count>3 then charlson_count=3; /*Cap the Charlson count*/
	if charlson_count=. then charlson_count=0;
run;

proc sort data=mscan_demog; by enrolid year; run;

proc contents data=mscan_demog; run;

proc freq data=mscan_demog;
	tables year charlson_count*year;
run;

proc print data=mscan_demog (obs=50);
	var enrolid year charlson_count;
run;

/***********************************************************************************************************************/
/*Output the SAF dataset to use for future analysis*/
/***********************************************************************************************************************/
data out.beneyear_cdhp_did_saf;
	set mscan_demog;
run;

proc freq data=out.beneyear_cdhp_did_saf;
	tables gdr_cd age_cat charlson_count / missing;
run;

proc export data=out.beneyear_cdhp_did_saf
			outfile = "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Final/beneyear_cdhp_did_saf.dta" replace;
run;


/**************************************************************
 GENERATE DEMOGRAPHIC AND DESCRIPTIVE STATISTICS
**************************************************************/

%macro freqs(byvar,var);
	ods output ChiSq = chi
			   CrossTabFreqs = xtab;
	proc freq data=mscan_demog_match;
		tables &byvar.*&var. / chisq;
		*weight c_weight;
	run;
	ods output close;

	proc print data=xtab; run;
	proc print data=chi; run;

	data _NULL_;
		set chi;
		if trim(left(statistic))="Chi-Square" then call symput("chisq",prob);
	run;

	data &byvar. (keep=&byvar. &var. rowpercent rename=(&var.=value1 rowpercent=pct_treat))
		 non_&byvar. (keep=&byvar. &var. rowpercent rename=(&var.=value1 rowpercent=pct_control));
		set xtab (where=(rowpercent~=.));
		if &byvar.=1 then output &byvar.;
		else if &byvar.=0 then output non_&byvar.;
	run;

	proc sort data=&byvar.; by value1; run;
	proc sort data=non_&byvar.; by value1; run;

	data z_&var. (keep=value pct_treat pct_control);
		length value $100;
		merge &byvar.
			  non_&byvar.;
		by value1;
		format value1 $&var..;
		value=vvalue(value1);
	run;

	data z_&var.;
		length variable $32;
		set z_&var.;
		if _n_=1 then do; 
			variable="&var.";
			Significance=&chisq.;
		end;
	run;

	proc print data=z_&var.; run;
%mend;
*%freqs(byvar=treatment, var=gdr_cd);
*%freqs(byvar=treatment, var=age_cat);
*%freqs(byvar=treatment, var=charlson_count);

%macro out2;
data freqs_all;
	set z_:;
run;

proc print data= freqs_all; run;
%mend;
/**************************************************************
 CALCULATE COSTS BY VARIABLE
**************************************************************/

/*This macro determines which dataset to read in for analysis - original, propensity matched, or propensity weighted*/
%macro costs(ds,name,cost_var);
	data mscan_demog&ds.;
		set mscan_demog&ds.;
		if 18<=age<=34 then age_cat='18-34';
		if 35<=age<=49 then age_cat='35-49';
		if 50<=age<=64 then age_cat='50-64';
		if cst_&cost_var.~=. & cst_&cost_var.~=0 then ratio_&cost_var. = (cst_lv_&cost_var./cst_&cost_var.)*10000;
	run;

	/*This macro makes the ttest output a single line dataset with means and ttest*/
	%macro ttest(byvar);

		proc sort data=mscan_demog&ds.; by &byvar.; run;

		ods listing close; /*For now do not print output to listing - .lst file is too cluttered*/
		ods output  Statistics = stats
		 			TTests = ttests
					Equality = variances;
		proc ttest data=mscan_demog&ds.;
			class treatment;
			by &byvar.;
			var cst_lv_&cost_var. cst_&cost_var. ratio_&cost_var. cst_less_sensitive cst_more_sensitive;
			weight c_weight;
		run;
		ods output close;
		ods listing;

		 proc print data=variances; run;

		/*proc print data=stats; run;	You can include these if somethings going wrong - for now suppress output
		proc print data=ttests; run;*/

		data stats (keep = &byvar. variable class treatment non_treatment);
			set stats(rename=(mean=avg));
			if trim(left(class)) = '0' then non_treatment = avg;
			if trim(left(class)) = '1' then treatment = avg; 
		run;

		 data non_treatment(drop = class treatment)
		 	  treatment (drop = class non_treatment);
		 	set stats;
		 	if trim(left(class)) = '0' then output non_treatment;
		 	if trim(left(class)) = '1' then output treatment;
		 run;

		 proc sort data = non_treatment; by &byvar. variable; run;
		 proc sort data = treatment; by &byvar. variable; run;

		 data stats_final;
		 	merge non_treatment
			      treatment;
		 	by &byvar. variable;
		 run;

		 /*proc print data=stats_final; run;*/
		
		 proc print data=ttests; run;

		 /*If the variances are unequal, use the satterthwaite p-val, otherwise use the pooled p-val*/
		 proc sort data=ttests; by &byvar. variable; run;
		 proc sort data=variances; by &byvar. variable; run;

		 data ttest (keep=&byvar. variable probt rename=(probt=Significance));
		 	merge ttests
				  variances (keep=&byvar. Variable ProbF);
			by &byvar. Variable;
			if /*trim(left(ProbF))="<.0001" |*/ (ProbF*1)<.05 then do;
				if trim(left(Method))="Satterthwaite";
			end;
			else do;
				if trim(left(Method))="Pooled";
			end;
		run;

		/*proc print data=ttest; run;*/
		proc sort data=ttest; by &byvar. variable; run;

		data t_&byvar.;
			length variable $ 50;
			merge stats_final
				  ttest;
			by &byvar. variable;
		run;

		/*proc print data=t_&byvar.; run;*/

		data a_&byvar. (rename=(treatment=&cost_var._treat non_treatment=&cost_var._non_treat Significance=&cost_var._Sig))
		     b_&byvar. (rename=(treatment=all_costs_treat non_treatment=all_costs_non_treat Significance=all_costs_Sig))
		     c_&byvar. (rename=(treatment=lv_cost_ratio_treat non_treatment=lv_cost_ratio_non_treat Significance=lv_cost_ratio_Sig))
			 d_&byvar. (rename=(treatment=less_sensitive_treat non_treatment=less_sensitive_non_treat Significance=less_sensitive_Sig))
			 e_&byvar. (rename=(treatment=more_sensitive_treat non_treatment=more_sensitive_non_treat Significance=more_sensitive_Sig));
			set t_&byvar.;
			if trim(left(variable))="cst_lv_&cost_var." then output a_&byvar.;
			else if trim(left(variable))="cst_&cost_var." then output b_&byvar.;
			else if trim(left(variable))="ratio_&cost_var." then output c_&byvar.;
			else if trim(left(variable))="cst_less_sensitive" then output d_&byvar.;
			else if trim(left(variable))="cst_more_sensitive" then output e_&byvar.;
		run;
		
		proc sort data=a_&byvar.; by &byvar.; run;
		proc sort data=b_&byvar.; by &byvar.; run;
		proc sort data=c_&byvar.; by &byvar.; run;

		data f_&byvar. (drop=Variable &byvar. rename=(Var=Variable));
			length Var $32;
			merge a_&byvar.
			      b_&byvar.
			      c_&byvar.
				  d_&byvar.
				  e_&byvar.;
			by &byvar.;
			format &byvar. $&byvar..;
			Value=VVALUE(&byvar.);
			Var="&byvar.";
		run;
		
		proc print data=f_&byvar.; run;
	%mend;
	%ttest(byvar=gdr_cd);
	%ttest(byvar=age_cat);
	%ttest(byvar=charlson_count);

	data ttests_&cost_var._&name.;
		length Value $50;
		set f_:;
	run;

	/*Unstratified costs*/
	proc ttest data=mscan_demog&ds.;
		class treatment;
		var cst_lv_&cost_var. cst_&cost_var. ratio_&cost_var. cst_less_sensitive cst_more_sensitive;
	run;
%mend;
*%costs(ds=2012_match,name=2012,cost_var=non_inpatient);
*%costs(ds=2013_match,name=2013,cost_var=non_inpatient);

*%costs(ds=2012_match,name=2012,cost_var=imaging);
*%costs(ds=2013_match,name=2013,cost_var=imaging);

*%costs(ds=2012_match,name=2012,cost_var=laboratory);
*%costs(ds=2013_match,name=2013,cost_var=laboratory);


%macro out;
/*Output the relevant datasets*/
ods tagsets.excelxp file="&out./cdhp_did_demog_noro.xml" style=sansPrinter;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Demographics by CHDP" frozen_headers='yes');
proc print data=freqs_all; run;

ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Non-Inpatient Costs - 2012" frozen_headers='yes');
proc print data=ttests_non_inpatient_2012; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Non-Inpatient Costs - 2013" frozen_headers='yes');
proc print data=ttests_non_inpatient_2013; run;

ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Imaging Costs - 2012" frozen_headers='yes');
proc print data=ttests_imaging_2012; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Imaging Costs - 2013" frozen_headers='yes');
proc print data=ttests_imaging_2013; run;

ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Laboratory Costs - 2012" frozen_headers='yes');
proc print data=ttests_laboratory_2012; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Laboratory Costs - 2013" frozen_headers='yes');
proc print data=ttests_laboratory_2013; run;

ods tagsets.excelxp close;
%mend;

proc datasets library=work kill;
run;
quit;






