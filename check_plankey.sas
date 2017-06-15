options compress=yes mprint;

libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";

/**************************************************************
 ENROLLMENT INFORMATION
**************************************************************/
data enrollment;
	set raw.ccaea2013 (in=a )
		raw.ccaea2012 (in=b )
		raw.ccaea2011 (in=c )
		raw.ccaea2010 (in=d )
		raw.ccaea2009 (in=e )
		raw.ccaea2008 (in=f )
		raw.ccaea2007 (in=g )
		raw.ccaea2006 (in=h );

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
	missing_type=0;
	missing_key=0;
	plantype=.;
	if plntyp1~=. then plantype=plntyp1;
	if plnkey1~=. then plankey=plnkey1;
	%macro loop;
		%do i=1 %to 12;
			if plntyp&i.=. then cont_cov=0;
			if plantype~=. then do; /*Keep enrollees who were in the same plan all year*/
				if plntyp&i.~=plantype then plntyp=.;
			end;
			if enrind&i.~=. & plntyp&i.=. then missing_type=1;
			if plntyp&i.~=. & plnkey&i.=. then missing_key=1;
		%end;
	%mend;
	%loop;
	*if cont_cov=1 & plantype~=.;
run;

proc print data=enrollment (obs=20); 
	var enrolid plntyp: plnkey:;
run;

title "Check if plntyp or plnkey are ever missing when a bene is enrolled";
proc freq data=enrollment;
	tables missing_type missing_key / missing;
run;
title "Check if plntyp or plnkey are ever missing when a bene is enrolled for key contributors";
proc freq data=enrollment;
	tables missing_type missing_key / missing;
	where contributor in(024,027,146,825);
run;

/*Check if a given plan type within a contributor-year has at least 1 plan key associated with it*/
proc sort data=enrollment out=plankey nodupkey; by contributor year plantype descending plankey; run;

data plankey;
	set plankey;
	if plankey=. then no_key_for_type=1;
run;

data plankey_unique;
	set plankey;
	by contributor year plantype descending plankey;
	if first.plankey then output;
run;


title "Check all plankey associated with a plantype";
proc print data=plankey (obs=50);
	var contributor year plantype plankey no_key_for_type;
run;

proc freq data=plankey;
	tables no_key_for_type / missing;
run;
title;

title "Check only first plankey associated with a plantype";
proc print data=plankey_unique (obs=50);
	var contributor year plantype plankey no_key_for_type;
run;

proc freq data=plankey_unique;
	tables no_key_for_type / missing;
run;
title;


proc sort data=enrollment; by contributor; run;

/*Calculate the non-missingness of plantype and plankey by contributor. Approximate, based on enrollment in the first month of a year*/
data by_emp;
	set enrollment (where=(enrind1~=.));
	retain tot_plntyp tot_plnkey count;
	by contributor;
	if first.contributor then do;
		count=0;
		tot_plntyp=0;
		tot_plnkey=0;
	end;

	count+1;
	if plntyp1~=. then tot_plntyp+1;
	if plnkey1~=. then tot_plnkey+1;

	if last.contributor then do;
		if count>0 then pct_plntyp=tot_plntyp/count;
		if count>0 then pct_plnkey=tot_plnkey/count;
		if pct_plntyp>0 then pct_plnkey2=tot_plnkey/tot_plntyp;
		if pct_plnkey>.75 | pct_plnkey2>.75 then flag_contrib=1;
		output;
	end;
run;

proc print data=by_emp (obs=50); 
	var contributor count tot_plntyp tot_plnkey pct_plntyp pct_plnkey pct_plnkey2 flag_contrib;
run;
 
proc freq data=by_emp;
	tables flag_contrib / missing;
run; 

proc print data=by_emp; 
	var contributor count tot_plntyp tot_plnkey pct_plntyp pct_plnkey pct_plnkey2 flag_contrib;
	where flag_contrib=1;
run;
