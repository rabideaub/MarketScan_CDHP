libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname proc "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
libname final "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Final";
%let out = /disk/agedisk3/mktscan.work/sood/rabideau/Output;

data enrollment;
	length plan $13;
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
	plantype=.;
	%macro loop;
		%do i=1 %to 12;
			if plntyp&i=. then cont_cov=0;
			if plantype=. then do;
				if plntyp&i.~=. then plantype=plntyp&i.; /*Set the plantype to the first one the bene is in*/
			end; 
		%end;
	%mend;
	%loop;
	if a then year=2013;
	if b then year=2012;
	if c then year=2011;
	if d then year=2010;
	if e then year=2009;
	if f then year=2008;
	if g then year=2007;
	if h then year=2006;

	if plantype=1 then plan="1 = B/MM";
	else if plantype=2 then plan="2 = COMP";
	else if plantype=3 then plan="3 = EPO";
	else if plantype=4 then plan="4 = HMO";
	else if plantype=5 then plan="5 = NoCap POS";
	else if plantype=6 then plan="6 = PPO";
	else if plantype=7 then plan="7 = Cap POS";
	else if plantype=8 then plan="8 = CDHP";
	else if plantype=9 then plan="9 = CDHP";
	else do;
		plantype=10;
		plan="Other";
	end;

	if cont_cov=1; /*Keep only those enrolled all 12 months of the year*/
run;

proc sort data=enrollment; by contributor plan; run;

/*Collapse at the contributor level by year*/
%macro loop1;
	%do i=2006 %to 2013;
		data collapse_contrib_&i. (keep=contributor count_&i.);
			set enrollment (where=(year=&i.));
			retain count_&i.;
			by contributor;
			if first.contributor then do;
				count_&i.=0;
			end;
			count_&i.+1;
			if last.contributor then output;
		run;

		proc sort data=collapse_contrib_&i.; by contributor; run;

		proc print data=collapse_contrib_&i. (obs=10); run;
	%end;
%mend;
%loop1;

data contrib_collapsed;
	merge collapse_contrib_:;
	by contributor;
run;

proc print data=contrib_collapsed (obs=10); run;

/*Same as above, but collapse at the contributor plan level by year*/
%macro loop2;
	%do i=2006 %to 2013;
		data collapse_plan_&i. (keep=contributor plan count_&i.);
			set enrollment (where=(year=&i.));
			retain count_&i.;
			by contributor plan;
			if first.plan then do;
				count_&i.=0;
			end;
			count_&i.+1;
			if last.plan then output;
		run;

		proc sort data=collapse_plan_&i.; by contributor plan; run;

		proc print data=collapse_plan_&i. (obs=10); run;
	%end;
%mend;
%loop2;

data plan_collapsed (drop=contributor);
	length employer $3;
	merge collapse_plan_:;
	by contributor plan;
	if first.contributor then employer=put(trim(left(contributor)),3.);
	if ~first.contributor then employer='';
run;

proc print data=plan_collapsed (obs=10); run;

/*Same as the loop above but output a new dataset for each plan by year*/
%macro loop3;
	%do j=1 %to 10;
		%do i=2006 %to 2013;

			/*Check if the dataset will exist before running code, otherwise it will halt program*/
			proc freq data=enrollment;
				tables plantype / out=exist_&j._&i.;
				where year=&i. & plantype=&j.;
			run;

			%macro nobs(data,name); /*Observation counting macro. BR 5-9-17*/
				%global &name.; 
					data _null_;
						if 0 then set &data. nobs=count; 
						call symput ("&name.",trim(left(put(count,9.)))); 
						stop; 
					run; 
				%mend nobs;
				%nobs(data=exist_&j._&i., name=obs); 

			%put &obs.;

			%if "&obs."~="0" %then %do;

				data collapse_&j._&i. (keep=contributor plan count_&i.);
					set enrollment (where=(year=&i. & plantype=&j.));
					retain count_&i.;
					by contributor plan;
					if first.plan then do;
						count_&i.=0;
					end;
					count_&i.+1;
					if last.plan then output;
				run;

				proc sort data=collapse_&j._&i.; by contributor plan; run;

				proc print data=collapse_&j._&i. (obs=10); run;
			%end;
		%end;

		%if %sysfunc(exist(collapse_&j._2006)) |
			%sysfunc(exist(collapse_&j._2007)) |
			%sysfunc(exist(collapse_&j._2008)) |
			%sysfunc(exist(collapse_&j._2009)) |
			%sysfunc(exist(collapse_&j._2010)) |
			%sysfunc(exist(collapse_&j._2011)) |
			%sysfunc(exist(collapse_&j._2012)) |
			%sysfunc(exist(collapse_&j._2013)) %then %do;

			data collapsed_&j.;
				merge collapse_&j._:;
				by contributor plan;
			run;

			title "Look at Plan Type &j. by Year";
			proc print data=collapsed_&j. (obs=10); run;
			title;
		%end;
	%end;
%mend;
%loop3;

/*Output to an excel workbook*/
ods tagsets.excelxp file="&out./yearly_plantype_counts.xml" style=sansPrinter;
	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Contributor" frozen_headers='yes');
	proc print data=contrib_collapsed; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Contrib-Plan" frozen_headers='yes');
	proc print data=plan_collapsed; run;

	%macro check_exist; /*This is all missing with the 1% sample, but maybe its just very rare, so include this*/
		%if %sysfunc(exist(collapsed_1)) %then %do;
			ods tagsets.excelxp options(absolute_column_width='20' sheet_name="1 = B/MM" frozen_headers='yes');
			proc print data=collapsed_1; run;
		%end;
	%mend;
	%check_exist;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 2 = COMP" frozen_headers='yes');
	proc print data=collapsed_2; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 3 = EPO" frozen_headers='yes');
	proc print data=collapsed_3; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 4 = HMO" frozen_headers='yes');
	proc print data=collapsed_4; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 5 = NoCap POS" frozen_headers='yes');
	proc print data=collapsed_5; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 6 = PPO" frozen_headers='yes');
	proc print data=collapsed_6; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 7 = Cap POS" frozen_headers='yes');
	proc print data=collapsed_7; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 8 = CDHP" frozen_headers='yes');
	proc print data=collapsed_8; run;

	ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 9 = CDHP" frozen_headers='yes');
	proc print data=collapsed_9; run;

	%macro check_exist2; /*This is all missing with the 1% sample, but maybe its just very rare, so include this*/
		%if %sysfunc(exist(collapsed_10)) %then %do;
			ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Plan 10 = Other" frozen_headers='yes');
			proc print data=collapsed_10; run;
		%end;
	%mend;
	%check_exist2;
ods tagsets.excelxp close;
