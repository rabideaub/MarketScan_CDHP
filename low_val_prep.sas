/*******************************************************************************************
********************************************************************************************
Program: low_val_prep.sas
Project: CDHP Low Value Analysis (Sood)
By: Brendan Rabideau
Created on: 5/22/17
Updated on: 5/12/17
Purpose: Assemble the raw data and create pre-existing condition flags that go into
 		 identifying low-value procedures in the next program - low_val_procs.sas

Input: MarketScan Outpatient and Inpatient Claims 2006-2013
Output: out.low_val_prep.sas7bdat

Notes: 

Updates:


*********************************************************************************************
********************************************************************************************/


/*******************************************************************************
MACRO SET
*******************************************************************************/
options compress=yes mprint;

libname raw "/disk/agedisk3/mktscan/nongeo/data/100pct";
libname out "/disk/agedisk3/mktscan.work/sood/rabideau/Data/CDHP/Processed";

/*******************************************************************************
DATA PREP
*******************************************************************************/

/*Read in the MarketScan Outpatient Claims datasets for select employers*/
data op;
	length year 8. prov_cat $10;
	set raw.ccaeo2006 (in=a where=(contributor in(024,027,146,825)))
		raw.ccaeo2007 (in=b where=(contributor in(024,027,146,825)))
		raw.ccaeo2008 (in=c where=(contributor in(024,027,146,825)))
		raw.ccaeo2009 (in=d where=(contributor in(024,027,146,825)))
		raw.ccaeo2010 (in=e where=(contributor in(024,027,146,825)))
		raw.ccaeo2011 (in=f where=(contributor in(024,027,146,825)))
		raw.ccaeo2012 (in=g where=(contributor in(024,027,146,825)))
		raw.ccaeo2013 (in=h where=(contributor in(024,027,146,825)));
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
	set raw.ccaes2006 (in=a where=(contributor in(024,027,146,825)))
		raw.ccaes2007 (in=b where=(contributor in(024,027,146,825)))
		raw.ccaes2008 (in=c where=(contributor in(024,027,146,825)))
		raw.ccaes2009 (in=d where=(contributor in(024,027,146,825)))
		raw.ccaes2010 (in=e where=(contributor in(024,027,146,825)))
		raw.ccaes2011 (in=f where=(contributor in(024,027,146,825)))
		raw.ccaes2012 (in=g where=(contributor in(024,027,146,825)))
		raw.ccaes2013 (in=h where=(contributor in(024,027,146,825)));
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

/*MarketScan_User_Guide.pdf page 19 has information which implies the principal diag\proc are the discharging
  ones on the entire inpatient admission, not necessarily the one performed on that particular date. Therefore,
  it seems like diag1 and proc1 are what were are more interested in for this project. Checks are below to 
  illustrate the differences.*/
proc freq data=ip;
	tables dif_dx1 dif_proc1 / missing;
run;
title;

title "Check Different Principle Proc and Proc1";
proc print data=ip (obs=20);
	var enrolid pdx diag1;
	where dif_dx1=1;
run;
title "Check Different Principle DX and DX1";
proc print data=ip (obs=20);
	var enrolid pproc proc1;
	where dif_proc1=1;
run;
title;

data med;
	set op
		ip;
run;

title "Check OP and IP Years";
proc freq data=med;
	table prov_cat*year / missing;
run;
title;

proc sort data=med; by enrolid; run;

/*Some conditions are identified with BETOS codes - use a xwalk to convert HCPCS to BETOS*/
data betos; 
  infile '/disk/agedisk3/mktscan.work/sood/rabideau/Documentation/BETOS_xwalk.txt'; 
  input START $ LABEL $; 
run;
data betos;
	set betos;
	FMTNAME="$BETOS";
run;
proc sort data=betos nodupkey; by START; run;
proc format cntlin=betos;
run;

/*Create BETOS and PROV_CAT vars, and remove leading and trailing blanks from key variables*/
data med;
	set med;
	betos=compress(put(proc1,$BETOS.));
	diag1=compress(diag1);
	diag2=compress(diag2);
	diag3=compress(diag3);
	diag4=compress(diag4);
	proc1=compress(proc1);
run;

