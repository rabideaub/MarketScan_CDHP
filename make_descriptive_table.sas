libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname proc "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
libname final "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Final";
%let out = /disk/agedisk3/mktscan.work/sood/rabideau/Output;
%include "/disk/agedisk3/mktscan.work/sood/rabideau/Programs/CDHP/gen_chisq.sas";

proc format;
	value $agegrp
	"1" = "1 = 0-17"
	"2" = "2 = 18-34"
	"3" = "3 = 35-44"
	"4" = "4 = 45-54"
	"5" = "5 = 55-64";

	value $sex
	1 = "1 = Male"
	2 = "2 = Female";

	value cdhp
	0 = "0 = Non-CDHP"
	1 = "1 = CDHP";
run;

data enrollment;
	length plan $12;
	set raw.ccaea2013 (in=a where=(contributor in(027,146)))
		raw.ccaea2012 (in=b where=(contributor in(027,146)))
		raw.ccaea2011 (in=c where=(contributor in(027,146)))
		raw.ccaea2010 (in=d where=(contributor in(027,146)))
		raw.ccaea2009 (in=e where=(contributor in(027,146)))
		raw.ccaea2008 (in=f where=(contributor in(027,146)))
		raw.ccaea2007 (in=g where=(contributor in(027,146)))
		raw.ccaea2006 (in=h where=(contributor in(027,146)));

	cont_cov=1;
	cdhp_count=0;
	if plntyp1=1 then plan="1 = B/MM";
	else if plntyp1=2 then plan="2 = COMP";
	else if plntyp1=3 then plan="3 = EPO";
	else if plntyp1=4 then plan="4 = HMO";
	else if plntyp1=5 then plan="5 = NoCap POS";
	else if plntyp1=6 then plan="6 = PPO";
	else if plntyp1=7 then plan="7 = Cap POS";
	else if plntyp1=8 | plntyp1=9 then plan="8 = CDHP";
	else plan="Other";
	%macro loop;
		%do i=1 %to 12;
			if plntyp&i=. then cont_cov=0;
			if plntyp&i in(8,9) then cdhp_count+1;
			if plntyp&i.~=plntyp1 then plan="Other"; /*If multiple plantypes in the same year, set to other*/
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

	if contributor in (024,027,146,825);
	if contributor in (024,027) then full_replace=1;
	else if contributor in (146,825) then full_replace=0;

	if year<2010 then period=1;
	else if 2010<=year<2012 then period=2;
	else if year>=2012 then period=3;

	if cont_cov=1; /*Keep only those enrolled all 12 months of the year*/
run;

proc print data=enrollment (obs=20); run;

proc freq data=enrollment; 
	tables contributor*cdhp / missing;
run;

title "Demographics by Year for Contributor 027";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (plan agegrp sex)*period / missing;
	where contributor in(027) & cont_cov=1;
run;
title "Demographics by Year for Contributor 146";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (plan agegrp sex)*period / missing;
	where contributor in(146) & cont_cov=1;
run;
title;


/*Take frequencies of select variables by year, transpose and append*/
%macro take_freqs(ds,var,emp);
	ods output
	CrossTabFreqs = xtab;
	proc freq data=&ds.;
		tables (&var.)*period / missing out=y_&var.;
		where contributor=&emp.;
	run;
	ods output close;

	proc print data=xtab; run;

	data y_&var.;
		set xtab (keep=&var. period colpercent where=(colpercent~=.));
		if colpercent <.01 then colpercent=.;
	run;

	proc print data=y_&var.; run;

	proc transpose data=y_&var. out=y_&var. prefix=_&emp._P;
		by &var.;
		id period;
		var colpercent;
	run;

	data &ds._&emp._&var. (drop=&var. _NAME_ _LABEL_);
		length variable value $32;
		set y_&var.;
		variable="&var.";
		%if "&var."="agegrp" | "&var."="sex" %then %do;
			format &var. $&var..;
		%end;
		value=vvalue(&var.);
	run;

	proc sort data=&ds._&emp._&var.; by variable value; run;

%mend;
%take_freqs(ds=enrollment, var=agegrp, emp=027); %take_freqs(ds=enrollment, var=plan, emp=027); %take_freqs(ds=enrollment, var=sex, emp=027);

data q_027_all;
	set enrollment_027:;
run;

%take_freqs(ds=enrollment, var=agegrp, emp=146); %take_freqs(ds=enrollment, var=plan, emp=146); %take_freqs(ds=enrollment, var=sex, emp=146);

data q_146_all;
	set enrollment_146:;
run;

data freqs_all;
	merge q_027_all
		  q_146_all;
	by variable value;
	format sex $sex. agegrp $agegrp.;
run;

/*Do the same thing, but for the continuously enrolled cohort. This cohort was identified earlier in full_replace_summary.sas*/
proc sort data=enrollment; by enrolid; run;
proc sort data=proc.full_replace_ce out=cont_enrolled; by enrolid; run;

data enrollment_ce;
	merge enrollment (in=x)
		  cont_enrolled (in=y);
	by enrolid;
	if x & y;
run;

