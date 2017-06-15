libname raw "/disk/agedisk3/mktscan/nongeo/data/001pct";
libname raw2 "/disk/agedisk3/mktscan/nongeo/data/100pct";

%macro all_parts(part);
	proc contents data=raw.ccae&part.2013; run;
	proc print data=raw.ccae&part.2013 (obs=20); run;
%mend;
*%all_parts(part=a);
*%all_parts(part=i);
*%all_parts(part=s);
*%all_parts(part=o);
*%all_parts(part=f);
*%all_parts(part=d);
*%all_parts(part=p);
*%all_parts(part=t);

%macro outpatient;
	%do i=2006 %to 2013;
		title "Outpatient Claims &i.";
		proc contents data=raw2.ccaeo&i.; run;
		proc print data=raw2.ccaeo&i. (obs=20); run;
	%end;
%mend;
%outpatient;