title "Check Med Claims Dataset";
proc contents data=med; run;
proc print data=med (obs=20); run;
title;

proc sort data=med; by enrolid svcdate; run;


/*******************************************************************************
 ADD IN PREEXISTING CONDITION FLAGS
*******************************************************************************/
data med;
	set med (where=(18<=age<65));
	by enrolid;
	/*Retain markers for conditions that are time dependent (e.g. flag if bone density test was performed at least
	  once in the last two years)*/

	array dx [2] diag1-diag2; /*Only 2 diagnosis codes exist from 2006-2008, so we can only use 2*/

	/*Chronic Kidney Disease, Bone Density Testing, Deep Vein Thrombosis-Pulmonary Embolism,
	  Non-Cardiothoracic Surgery, Surgery, Stroke-Transient Ischemic Attack, Ischemic Heart Disease*/
	retain CKD CKD_dx CKD_dx_dt CKD_dt 
		   prebone bone_dx_dt 
		   dvt_pe dvt_pe_dt 
		   rec_dvt_pe rec_dvt_pe_dt 
		   stroke_tia stroke_tia_dx stroke_tia_dx_dt stroke_tia_dt 
		   ihd ihd_dt first_ihd_dt ihd_all
		   dialysis
		   ost ost_dt
		   b12_folate
		   hyp_cal
		   sinusitis sinusitis_dt
		   bp_dt
		   ami ami_dt first_ami_dt ami_all
		   epilepsy
		   arth arth_dx arth_dx_dt arth_dt
		   thyroid thyroid_dt
		   prepap pap_dx_dt 
		   precyst cyst_dx_dt
		   radiography radiography_dt
		   ed14 ed14_dt;


	if first.enrolid then do;
		CKD_dx_dt = .;
		CKD_dt = .;
		CKD_dx = 0;
		CKD = 0; /*Indicates confirmed CKD within last 2yrs*/

		bone_dx_dt = .;
		prebone = 0; /*Indicates a claim occurred within 2yrs of a previous bone density exam*/

		dvt_pe_dt = .;
		dvt_pe = 0; /*Indicates confirmed deep vein throm or pulm emb within last 30days*/

		rec_dvt_pe_dt = .;
		rec_dvt_pe = 0; /*Indicates recent deep vein throm or pulm emb within last 30days and prior dvt_pe >90days prior */

		stroke_tia_dx_dt = .;
		stroke_tia_dt = .;
		stroke_tia_dx = 0;
		stroke_tia = 0; /*Indicates confirmed stroke_tia within last 1yr*/

		ihd_dt = .;
		first_ihd_dt = .;
		ihd_all=0;
		ihd = 0; /*Indicates confirmed IHD between 3 months and 1yr*/

		dialysis = 0; /*Indicates a patient is undergoing dialysis - no timeframe mentioned on CCW*/

		ost = 0; /*Indicates Osteoporosis diagnosis within the last 1yr*/
		ost_dt = .; 

		b12_folate=0; /*Indicates a B12 or folate deficiency at any point in the pasat*/
		
		hyp_cal = 0; /*Indicates hypercalcemia in a 2009 claim only*/
		
		sinusitis=0; /*Indicates chronic sinusitits - a sinusitis diagnosis occurring between 30 days and 1 year before the claim*/
		sinusitis_dt=.;

		bp_dt=.; /*First observable date of back pain diagnosis*/

		ami=0; /*Indicates AMI between 3months and 1yr*/
		ami_all=0;
		first_ami_dt=.;
		ami_dt=.;

		epilepsy=0; /*Indicates epilepsy or convulsions at any point in the past*/

		arth_dx_dt = .;
		arth_dt = .;
		arth_dx = 0;
		arth = 0; /*Indicates confirmed arthritis within last 2yrs*/

		thyroid_dt=.;
		thyroid=0; /*Indicates hypothyroidism within the same year as the claim*/

		pap_dx_dt = .;
		prepap = 0; /*Indicates a claim occurred within 30months of a previous pap procedure*/

		cyst_dx_dt = .;
		precyst = 0; /*Indicates a claim occurred within 60 days of a previous adnexal cyst imaging*/

		radiography_dt=.;
		radiography=0; /*Indicates radiography within 7 days*/

		ed14_dt=.;
		ed14=0; /*Indicates ED visit within 14 days of claim*/
	end;


	do i=1 to dim(dx);
	/*CKD Diag*/
		if CKD_dt=. | (svcdate - CKD_dt > (365.25)) then CKD = 0; /*If >1yr since confirmed CKD, reset flag to 0*/
		if CKD_dx_dt=. | (svcdate-CKD_dx_dt>=(365.25)) then CKD_dx = 0; /*If >1yr since CKD dx, reset dx counter 0*/

		if dx[i] in('01600', '01601','01602','01603','01604','01605','01606','0954', '1890', '1899',
					 '2230', '23691','24940','24941','25040','25041','25042','25043','2714', '27410','587',
					 '28311','40301','40311','40391','40402','40403','40412','40413','40492','40493','586',
					 '4401', '4421', '5724', '5800', '5804', '58081','58089','5809', '5810', '5811', '5812',
					 '5813', '58181','58189','5819', '5820', '5821', '5822', '5824', '58281','58289','5829',
					 '5830', '5831', '5832', '5834', '5836', '5837', '58381','58389','5839', '5845', '5846',
					 '5847', '5848', '5849', '585',  '5851', '5852', '5853', '5854', '5855', '5856', '5859', 
					 '5880', '5881', '58881','58889','5889', '591',  '75312','75313','75314','75315','75316',
					 '75317','75319','75320','75321','75322','75323','75329','7944') then do;
			/*If one of these types CKD is confirmed. If not, 2 dx within 2yr are required*/
			if  trim(left(prov_cat)) in("Inpatient") then do; 
				CKD = 1;
				CKD_dt = svcdate;
			end;
			else if trim(left(prov_cat)) in("Outpatient") then do;
				CKD_dx +1;
				CKD_dx_dt = svcdate;
			end;
		end;
		if CKD_dx >=2 then do; /*If dx counter >=2 within 1yr, CKD is confirmed*/
			CKD = 1;
			CKD_dt = svcdate;
		end;

	/*Bone Density Testing*/
		if i=1 then do; /*Bone test is proc based, not diag based, so do not loop it like the conditions*/
			if bone_dx_dt=. | (svcdate-bone_dx_dt>(365.25*2)) then prebone=0; 
			if proc1 in('76977','77078','77079','77080','77083','78350','78351') then do;
			   prebone+1;
			   bone_dx_dt=svcdate;
			end;
		end;

	/*DVT-PE*/
		if svcdate-dvt_pe_dt>30 | dvt_pe_dt=. then dvt_pe=0; /*if 30 days since DVT_PE dx, reset flag to 0*/
		if dx[i] in('4151', '4510', '45111', '45119', '4512', '45181', '4519', '4534', 'V1251') then do;
			dvt_pe=1;
			if dvt_pe_dt=. then rec_dvt_pe_dt=svcdate; /*First diagnosis of DVT_PE only*/
			dvt_pe_dt=svcdate;
		end;

		/*if 90 days after original DVT_PE dx AND there is another DVT_PE diagnosis within 30 days, set recurrent thrombosis flag = 1*/
		if svcdate-rec_dvt_pe_dt>90 & rec_dvt_pe_dt~=. & dvt_pe=1 then rec_dvt_pe=1; 
			
	/*Stroke-TIA*/
		do j = 1 to dim(dx);
			/*Exclusionary criteria. If these conditions are met do not count this obs towards the Stroke_TIA indicator,
			  however if there is a history of Stroke_TIA within a year that is still retained*/
			if substr(dx[j],1,3) in('800','801','802','803','804','850','851','852','853','854') |
			   substr(diag1,1,3) in('V57') then skip_step=1; 
		end;

		/*If >1yr since confirmed stroke_TIA, reset flag to 0*/
		if stroke_TIA_dt=. | (svcdate - stroke_TIA_dt > (365.25)) then stroke_TIA = 0; 
		/*If >1yr since stroke_TIA dx, reset dx counter to 0*/
		if stroke_TIA_dx_dt=. | (svcdate-stroke_TIA_dx_dt>=(365.25)) then stroke_TIA_dx = 0;

		if skip_step~=1 then do; /*Skip this step if exclusionary criteria are present*/
			if dx[i] in('430',  '431',  '43301', '43311', '43321','43331','43381','43391','43400','43401',
		     		    '43410','43411','43490', '43491', '4350', '4351', '4353', '4358', '4359', '436',  '99702') then do;
				if  trim(left(prov_cat)) in("Inpatient") then do; /*If inpatient and dx then confirmed stroke_TIA*/
					stroke_TIA = 1;
					stroke_TIA_dt = svcdate;
				end;
				else if trim(left(prov_cat)) in("Outpatient") then do;
					stroke_TIA_dx +1;
					stroke_TIA_dx_dt = svcdate;
				end;
			end;
			if stroke_TIA_dx >=2 then do; /*If 2 dx within 1yr, confirmed stroke_TIA*/
				stroke_TIA = 1;
				stroke_TIA_dt = svcdate;
			end;
		end;

		/*Ischemic Heart Disease between 3 months and 1 year*/
		if IHD_dt=. | (svcdate - IHD_dt > (365.25)) then IHD = 0; /*If >1yr since confirmed IHD, reset flag to 0*/

		if dx[i] in('41000', '41001', '41002', '41010', '41011', '41012', '41020', '41021', '41022', '41401',
					'41030', '41031', '41032', '41040', '41041', '41042', '41050', '41051', '41052', '41060',	
					'41061', '41062', '41070', '41071', '41072', '41080', '41081', '41082', '41090', '41091',	
					'41092', '4110',  '4111',  '41181', '41189', '412',   '4130',  '4131',  '4139',  '41400', 
					'41402', '41403', '41404', '41405', '41406', '41407', '41412', '4142',  '4143',  '4144',	
				    '4148',  '4149'	) & trim(left(prov_cat)) in("Outpatient","Inpatient") then do;
			if IHD_dt=. then first_ihd_dt=svcdate;
			IHD = 1;
			IHD_all=1;
			IHD_dt = svcdate;
		end;

		if IHD=1 & 0<=svcdate-first_ihd_dt<=(30.4*3) then IHD=0; /*If it is within 3 months of the first IHD detection, set to 0*/

		/*Dialysis*/
		if betos in('P9A','P9B') | betos1 in('P9A','P9B') | betos2 in('P9A','P9B') | betos3 in('P9A','P9B')
		then dialysis=1;

		/*Osteoporosis Diag*/
		if ost_dt=. | (svcdate - ost_dt > (365.25)) then ost = 0; /*If >1yr since confirmed ost, reset flag to 0*/

		if dx[i] in('73300', '73301', '73302', '73303', '73309') then do;
			/*If one of these types, ost is confirmed*/
			if  trim(left(prov_cat)) in("Outpatient","Inpatient") then do; 
				ost = 1;
				ost_dt = svcdate;
			end;
		end;

		/*B12 or Folate disorders*/
		if dx[i] in('2662','2704','2810','2811','2812','2859') then b12_folate=1;

		/*Hypercalcemia Diagnosis in 2009*/
		if dx[i] in('2754') & year=2009 then hyp_cal=1;

		/*Chronic Sinusitis (last diagnosis between 30 days and 1 year ago)*/
		if sinusitis_dt=. | (svcdate - sinusitis_dt > 365.25 | svcdate - sinusitis_dt < 30 ) then sinusitis = 0;
		else if 30 <= svcdate - sinusitis_dt <= 365.25 then sinusitis = 1;

		if substr(dx[i],1,3) in('461','473') then do;
			sinusitis_dt = svcdate;
		end;

		/*First diagnosis of back pain indicator*/
		if bp_dt = . & dx[i] in('7213','72190','72210','72252','7226','72293','72402','7242',
								'7243','7244','7245','7246','72470','72471','72479','7385',
								'7393','7394','8460','8461','8462','8463','8468','8469','8472') then bp_dt=svcdate;
		
		/*AMI between 3 months and 1 year in an inpatient setting*/
		if ami_dt=. | (svcdate - ami_dt > (365.25)) then ami = 0; /*If >1yr since confirmed ami, reset flag to 0*/

		if dx[1] in('41001', '41011', '41021', '41031', '41041', '41051', '41061', '41071', '41081', '41091') | /*Only the 1st and 2nd DX count*/
		   dx[2] in('41001', '41011', '41021', '41031', '41041', '41051', '41061', '41071', '41081', '41091') then do;
			if  trim(left(prov_cat)) in("Inpatient") then do; /*Only an Inpatient setting counts*/
				if ami_dt=. then first_ami_dt=svcdate;
				ami = 1;
				ami_all=1;
				ami_dt = svcdate;
			end;
		end;
		if ami=1 & 0<=svcdate-first_ami_dt<=(30.4*3) then ami=0; /*If it is within 3 months of the first AMI detection, set to 0*/

		/*Epilepsy or Convulsions*/
		if substr(dx[i],1,3) in('345') | substr(dx[i],1,4) in('7803','7810') then epilepsy=1;

		/*Arthritis*/
		if arth_dt=. | (svcdate - arth_dt > (365.25)) then arth = 0; /*If >1yr since confirmed arth, reset flag to 0*/
		if arth_dx_dt=. | (svcdate-arth_dx_dt>=(365.25)) then arth_dx = 0; /*If >1yr since arth dx, reset dx counter 0*/

		if dx[i] in('7140','7141','7142','71430','71431','71432','71433','71500','71504','71509','71510',
					'71511','71512','71513','71514','71515','71516','71517','71518','71520','71521','71522',
					'71523','71524','71525','71526','71527','71528','71530','71531','71532','71533','71534',
					'71535','71536','71537','71538','71580','71589','71590','71598') then do;
			if trim(left(prov_cat)) in("Outpatient","Inpatient") then do;
				arth_dx +1;
				arth_dx_dt = svcdate;
			end;
		end;
		if arth_dx >=2 then do; /*If dx counter >=2 within 2yr, arth is confirmed*/
			arth = 1;
			arth_dt = svcdate;
		end;

	/*Hypothyroidism*/
		if thyroid_dt=. | (svcdate - thyroid_dt > (365.25)) then thyroid = 0; /*If >1yr since confirmed hypothyroidism, reset flag to 0*/

		if substr(dx[i],1,3) in('244') then do;
			thyroid = 1;
			thyroid_dt = svcdate;
		end;

	/*Annual Pap Testing*/
		if i=1 then do; /*pap test is proc based, not diag based, so do not loop it like the conditions*/
			if pap_dx_dt=. | (svcdate-pap_dx_dt>(30.4*30)) then prepap=0; /*Within 30 months*/
			if proc1 in('88141', '88142', '88143', '88147', '88148', '88150', '88152', '88153', '88154', 
					      '88164', '88165', '88166', '88167', '88174', '88175', 'G0123', 'G0124', 'G0141', 
					      'G0143', 'G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'Q0091') then do;
			   prepap+1;
			   pap_dx_dt=svcdate;
			end;
		end;

	/*Annual cyst Testing*/
		if i=1 then do; /*cyst test is proc based, not diag based, so do not loop it like the conditions*/
			if cyst_dx_dt=. | (svcdate-cyst_dx_dt>(60)) then precyst=0; /*Within 60 days*/
			if proc1 in('76857','76830') then do;
			   precyst+1;
			   cyst_dx_dt=svcdate;
			end;
		end;

	/*Upper Extremity Radiography*/
		if radiography_dt=. | (svcdate - radiography_dt > (7)) then radiography = 0; /*If >7days since confirmed radiography claim, reset flag to 0*/

		if proc1 in('25600', '25605', '25609', '25611', '73000', '73010', '73020', '73030', 
					  '73040', '73050','73090', '73092', '73100', '73110', '73115','73120', '73130', '73140','73200', 
					  '73201', '73202', '73206','73218', '73219', '73220', '73221','73222', '73223', '73225') |
		   			  '23600'<=:proc1<=:'23630' | '23665'<=:proc1<=:'23680' then do;

			radiography = 1;
			radiography_dt = svcdate;
		end;

	/*ED Visit Within 14 Days*/
		if ed14_dt=. | (svcdate - ed14_dt > (14)) then ed14 = 0; /*If >14days since confirmed ED visit, reset flag to 0*/
		if trim(left(stdplac)) in('23') then do;
			ed14=1;
			ed14_dt=svvdate;
		end;

	/*Close the loop*/
	end;


	/*Make a flag for emergency rooms visits*/
	ed=(trim(left(stdplac))="23");
run;


/*Same as data step above, but had to re-sort by descending svcdate since it checks if a procedure was
  done 30days BEFORE a surgery, as opposed to x-days after an event like above*/
proc sort data=med; by enrolid descending svcdate; run;

data out.low_val_prep;
	set med;
	by enrolid;

	array proc [1] proc1;
	array beto[1] betos; 

	/*Non-Cardiothoracic Surgery, Surgery*/
	retain nc_surge nc_surge_dt
		   surge surge_dt
		   post_dialysis post_dial_dt
		   radiography radiography_dt;

	if first.enrolid then do;
		nc_surge_dt = .;
		surge_dt = .;
		post_dial_dt = .;
		radiography_dt = .;

		nc_surge = 0; /*Indicates noncardiothoracic surgery coming up within 30days*/
		surge = 0;	  /*Indicates surgery coming up within 30days*/
		post_dialysis = 0; /*Indicates dialysis coming up within 30 days*/
		radiography = 0; /*Indicates upper body radiography coming up within 7 days*/
	end;
	
	do i=1 to dim(proc);
	/*Preoperative Testing Surgical Dates*/
		if proc[i] in('19120', '19125', '47562', '47563', '49560', '58558') |
		   beto[i] in ('P1x','P3D','P4A','P4B','P4C','P5C','P5D','P8A','P8G') |
		   substr(beto[i],1,2) in ('P1') then do; /*non-cardiothoracic surgery*/
			nc_surge_test=1;
			nc_surge=1;
			nc_surge_dt=svcdate;
		end;
		if nc_surge_dt-svcdate>30 | nc_surge_dt=. then nc_surge=0;

		if beto[i] in ('P1x','P2x','P3D','P4A','P4B','P4C','P5C','P5D','P8A','P8G') |
		   substr(beto[i],1,2) in ('P1','P2') then do;/*surgery*/
		    surge_test=1;
			surge=1;
			surge_dt=svcdate;
		end;
		if surge_dt-svcdate>30 | surge_dt=. then surge=0;
	end;

	/*Upcoming Dialysis Testing*/
		if betos in('P9A','P9B') | betos1 in('P9A','P9B') | betos2 in('P9A','P9B') | betos3 in('P9A','P9B') then do;
		    post_dialysis=1;
		    post_dial_dt=svcdate;
		end;
		if post_dial_dt-svcdate>30 | post_dial_dt=. then post_dialysis=0;

	/*Upper Extremity Radiography*/
		if proc1 in('25600', '25605', '25609', '25611', '73000', '73010', '73020', '73030', 
					  '73040', '73050','73090', '73092', '73100', '73110', '73115','73120', '73130', '73140','73200', 
					  '73201', '73202', '73206','73218', '73219', '73220', '73221','73222', '73223', '73225') |
		   			  '23600'<=:proc1<=:'23630' | '23665'<=:proc1<=:'23680' then do;

			radiography = 1;
			radiography_dt = svcdate;
		end;
		if radiography_dt=. | (radiography_dt-svcdate > (7)) then radiography = 0; /*If >7days before confirmed radiography claim, reset flag to 0*/

run;

%macro out;
	/*Make a flag for an inpatient confinement that includes an ED stay*/
	proc sort data=out.low_val_prep; by conf_id descending ed; run;

	data out.low_val_prep;
		set out.low_val_prep;
		retain ed_stay;
		by conf_id;
		if first.conf_id & conf_id~="" then ed_stay=ed; /*Flag all claims in a confinement that had at least 1 ED stay*/
	run;
%mend;

title "Check Key Variables";
proc freq data=out.low_val_prep;
	tables 	
		CKD 
		prebone  
		dvt_pe 
		rec_dvt_pe  
		stroke_tia  
		ihd 
		dialysis  
		ost  
		b12_folate
		hyp_cal  
		sinusitis
		ami
		epilepsy
		arth  
		thyroid
		prepap  
		precyst
		radiography
		/*ed14*/
		nc_surge
		surge
		post_dialysis
		prov_cat
		stdplac / missing nocum nocol norow;
run;
