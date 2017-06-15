libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname proc "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";
%let out=/disk/agedisk3/mktscan.work/sood/rabideau/Output;

%macro service_type(type);
	%macro loop;
		%do i=2006 %to 2013;
			proc contents data=raw.ccae&type.&i.; run;
		%end;
	%mend;
	%loop;

	/*Read in the data, keep only select contributors. Contributors were hand selected based on output from check_full_replacement.sas*/
	data &type.;
		length year month 8.;
		set raw.ccae&type.2006 (in=a where=(contributor in(024,027,146,825)))
			raw.ccae&type.2007 (in=b where=(contributor in(024,027,146,825)))
			raw.ccae&type.2008 (in=c where=(contributor in(024,027,146,825)))
			raw.ccae&type.2009 (in=d where=(contributor in(024,027,146,825)))
			raw.ccae&type.2010 (in=e where=(contributor in(024,027,146,825)))
			raw.ccae&type.2011 (in=f where=(contributor in(024,027,146,825)))
			raw.ccae&type.2012 (in=g where=(contributor in(024,027,146,825)))
			raw.ccae&type.2013 (in=h where=(contributor in(024,027,146,825)));

		/*if a then year=2006;
		else if b then year=2007;
		else if c then year=2008;
		else if d then year=2009;
		else if e then year=2010;
		else if f then year=2011;
		else if g then year=2012;
		else if h then year=2013;*/

		year=year(svcdate);
		month=month(svcdate);
		year_month=trim(left(year))||"_"||trim(left(month));

	run;

	proc sort data=&type.; by contributor enrolid year month; run;

	proc print data=&type. (obs=10); run;

	/*Merge on the continuously enrolled finder file. Finder file comes from full_replace_summary.sas
	  We need to add on age to this file. BR 6-14-17*/
	data full_replace_ce;
		set proc.full_replace_ce;
	run;

	proc sort data=full_replace_ce; by contributor enrolid; run;

	/*Make a bene-month level enrollment file from the finder file to merge onto the
	  utilization file and determine zero utilization months*/
	data full_replace_ce_ym;
		length year month 8.;
		set full_replace_ce (keep=contributor enrolid);
		%macro output_year_month;
			%do i=2006 %to 2013;
				%do j=1 %to 12;
					year=&i.;
					month=&j.;
					output;
				%end;
			%end;
		%mend;
		%output_year_month;
	run;

	title "Print the bene-year-month level enrollment file";
	proc print data=full_replace_ce_ym (obs=100); run;
	title;

	proc freq data=full_replace_ce_ym;
		tables year*month / missing;
	run;

	proc sort data=full_replace_ce_ym nodupkey; by contributor enrolid year month; run;
	proc contents data=full_replace_ce_ym; run;

	data &type._ce;
		merge &type. (in=a)
			  full_replace_ce_ym (in=b);
		by contributor enrolid year month;
		if b;

		/*Benes must be 18<=age<=64 for all years of data, 2006-2013. e.g. in 2006 an bene must be between 18 and 57 in order to not be over 64 by 2013*/
		if ((year-1988)<=age<=(year-1951)); 
		/*example: 2006-1988=18, 2006-1951=57 ---> 18<=age<=57 for claims with a service date in 2006*/
	run;


	/*Aggregate total payment to the monthly level for each contributor*/
	proc sort data=&type._ce; by contributor enrolid year month; run;

	data monthly_pay;
		set &type._ce;
		by contributor enrolid year month;
		retain tot_pay tot_services tot_deduct;
		if first.month then do;
			tot_pay=0;
			tot_services=0;
			tot_deduct=0;
		end;
		tot_pay=sum(tot_pay,pay);
		tot_services+1;
		tot_deduct=sum(tot_deduct,deduct);
		if last.month then output;
	run;

	proc univariate data=monthly_pay;
		var tot_pay tot_services tot_deduct;
	run;

	title "Check Year*Month. These values should all be identical since benes are continuously enrolled";
	proc freq data=monthly_pay;
		tables year*month;
	run;
	title;

	title "Check Year*Month for a given contributor. These values should all be identical since benes are continuously enrolled";
	proc freq data=monthly_pay;
		tables year*month;
		where contributor=024; 
	run;
	title;

	/*Take monthly means for each contributor*/
	proc sort data=monthly_pay; by contributor; run;

	%macro take_means(var);
		proc means data=monthly_pay;
			class year month;
			var &var.;
			where contributor=024;
			output out=pay024;
		run;

		proc means data=monthly_pay;
			class year month;
			var &var.;
			where contributor=027;
			output out=pay027;
		run;

		proc means data=monthly_pay;
			class year month;
			var &var.;
			where contributor=146;
			output out=pay146;
		run;

		proc means data=monthly_pay;
			class year month;
			var &var.;
			where contributor=825;
			output out=pay825;
		run;

		proc print data=pay024; run;

		/*Transpose so that each contributor has its own line*/
		%macro transpose(emp);
			data pay&emp. (keep=year month year_month &var.);
				set pay&emp.;
				if trim(left(_STAT_))="MEAN" & _TYPE_=3;
				year_month=trim(left(year))||"_"||trim(left(month));
			run;

			proc sort data=pay&emp.; by year month; run;

			proc transpose data=pay&emp. out=t_pay&emp. prefix=pay_;
				id year_month;
				var &var.;
			run;

			data t_pay&emp. (drop=_NAME_);
				length contributor 3.;
				set t_pay&emp.;
				contributor=&emp.;
			run;

			proc print data=t_pay&emp.; run;
		%mend;
		%transpose(emp=024); %transpose(emp=027); %transpose(emp=146); %transpose(emp=825);

		data t_&var._&type.;
			set t_pay:;
		run;

		proc print data=t_&var._&type.; run;
	%mend;
	%take_means(var=tot_pay); %take_means(var=tot_services); %take_means(var=tot_deduct);
%mend;
%service_type(type=o); /*Outpatient*/
%service_type(type=s); /*Inpatient*/
%service_type(type=d); /*Outpatient Pharmacy*/

/*********************
PRINT CHECK
*********************/
/*Output a sample of each of the datasets to an excel workbook*/
ods tagsets.excelxp file="&out./full_replace_monthly_pay.xml" style=sansPrinter;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Outpatient Monthly Pay" frozen_headers='yes');
proc print data=t_tot_pay_o; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Outpatient Monthly Claims" frozen_headers='yes');
proc print data=t_tot_services_o; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Outpatient Monthly Deductible" frozen_headers='yes');
proc print data=t_tot_deduct_o; run;

ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Pharmacy Monthly Pay" frozen_headers='yes');
proc print data=t_tot_pay_d; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Pharmacy Monthly Claims" frozen_headers='yes');
proc print data=t_tot_services_d; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Pharmacy Monthly Deductible" frozen_headers='yes');
proc print data=t_tot_deduct_d; run;

ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Inpatient Monthly Pay" frozen_headers='yes');
proc print data=t_tot_pay_s; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Inpatient Monthly Claims" frozen_headers='yes');
proc print data=t_tot_services_s; run;
ods tagsets.excelxp options(absolute_column_width='20' sheet_name="Inpatient Monthly Deductible" frozen_headers='yes');
proc print data=t_tot_deduct_s; run;
ods tagsets.excelxp close;
/*********************
CHECK END
*********************/
