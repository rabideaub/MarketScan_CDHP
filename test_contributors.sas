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

proc contents data=enrollment; run;

proc print data=enrollment (obs=100);
	where contributor=447;
run;

/*Check to see if the same enrollment ID is associated with multiple contributors*/
proc sort data=enrollment; by enrolid contributor; run;

data enrollee;
	set enrollment;
	retain num_contrib;
	by enrolid contributor;
	if first.enrolid then num_contrib=0;
	if first.contributor then num_contrib+1;
	if last.enrolid then output;
run;

proc univariate data=enrollee;
	var num_contrib;
run;

/*Get a count of previously identified contributors by year*/
data enrollment_cdhp;
	set enrollment;
	if contributor in("024","027","038","444","447","767","813","916","931"); /*Keep select contributors*/
run;

proc freq data=enrollment_cdhp;
	tables contributor*year / missing;
run;

proc freq data=enrollment_cdhp;
	tables contributor*year / missing;
	where plntyp1~=.;
run;

