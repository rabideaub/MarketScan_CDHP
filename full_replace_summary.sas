/*The purpose of this program is to take the employers (contributors) identified as full replacement
  and those identified as corresponding controls (manually selected based on output from check_full_replacement.sas)
  and check their observable characteristics over time. Select charactertistics are sex, age, continuous enrollment,
  CDHP enrollment, and yearly survival/attrition. Outputs are a listing file and a finder file of all enrollees
  continuously enrolled from 1/2006 - 12/2013*/

libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname proc "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
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
	set raw.ccaea2013 (in=a)
		raw.ccaea2012 (in=b)
		raw.ccaea2011 (in=c)
		raw.ccaea2010 (in=d)
		raw.ccaea2009 (in=e)
		raw.ccaea2008 (in=f)
		raw.ccaea2007 (in=g)
		raw.ccaea2006 (in=h);

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

	if contributor in (024,027,146,825);
	if contributor in (024,027) then full_replace=1;
	else if contributor in (146,825) then full_replace=0;
run;

proc print data=enrollment (obs=20); run;

proc freq data=enrollment; 
	tables cont_cov*cdhp / missing;
run;

title "Demographics by Year for Contributor 024";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (cdhp agegrp sex)*year / missing;
	where contributor in(024) & cont_cov=1;
run;
title "Demographics by Year for Contributor 027";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (cdhp agegrp sex)*year / missing;
	where contributor in(027) & cont_cov=1;
run;
title "Demographics by Year for Contributor 146";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (agegrp sex)*year / missing;
	where contributor in(146) & cont_cov=1;
run;
title "Demographics by Year for Contributor 825";
proc freq data=enrollment;
	format cdhp cdhp. agegrp $agegrp. sex $sex.;
	tables (cdhp agegrp sex)*year / missing;
	where contributor in(825) & cont_cov=1;
run;
title;

proc sort data=enrollment; by contributor; run;

proc means data=enrollment;
	class year;
	by contributor;
	var age;
	where cont_cov=1;
run;

/*Count number continuously enrolled per year and percent enrolled consecutively from first year in a given year*/
proc sort data=enrollment; by contributor enrolid year; run;

proc transpose data=enrollment out=t_enrollment prefix=Y;
	by contributor enrolid;
	id year;
	var cont_cov;
run;

proc print data=t_enrollment (obs=20); run;

data t_enrollment_flat;
	set t_enrollment;
	by contributor;
	retain t2006-t2013 c2006-c2013;
	if first.contributor then do;
		%macro loop1;
			%do i=2006 %to 2013;
				t&i.=0;
				c&i.=0;
			%end;
		%mend;
		%loop1;
	end;

	consec_var=0;
	%macro loop2;
		%do i=2006 %to 2013;
			if y&i.=1 then do;
				t&i.+1; /*Total people enrolled in a given year*/
				if consec_var=(&i.-2006) then consec_var+1; 
				if consec_var=(&i.-2005) then c&i.+1; /*Identify people who have been continuously enrolled since 2006*/
			end;
		%end;
	%mend;
	%loop2;

	if last.contributor then do;
		%macro loop3;
			%do i=2006 %to 2013;
				if t2006>0 then pct&i.=c&i./t2006; /*Percentage of people from 2006 cohort who have been continuously enrolled up to the given year*/
			%end;
		%mend;
		%loop3;

		%macro loop4;
			%do i=2007 %to 2013;
				%let j=%eval(&i.-1);
				if c&j.>0 then d&i.=(c&i. - c&j. )/c&j.; /*Percentage change in the number of continuously enrolled population. ((c2007-c2006)/c2006)*/
			%end;
		%mend;
		%loop4;
		output;
	end;
run;

proc print data=t_enrollment_flat; run;

/*Count number continuously enrolled CDHP beneficiaries per year*/
proc sort data=enrollment; by contributor enrolid year; run;

proc transpose data=enrollment out=cdhp_enrollment prefix=CDHP_;
	by contributor enrolid;
	id year;
	var cdhp;
run;

proc print data=cdhp_enrollment (obs=20); run;

data cdhp_enrollment_flat;
	set cdhp_enrollment;
	by contributor;
	retain cdhp2006-cdhp2013 cCDHP2006-cCDHP2013 c2006-c2013;
	if first.contributor then do;
		%macro loop1;
			%do i=2006 %to 2013;
				cdhp&i.=0;
				cCDHP&i.=0;
				c&i.=0;
			%end;
		%mend;
		%loop1;
	end;

	consec_var=0;
	%macro loop2;
		%do i=2006 %to 2013;
			if CDHP_&i.~=. then do; /*CDHP of 0 or 1 means they were consecutively enrolled for a whole year, missing means not*/
				if CDHP_&i.=1 then cdhp&i.=cdhp&i.+1; /*Total people enrolled in a given year*/
				if consec_var=(&i.-2006) then consec_var+1; 
				if consec_var=(&i.-2005) & CDHP_&i.=1 then cCDHP&i.+1; /*Identify people who have been continuously enrolled since 2006 and are in a CDHP in a given year*/
				if consec_var=(&i.-2005) then c&i.+1; /*This should be the same as the above dataset t_enrollment. This is a test*/

			end;
		%end;
	%mend;
	%loop2;

	if last.contributor then do;
		%macro loop3;
			%do i=2007 %to 2013;
				%let j=%eval(&i.-1);
				if cCDHP&j.>0 then dCDHP&i.=(cCDHP&i. - cCDHP&j. )/cCDHP&j.; /*Percentage change in the number of continuously, CDHP enrolled population. ((cCDHP2007-cCDHP2006)/cCDHP2006)*/
			%end;
		%mend;
		%loop3;
		output;
	end;
run;

proc print data=cdhp_enrollment_flat (obs=20); run;

/*Check for statistical significance between full replacement and non-replacement contributors*/
data enrollment_cdhp (keep=contributor agegrp eeclass eestatu emprel indstry rx sex unique_company full_replace);
	set enrollment;
run;

*%chisq(ds=enrollment_cdhp,cutoff=20,byvar=full_replace,subset=,formats=N);

/*Output a finder file with patients continuously enrolled from 2006 to 2013 in our target companies*/
data proc.full_replace_ce (keep=contributor enrolid);
	set t_enrollment; /*t_enrollment is the transposed enrollment file at the contrib-enrolid level. Variables y20XX are yearly enrollment flags*/
	if sum(of y2006-y2013)=8 then keep=1;
	if keep=1;
run;