%take_freqs(ds=enrollment_ce, var=agegrp, emp=027); %take_freqs(ds=enrollment_ce, var=plan, emp=027); %take_freqs(ds=enrollment_ce, var=sex, emp=027);

data q_027_ce;
	set enrollment_ce_027:;
run;

%take_freqs(ds=enrollment_ce, var=agegrp, emp=146); %take_freqs(ds=enrollment_ce, var=plan, emp=146); %take_freqs(ds=enrollment_ce, var=sex, emp=146);

data q_146_ce;
	set enrollment_ce_146:;
run;

data freqs_ce;
	merge q_027_ce
		  q_146_ce;
	by variable value;
	format sex $sex. agegrp $agegrp.;
run;

title "Frequencies for All Benes by Period";
proc print data=freqs_all; run;
title; 

title "Frequencies for the Continuously Enrolled by Period";
proc print data=freqs_ce; run;
title;

proc sort data=enrollment nodupkey out=unique_enrollment; by enrolid period; run;
proc sort data=enrollment_ce nodupkey out=unique_enrollment_ce; by enrolid period; run;

title "N Per Period - All Benes";
proc freq data=unique_enrollment;
	tables contributor*period / missing;
run;

title "N Per Period - Continuously Enrolled Benes";
proc freq data=unique_enrollment_ce;
	tables contributor*period / missing;
run;
title;

/*Look at payment variables from our final SAF dataset. The final output is generated by demog_table_did.sas, but 
  the entire low-value procs algorithm is applied to get to that point*/
data beneyear_cdhp_did_saf;
	set final.beneyear_cdhp_did_saf (where=(contributor in(027,146)));

	/*Keep if continuously enrolled in that given year to match freqs sample above*/
	%macro loop;
		%do i=2006 %to 2013;
			if year=&i. then do;
				if Y&i.=1;
			end;
		%end;
	%mend;
	%loop;

	if year<2010 then period=1;
	else if 2010<=year<2012 then period=2;
	else if year>=2012 then period=3;

	if year=2006 then cst_lv_non_inpatient=.; /*2006 has no lookback year, so low value costs are artificially low. Set to missing*/
run;

title "Spending for Contributor 027 - All Benes";
proc means data=beneyear_cdhp_did_saf;
	class period;
	var cst_non_inpatient cst_lv_non_inpatient;
	where contributor=027;
	output out=all_027;
run;

title "Spending for Contributor 146 - All Benes";
proc means data=beneyear_cdhp_did_saf;
	class period;
	var cst_non_inpatient cst_lv_non_inpatient;
	where contributor=146;
	output out=all_146;
run;

title "Spending for Contributor 027 - Continuously Enrolled Benes";
proc means data=beneyear_cdhp_did_saf;
	class period;
	var cst_non_inpatient cst_lv_non_inpatient;
	where contributor=027 & attrit=0;
	output out=ce_027;
run;

title "Spending for Contributor 146 - Continuously Enrolled Benes";
proc means data=beneyear_cdhp_did_saf;
	class period;
	var cst_non_inpatient cst_lv_non_inpatient;
	where contributor=146 & attrit=0;
	output out=ce_146;
run;
title;

title "Look at the output from the means procedure";
proc print data=all_027; run;
title;

%macro take_means(ds,var,emp);
	data &ds.;
		set &ds.;
		if trim(left(_STAT_))="MEAN" & _TYPE_=1;
	run;

	proc transpose data=&ds. out=t_&emp. prefix=_&emp._P;
		id period;
		var &var.;
	run;

	data &ds._&var. (rename=(_NAME_=Variable));
		length _NAME_ $32;
		set t_&emp.;
	run;

	proc print data=&ds._var.; run;
%mend;
%take_means(ds=all_027,var=cst_non_inpatient, emp=027); %take_means(ds=all_027,var=cst_lv_non_inpatient, emp=027);
%take_means(ds=all_146,var=cst_non_inpatient, emp=146); %take_means(ds=all_146,var=cst_lv_non_inpatient, emp=146);

data all_027;
	set all_027_cst_non_inpatient
		all_027_cst_lv_non_inpatient;
run;

data all_146;
	set all_146_cst_non_inpatient
		all_146_cst_lv_non_inpatient;
run;

proc sort data=all_027; by variable; run;
proc sort data=all_146; by variable; run;

data means_all;
	merge all_027
		  all_146;
	by variable;
run;

%take_means(ds=ce_027,var=cst_non_inpatient, emp=027); %take_means(ds=ce_027,var=cst_lv_non_inpatient, emp=027);
%take_means(ds=ce_146,var=cst_non_inpatient, emp=146); %take_means(ds=ce_146,var=cst_lv_non_inpatient, emp=146);

data ce_027;
	set ce_027_cst_non_inpatient
		ce_027_cst_lv_non_inpatient;
run;

data ce_146;
	set ce_146_cst_non_inpatient
		ce_146_cst_lv_non_inpatient;
run;

proc sort data=ce_027; by variable; run;
proc sort data=ce_146; by variable; run;

data means_ce;
	merge ce_027
		  ce_146;
	by variable;
run;

title "Look at Spending for All Benes";
proc print data=means_all; run;
title;

title "Look at Spending for Continuously Enrolled Benes";
proc print data=means_ce; run;
title;



