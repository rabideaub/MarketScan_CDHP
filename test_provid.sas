libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname proc "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
%let out=/disk/agedisk3/mktscan.work/sood/rabideau/Output;

	/*Read in the data, keep only select contributors. Contributors were hand selected based on output from check_full_replacement.sas*/
	data op;
		length year month 8.;
		set raw.ccaeo2006 (in=a where=(contributor in(024,027,146,825)))
			raw.ccaeo2007 (in=b where=(contributor in(024,027,146,825)));
		year=year(svcdate);
		month=month(svcdate);
	run;

	/*Check how many contributors are affiliated with one provider*/
	proc sort data=op; by provid contributor; run;

	data mult_contrib;
		set op;
		retain num_contrib;
		by provid contributor;
		if first.provid then num_contrib=0;
		if first.contributor then num_contrib+1;
		if last.provid then output;
	run;

	title "Count number of contributors affiliated with a single provider";
	proc freq data=mult_contrib;
		tables num_contrib / missing;
	run;

	/*Check how many plan types are affiliated with one provider*/
	proc sort data=op; by provid plantyp; run;

	data mult_plantyp;
		set op;
		retain num_plantyp;
		by provid plantyp;
		if first.provid then num_plantyp=0;
		if first.plantyp then num_plantyp+1;
		if last.provid then output;
	run;

	title "Count number of plan types affiliated with a single provider";
	proc freq data=mult_plantyp;
		tables num_plantyp / missing;
	run;

	/*Check how many years are affiliated with one provider*/
	proc sort data=op; by provid year; run;

	data mult_year;
		set op;
		retain num_year;
		by provid year;
		if first.provid then num_year=0;
		if first.year then num_year+1;
		if last.provid then output;
	run;

	title "Count number of plan types affiliated with a single provider";
	proc freq data=mult_year;
		tables num_year / missing;
	run;
