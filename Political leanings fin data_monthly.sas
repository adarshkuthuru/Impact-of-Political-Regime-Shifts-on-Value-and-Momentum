
***IMPORT DATA;
PROC IMPORT OUT= WORK.leanings
            DATAFILE= "F:\political leanings\Political leanings fin data\Political leaning data_trading lab system\Political leanings fin data\political_leanings_final.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="political_leanings_final$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.COUNTRIES
            DATAFILE= "F:\political leanings\Political leanings fin data\Political leaning data_trading lab system\Political leanings fin data\COUNTRIES.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="SHEET1$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.EQ
            DATAFILE= "F:\political leanings\Political leanings fin data\Political leaning data_trading lab system\Political leanings fin data\pol leanings fin compiled.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="EQ_Ret$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


proc transpose data=EQ out=EQ_NEW;
  by DATE;
run;

data EQ_new1;
	set EQ_new;
	if missing(col1)=1 then delete;
run;

PROC IMPORT OUT= WORK.FI
            DATAFILE= "F:\political leanings\Political leanings fin data\Political leaning data_trading lab system\Political leanings fin data\pol leanings fin compiled.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="FI_NEW$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


proc transpose data=FI out=FI_NEW;
  by DATE;
run;

data FI_new1;
	set FI_new;
	if missing(col1)=1 then delete;
run;

PROC IMPORT OUT= WORK.FX
            DATAFILE= "F:\political leanings\Political leanings fin data\Political leaning data_trading lab system\Political leanings fin data\pol leanings fin compiled.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="FX_ret$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


proc transpose data=FX out=FX_NEW;
  by DATE;
run;

data FX_new1;
	set FX_new;
	if missing(col1)=1 then delete;
run;

                                 /****EQUITY****/



data EQ_new1;
	set EQ_new1;
	lastDay=intnx ('month',Date,0,'E');
	day=day(Date);
	month=month(Date);
	year=year(Date);
	yearmon=catx(':',year,month);
	format lastDay date9.;
run;

proc sort data=EQ_new1 out=EQ_new2(keep=Date yearmon)nodupkey; by DATE; run;

proc sort data=EQ_new2; by yearmon; run;

data EQ_months;
	set EQ_new2;
	by yearmon;
	if last.yearmon=1 then k=1;
run;

data EQ_months;
	set EQ_months;
	if missing(k)=1 then delete;
	keep Date yearmon;
run;
proc sort data=EQ_months; by Date; run;


/*to check if end of months are missing*/
data EQ_months;
	set EQ_months;
	days=intck('day',lag(date),date);
	KEEP DATE yearmon days;
run;


/* appending end of month date to dataset*/ 
proc sql;
  create table EQ_f as
  select distinct a.*, b.date as End_Date
  from EQ_new1 as a, EQ_months as b
  where a.yearmon=b.yearmon
  order by a.date, a._label_ ;
quit;



*CUMULATIVE RETURN FOR THE NEXT 1 month;

***IDENTIFY SIMILAR RETs IN HISTORICAL DATA
HISTORICAL DATA = DATA UNTIL ONE month BEFORE;


proc sort data=EQ_f; by _label_ date ; run;

data EQ_f1;
	set EQ_f;
	keep date _label_ col1 lastDay end_date;
run; 

proc sql;
  create table Next30DayReturn_EQ as
  select distinct _label_, lastDay, end_date, sum(col1) as EQ_Ret
  from EQ_f1 
  group by lastDay, end_date, _label_;
quit;


DATA Next30DayReturn_EQ1;
	SET Next30DayReturn_EQ;
	dom=_label_;
	if _label_="United States" then dom='USA';
    if _label_="United Kingdom" then dom='UKD';
	if _label_="United Arab Emirates" then dom='UAE';
	id=catt(end_date,substr(dom,1,3));
run;

/******Forex******/
data FX_new1;
	set FX_new1;
	lastDay=intnx ('month',Date,0,'E');
	day=day(Date);
	month=month(Date);
	year=year(Date);
	yearmon=catx(':',year,month);
	format lastDay date9.;
run;

proc sort data=FX_new1 out=FX_new2(keep=Date yearmon)nodupkey; by DATE; run;

proc sort data=FX_new2; by yearmon; run;

data FX_months;
	set FX_new2;
	by yearmon;
	if last.yearmon=1 then k=1;
