libname POL 'E:\Local Disk F\political leanings\Political leanings fin data'; run;

*Import data;

PROC IMPORT OUT=POL.Pol1
            DATAFILE= "E:\Local Disk F\political leanings\Political leanings fin data\political_leanings_final_monthly 2017-04-15 v2.xlsx" 
            DBMS=EXCEL REPLACE;
sheet="Sheet1";
GETNAMES=YES;
MIXED=NO;
SCANTEXT=YES;
USEDATE=YES;
SCANTIME=YES;
RUN;

data POL.pol1;
	set POL.pol1;
	drop EQ_Ret FX_Ret _0yr_FI_yd_change FI_yield Month_count_from_transition;
run;

PROC IMPORT OUT=POL.election_date
            DATAFILE= "E:\Local Disk F\political leanings\Political leanings fin data\political_leanings_final_monthly 2017-04-15 v2.xlsx" 
            DBMS=EXCEL REPLACE;
sheet="Sheet3";
GETNAMES=YES;
MIXED=NO;
SCANTEXT=YES;
USEDATE=YES;
SCANTIME=YES;
RUN;

data POL.pol1;
	set POL.pol1;
	mon=month(Date_End_of_month_);
	yr=year(Date_End_of_month_);
run;

data POL.election_date;
	set POL.election_date;
	Electiondate1=input(Electiondate,MMDDYY10.);
	mon=month(Electiondate1);
	format Electiondate1 date9.;
	drop Electiondate;
run;


**finding list of distinct countries in each datasets-to check if names are same;
/*proc sort data=pol.pol1 nodupkey out=pol.country1 (keep=Country); by Country; run;*/
/**/
/*proc sort data=pol.election_date nodupkey out=pol.country2 (keep=countryname); by countryname; run;*/
/**/
/**/
/**/
/***merging country1 wu=ith country2 to check how many are matching;*/
/**/
/*proc sql;*/
/*	create table pol.country1 as*/
/*	select distinct a.*,b.**/
/*	from pol.country1 as a left join pol.country2 as b*/
/*	on a.country=b.countryname;*/
/*quit;*/


**Merging election dates with political data;

proc sql;
	create table pol.pol1 as
	select distinct a.*,b.Electiondate1 as Electiondate
	from pol.pol1 as a left join pol.election_date as b
	on a.country=b.countryname and a.mon=b.mon and a.yr=b.year;
quit;


data pol.pol1;
	set pol.pol1;
	nrow=_N_;
run;

**Creating Political_leanings_1 variable;

proc sql;
	create table pol.pol1 as
	select distinct a.*,b.Political_leanings as Political_leanings_1
	from pol.pol1 as a left join pol.pol1 as b
	on a.Country=b.Country and a.nrow=b.nrow+1;
quit;


data pol.pol1;
	set pol.pol1;
	if missing(Electiondate)=0 then Election_dummy=1;
	else Election_dummy=0;
run;


data pol.pol2;
	set pol.pol1;
	if yr<=2012;
	if missing(Electiondate)=0 then Leaning_transition=catx("_to_",Political_leanings_1,Political_leanings);
	drop Political_leanings_1 nrow mon;
run;


data pol.pol2;
	set pol.pol2;
	if Date_End_of_month_='31DEC2012'd and missing(Electiondate)=1 then Transition=0;
	if Date_End_of_month_='31DEC2012'd and Country='South Korea' then Transition=0; /*exceptional case */
run;


/*proc sort data=pol.pol2 out=pol.test; by Date_End_of_month_ Country; run;*/
