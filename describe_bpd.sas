libname bpd "/disk/agedisk3/mktscan/docs/2010_2013/Users/u5935066/Documents/Research MarketScan/NBER 2014-12/8 - Benefit Plan Design/Data";
libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";

%macro loop;
	%do i=2006 %to 2013;
		libname bpd&i. "/disk/agedisk3/mktscan/docs/bpd/&i.";

		data bpd&i.;
			set bpd&i..bpd&i. (encoding='wlatin1');
			year=&i.;
		run;

		proc contents data=bpd&i.; run;
		proc print data=bpd&i. (obs=10); run;
		proc freq data=bpd&i.; 
			tables plankey / missing; 
		run;
	%end;
%mend;
%loop;

data bpd_all;
	set bpd:;
run;

proc sort data=bpd_all nodupkey; by plankey; run;

title "Check BPD for Contributor 024";
proc print data=bpd_all label;
	var plankey year fded fdedon ided idedon ioop ioopon;
	where plankey in (1308,1309,1310,1311,1312,1313,1314,1315,1316,1317,1318,1319,7214,7215,7216,7217,7218,7219,7220,7221,7222,7223,7224);
run;
title;

title "Check BPD for Contributor 027";
proc print data=bpd_all label;
	var plankey year fded fdedon ided idedon ioop ioopon;
	where plankey in (7813);
run;
title;

title "Check BPD for Contributor 146";
proc print data=bpd_all label;
	var plankey year fded fdedon ided idedon ioop ioopon;
	where plankey in (3750,3751,3752,2753,3754,3755);
run;
title;

title "Check BPD for Contributor 825";
proc print data=bpd_all label;
	var plankey year fded fdedon ided idedon ioop ioopon;
	where plankey in (3050,3051,3052,3053,3054);
run;
title;

/*I've identified 7 contributors that have good plankey data using the program check_plankey.sas. Look at those here*/
data enrollment;
	set raw.ccaea2013 (in=a where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2012 (in=b where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2011 (in=c where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2010 (in=d where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2009 (in=e where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2008 (in=f where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2007 (in=g where=(contributor in (017,028,038,179,687,690,879)))
		raw.ccaea2006 (in=h where=(contributor in (017,028,038,179,687,690,879)));

	if plnkey1~=. then plankey=plnkey1;
run;

title "Look at the plankeys for contributors that were identified to have good plankey data";
proc freq data=enrollment;
	tables contributor*plnkey1 / missing;
run;
title;

proc sort data=enrollment out=enroll_unique nodupkey; by contributor plankey; run;
proc sort data=enroll_unique; by plankey; run;

data plankey;
	merge enroll_unique (in=a)
		  bpd_all (in=b);
	by plankey;
	if a;
run;

title "Check BPD for Contributors with Good Plankeys";
proc print data=plankey label;
	var plankey year fded fdedon ided idedon ioop ioopon;
run;
title;

		  

