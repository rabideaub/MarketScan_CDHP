/*Check for plankeys for benefit design. If none exist, keep patients who have been 
  in the same plan all year, append inpatient and outpatient*/

options compress=yes mprint;

libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname out "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";

/*******************************************************************************
DATA PREP
*******************************************************************************/
/*Read in the MarketScan Outpatient Claims datasets for select employers*/
data op;
	length year 8. prov_cat $10;
	set raw.ccaeo2006 (in=a where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2007 (in=b where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2008 (in=c where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2009 (in=d where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2010 (in=e where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2011 (in=f where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2012 (in=g where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaeo2013 (in=h where=(paidntwk="Y" & contributor in(024,027,146,825)));
	prov_cat="Outpatient";
	if trim(left(stdplac))="21" then prov_cat="Inpatient";
	if sex=1 then gdr_cd="M";
	else if sex=2 then gdr_cd="F";
	year=year(svcdate);
	rename dx1=diag1
		   dx2=diag2
		   dx3=diag3
		   dx4=diag4;
run;

title "Check Outpatient";
proc contents data=op; run;
proc print data=op (obs=10); run;
title;

/*Read in the MarketScan Inpatient Claims datasets for select employers*/
data ip;
	length year 8. prov_cat $10;
	set raw.ccaes2006 (in=a where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2007 (in=b where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2008 (in=c where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2009 (in=d where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2010 (in=e where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2011 (in=f where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2012 (in=g where=(paidntwk="Y" & contributor in(024,027,146,825)))
		raw.ccaes2013 (in=h where=(paidntwk="Y" & contributor in(024,027,146,825)));
	prov_cat="Inpatient";
	if sex=1 then gdr_cd="M";
	else if sex=2 then gdr_cd="F";
	year=year(svcdate);

	/*See if dx1 and the principle diagnosis variables are the same*/
	dif_dx1=0;
	dif_proc1=0;
	if pdx~=dx1 then dif_dx1=1;
	if pproc~=proc1 then dif_proc1=1;
	rename dx1=diag1
	   	   dx2=diag2
	  	   dx3=diag3
	   	   dx4=diag4;
run;

title "Check Inpatient";
proc contents data=ip; run;
proc print data=ip (obs=10); run;

data med;
	set op
		ip;
run;

title "All Plan Keys";
proc freq data=med;
	tables contributor*plankey / missing;
run;
title;

title "Plan Keys by Plan Type for Contributor 024";
proc freq data=med;
	tables plantyp*plankey / missing;
	where contributor=024;
run;
title;

title "Plan Keys by Plan Type for Contributor 027";
proc freq data=med;
	tables plantyp*plankey / missing;
	where contributor=027;
run;
title;

title "Plan Keys by Plan Type for Contributor 146";
proc freq data=med;
	tables plantyp*plankey / missing;
	where contributor=146;
run;
title;

title "Plan Keys by Plan Type for Contributor 825";
proc freq data=med;
	tables plantyp*plankey / missing;
	where contributor=825;
run;
title;

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

	if a then year=2013;
	if b then year=2012;
	if c then year=2011;
	if d then year=2010;
	if e then year=2009;
	if f then year=2008;
	if g then year=2007;
	if h then year=2006;

	cont_cov=1;
	cdhp_count=0;
	plantype=.;
	if plntyp1~=. then plantype=plntyp1;
	%macro loop;
		%do i=1 %to 12;
			if plntyp&i.=. then cont_cov=0;
			if plantype~=. then do; /*Keep enrollees who were in the same plan all year*/
				if plntyp&i.~=plantype then plntyp=.;
			end;
		%end;
	%mend;
	%loop;
	if cont_cov=1 & plantype~=.;
run;

proc sort data=enrollment nodupkey; by contributor enrolid year; run;
proc sort data=med; by contributor enrolid year; run;

/*Perform a m:1 merge, keeping only beneficiaries that had continuous coverage in the same plan in a given year*/
data med;
	merge med (in=a)
		  enrollment (in=b);
	by contributor enrolid year;
	if a & b;
	if deduct=. | deduct<0 then deduct=0;
run;

proc sort data=med; by contributor enrolid year plantype descending deduct; run;

/*Output total yearly deductibles in a plan. We're only interested in those who hit their max deductible, so only output
  if their deduct drops to 0 in a given year. To rule out 0's that are false maximum deductibles from services that are exempt 
  from deductibles, make sure there are at least 4 0's before outputting.*/
data yearly_deduct;
	set med;
	retain tot_deduct num_zeros;
	by contributor enrolid year plantype; 
	if first.plantype then do;
		tot_deduct=0;
		num_zeros=0;
	end;
	tot_deduct=sum(tot_deduct,deduct);
	if deduct=0 then num_zeros+1;
	if last.plantype then do;
		if num_zeros>=4 then output;
	end;
run;

/*See if the yearly deductible clusters at a certain number. A large cluster with a relatively high deductible likely
  indicates the maximum yearly deductible for a given plantype from that contributor*/

title "Distribution of Deductibles by Plantype, by Year, for Contributor 024";
proc univariate data=yearly_deduct;
	class year plantype;
	var tot_deduct;
	where contributor=024;
run;
title; 

title "Distribution of Deductibles by Plantype, by Year, for Contributor 027";
proc univariate data=yearly_deduct;
	class year plantype;
	var tot_deduct;
	where contributor=027;
run;
title; 

title "Distribution of Deductibles by Plantype, by Year, for Contributor 146";
proc univariate data=yearly_deduct;
	class year plantype;
	var tot_deduct;
	where contributor=146;
run;
title; 

title "Distribution of Deductibles by Plantype, by Year, for Contributor 825";
proc univariate data=yearly_deduct;
	class year plantype;
	var tot_deduct;
	where contributor=825;
run;
title; 


