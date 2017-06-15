libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
%let out = /disk/agedisk3/mktscan.work/sood/rabideau/Output;
%include "/disk/agedisk3/mktscan.work/sood/rabideau/Programs/CDHP/gen_chisq.sas";

data enrollment;
	set raw.ccaea2013 (in=a)
		raw.ccaea2012 (in=b)
		raw.ccaea2011 (in=c)
		raw.ccaea2010 (in=d)
		raw.ccaea2009 (in=e)
		raw.ccaea2008 (in=f)
		raw.ccaea2007 (in=g)
		raw.ccaea2006 (in=h);
	if plntyp1~=. then cdhp=0;
	if (plntyp1=8 | plntyp1=9) then cdhp=1;
	if a then year=2013;
	if b then year=2012;
	if c then year=2011;
	if d then year=2010;
	if e then year=2009;
	if f then year=2008;
	if g then year=2007;
	if h then year=2006;

run;

proc print data=enrollment (obs=10); run;
proc contents data=enrollment; run;

proc freq data=enrollment;
	tables year plntyp1*year cdhp*year;
run;

proc sort data=enrollment; by contributor year; run;

data enrollment_year;
	set enrollment;
	retain tot_cdhp tot_enroll;
	by contributor year;
	if first.year then do;
		tot_cdhp=0;
		tot_enroll=0;
	end;
	if plntyp1~=. then tot_enroll+1;
	if cdhp=1 then tot_cdhp+1;
	if tot_enroll~=0 then prop_cdhp=tot_cdhp/tot_enroll;
	if last.year then output;
run;

proc print data=enrollment_year (obs=60); run;

proc transpose data=enrollment_year out=enrollment_contrib prefix=prop_cdhp;
	by contributor;
	id year;
	var prop_cdhp;
run;

proc transpose data=enrollment_year out=enrollment_n prefix=n_;
	by contributor;
	id year;
	var tot_enroll;
run;

proc sort data=enrollment_contrib; by contributor; run;
proc sort data=enrollment_n; by contributor; run;

data enrollment_contrib;	
	merge enrollment_contrib
		  enrollment_n;
	by contributor;

	%macro loop;
		%do i=2006 %to 2013;
			if prop_cdhp&i.~=. then percent_cdhp&i.=put(prop_cdhp&i.,percent8.2) || " (n=" || trim(left(n_&i.)) || ")";
		%end;
	%mend;
	%loop;
run;

proc univariate data=enrollment_contrib;
	var prop_cdhp2006 n_2006 prop_cdhp2013 n_2013;
run;

proc means data=enrollment_contrib;
	var prop_cdhp2006 prop_cdhp2013;
run;

proc print data=enrollment_contrib (obs=20); run;

proc sort data=enrollment_contrib; by contributor; run;

data full_replace;
	set enrollment_contrib (where=(prop_cdhp2013~=.));
	/*Check to see if at least 1 year has low CDHP enrollment, while the most recent year has high enrollment*/
	%macro loop;
		%do i=2006 %to 2012;
			if prop_cdhp&i.~=. & prop_cdhp&i.<=.33 then low_cdhp=1;
		%end;
	%mend;
	%loop;
	if low_cdhp & prop_cdhp2013 >=.67;
run;

	/*********************
	PRINT CHECK
	*********************/
	/*Output a sample of each of the datasets to an excel workbook*/
	ods tagsets.excelxp file="&out./cdhp_replacement..xml" style=sansPrinter;
	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="All Contributors" frozen_headers='yes');
	proc print data=enrollment_contrib;
		var contributor percent_cdhp:;
	run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Full Replacement" frozen_headers='yes');
	proc print data=full_replace;
		var contributor percent_cdhp:;
	run;
	ods tagsets.excelxp close;
	/*********************
	CHECK END
	*********************/

data full_replace_id;
	set full_replace (keep=contributor);
run;

proc sort data=full_replace_id;	by contributor; run;

data enrollment_cdhp (keep=contributor agegrp eeclass eestatu emprel indstry rx sex unique_company full_replace);
	merge enrollment (in=a)
		  full_replace_id (in=b);
	by contributor;
	if b then full_replace=1;
	else full_replace=0;
	if first.contributor then unique_company=1;
run;

proc freq data=enrollment_cdhp;
	tables unique_company / missing;
run;

%chisq(ds=enrollment_cdhp,cutoff=20,byvar=full_replace,subset=,formats=N);