run;

data FX_months;
	set FX_months;
	if missing(k)=1 then delete;
	keep Date yearmon;
run;
proc sort data=FX_months; by Date; run;


/*to check if end of months are missing*/
data FX_months;
	set FX_months;
	days=intck('day',lag(date),date);
	KEEP DATE yearmon days;
run;


/* appending end of month date to dataset*/ 
proc sql;
  create table FX_f as
  select distinct a.*, b.date as End_Date
  from FX_new1 as a, FX_months as b
  where a.yearmon=b.yearmon
  order by a.date, a._label_ ;
quit;



*CUMULATIVE RETURN FOR THE NEXT 1 month;


***IDENTIFY SIMILAR RETs IN HISTORICAL DATA
HISTORICAL DATA = DATA UNTIL ONE month BEFORE;


proc sort data=FX_f; by _label_ date ; run;

data FX_f1;
	set FX_f;
	keep date _label_ col1 lastDay end_date;
run; 

proc sql;
  create table Next30DayReturn_FX as
  select distinct _label_, lastDay, end_date, sum(col1) as FX_Ret
  from FX_f1 
  group by lastDay, end_date, _label_;
quit;


DATA Next30DayReturn_FX1;
	SET Next30DayReturn_FX;
	dom=_label_;
	if _label_="United States" then dom='USA';
    if _label_="United Kingdom" then dom='UKD';
	if _label_="United Arab Emirates" then dom='UAE';
	id=catt(end_date,substr(dom,1,3));
run;


/******Fixed Income******/

data FI_new1;
	set FI_new1;
	lastDay=intnx ('month',Date,0,'E');
	day=day(Date);
	month=month(Date);
	year=year(Date);
	yearmon=catx(':',year,month);
	format lastDay date9.;
run;

proc sort data=FI_new1 out=FI_new2(keep=Date yearmon)nodupkey; by DATE; run;

proc sort data=FI_new2; by yearmon; run;

data FI_months;
	set FI_new2;
	by yearmon;
	if last.yearmon=1 then k=1;
run;

data FI_months;
	set FI_months;
	if missing(k)=1 then delete;
	keep Date yearmon;
run;
proc sort data=FI_months; by Date; run;


/*to check if end of months are missing*/
data FI_months;
	set FI_months;
	days=intck('day',lag(date),date);
	KEEP DATE yearmon days;
run;


/* appending end of month date to dataset*/ 
proc sql;
  create table FI_f as
  select distinct a.*, b.date as End_Date
  from FI_new1 as a, FI_months as b
  where a.yearmon=b.yearmon
  order by a.date, a._label_ ;
quit;


proc sql;
  create table FI_f1 as
  select distinct *
  from FI_f
  where date=end_date
  order by date, _label_ ;
quit;


proc sort data=FI_f1; by _label_ date ; run;


DATA FI_f1;
	SET FI_f1;
	yd_change=col1-lag(col1);
run;

DATA FI_f1;
	SET FI_f1;
	by _label_;
	if first._label_=1 then yd_change=.;
run;

DATA Next30DayReturn_FI;
	SET FI_f1;
	FI_yield=col1;
	drop col1 _name_ dateh;
run;


DATA Next30DayReturn_FI1;
	SET Next30DayReturn_FI;
	dom=_label_;
	if _label_="United States" then dom='USA';
    if _label_="United Kingdom" then dom='UKD';
	if _label_="United Arab Emirates" then dom='UAE';
	id=catt(end_date,substr(dom,1,3));
run;
DATA Next30DayReturn_FI1;
	SET Next30DayReturn_FI1;
	drop date day month year yearmon;
run;

/** Merging with final table **/
proc sort data=Next30DayReturn_EQ1 out=Next30DayReturn_EQ2; by id; run;
proc sort data=Next30DayReturn_FX1 out=Next30DayReturn_FX2; by id ; run;
proc sort data=Next30DayReturn_FI1 out=Next30DayReturn_FI2; by id ; run;

data final;
	merge Next30DayReturn_EQ2 Next30DayReturn_FI2 Next30DayReturn_FX2;
	by id;
run;

proc sort data=final; by END_DATE _LABEL_; run;

data final;
	set final;
	drop lastDay id dom;
run;

proc sort data=final; by _label_ end_DATE; run;

/**linking political data ***/



