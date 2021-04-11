
***IMPORT DATA;
PROC IMPORT OUT= WORK.leanings
            DATAFILE= "C:\Users\30970\Desktop\Political leaning data\Political leanings fin data\political_leanings_final.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="political_leanings_final$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.COUNTRIES
            DATAFILE= "C:\Users\30970\Desktop\Political leaning data\Political leanings fin data\COUNTRIES.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="SHEET1$";
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.EQ
            DATAFILE= "C:\Users\30970\Desktop\Political leaning data\Political leanings fin data\pol leanings fin compiled.xlsx"
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
            DATAFILE= "C:\Users\30970\Desktop\Political leaning data\Political leanings fin data\pol leanings fin compiled.xlsx"
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
            DATAFILE= "C:\Users\30970\Desktop\Political leaning data\Political leanings fin data\pol leanings fin compiled.xlsx"
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

***DD AT THE END OF WEDNESDAY OF EACH WEEK;
proc sql;
  create table EQ_Wed as
  select distinct *
  from EQ_NEW1
  where weekday(date)=4;
quit;
proc sql;
  create table FI_Wed as
  select distinct *
  from FI_NEW1
  where weekday(date)=4;
quit;
proc sql;
  create table FX_Wed as
  select distinct *
  from FX_NEW1
  where weekday(date)=4;
quit;

/*to check if any wednesdays are missing*/
data EQ1;
	set EQ_Wed;
run;
proc sort data=EQ1 out=EQ2 nodupkey; by DATE; run;
data EQ2;
	set EQ2;
	days=intck('day',lag(date),date);
	KEEP DATE days;
run;

data FI1;
	set FI_Wed;
run;
proc sort data=FI1 out=FI2 nodupkey; by DATE; run;
data FI2;
	set FI2;
	days=intck('day',lag(date),date);
	KEEP DATE days;
run;

data FX1;
	set FX_Wed;
run;
proc sort data=FX1 out=FX2 nodupkey; by DATE; run;
data FX2;
	set FX2;
	days=intck('day',lag(date),date);
	KEEP DATE days;
run;

/* creating date-wise & country-wise list*/ 
proc sql;
  create table datef as
  select distinct a.country, b.date
  from Countries as a, EQ2 as b;
quit;
proc sort data=datef ; by DATE Country; run;



***CALCULATE NEXT 5 TRADING DAY CUMULATIVE RETURN (THAT IS, NEXT 7 CALENDAR DAY RETURN) FOLLOWING HISTORICAL DDs;
*NEXT 5 TRADING DAYS (OR NEXT 7 CALENDAR DAYS);

*CUMULATIVE RETURN FOR THE NEXT 1 WEEK;

/******Equity******/

***IDENTIFY SIMILAR RETs IN HISTORICAL DATA
HISTORICAL DATA = DATA UNTIL ONE WEEK BEFORE;
data EQ_NEW1;
  set EQ_NEW1;
  dateh = intnx("day",date,7);
  format dateh date9.;
run;
proc sql;
  create table EQ_Wed_new as
  select distinct *
  from EQ_NEW1
  where weekday(date)=4;
quit;

proc sql;
  create table Next5DayEQReturn as
  select distinct a.date, b.date as act_date, a.dateh, b._label_ as country, b.col1 as EQ_returns
  from EQ_new1 as a, EQ_new1 as b
  where a.date < b.date <= a.dateh;
quit;

data Next5DayEQReturn1;
	set Next5DayEQReturn;
	if weekday(date)=4;
run;

proc sort data=Next5DayEQReturn1; by DATE Country ; run;


proc sql;
  create table Next5DayReturn_EQ as
  select distinct country, date, dateh, sum(EQ_returns) as Log5DayRet
  from Next5DayEQReturn1
  group by date, dateh,country;
quit;

DATA Next5DayReturn_EQ;
	SET Next5DayReturn_EQ;
	dom=country;
	if country="United States" then dom='USA';
    if country="United Kingdom" then dom='UKD';
	if country="United Arab Emirates" then dom='UAE';
	id=catt(date,substr(dom,1,3));
run;

/******Forex******/
data FX_NEW1;
  set FX_NEW1;
  dateh = intnx("day",date,7);
  format dateh date9.;
run;
proc sql;
  create table FX_Wed_new as
  select distinct *
  from FX_NEW1
  where weekday(date)=4;
quit;

proc sql;
  create table Next5DayFXReturn as
  select distinct a.date, b.date as act_date, a.dateh, b._label_ as country, b.col1 as FX_returns
  from FX_new1 as a, FX_new1 as b
  where a.date < b.date <= a.dateh;
quit;

data Next5DayFXReturn1;
	set Next5DayFXReturn;
	if weekday(date)=4;
run;

proc sort data=Next5DayFXReturn1; by DATE Country ; run;


proc sql;
  create table Next5DayReturn_FX as
  select distinct country, date, dateh, sum(FX_returns) as Log5DayRet_FX
  from Next5DayFXReturn1
  group by date, dateh,country;
quit;

DATA Next5DayReturn_FX;
	SET Next5DayReturn_FX;
	dom=country;
	if country="United States" then dom='USA';
    if country="United Kingdom" then dom='UKD';
	if country="United Arab Emirates" then dom='UAE';
	id=catt(date,substr(dom,1,3));
run;

/******Fixed Income******/

***IDENTIFY SIMILAR RETs IN HISTORICAL DATA
HISTORICAL DATA = DATA UNTIL ONE WEEK BEFORE;
data FI_NEW1;
  set FI_NEW1;
  dateh = intnx("day",date,7);
  format dateh date9.;
run;
proc sql;
  create table FI_Wed_new as
  select distinct *
  from FI_NEW1
  where weekday(date)=4;
quit;


data Next5DayFIReturn1;
	set FI_NEW1;
	if weekday(date)=4;
run;

proc sort data=Next5DayFIReturn1; by _LABEL_ DATE ; run;

DATA Next5DayReturn_FI;
	SET Next5DayFIReturn1;
	yd_change=col1-lag(col1);
run;

DATA Next5DayReturn_FI;
	SET Next5DayReturn_FI;
	by _label_;
	if first._label_=1 then yd_change=.;
run;

DATA Next5DayReturn_FI;
	SET Next5DayReturn_FI;
	country=_label_;
	FI_yield=col1;
	drop _label_ col1 _name_ dateh;
run;

DATA Next5DayReturn_FI;
	SET Next5DayReturn_FI;
	dom=country;
	if country="United States" then dom='USA';
    if country="United Kingdom" then dom='UKD';
	if country="United Arab Emirates" then dom='UAE';
	id=catt(date,substr(dom,1,3));
run;

/** Merging with final table **/
proc sort data=Next5DayReturn_EQ out=Next5DayReturn_EQ1; by id; run;
proc sort data=Next5DayReturn_FX out=Next5DayReturn_FX1; by id ; run;
proc sort data=Next5DayReturn_FI out=Next5DayReturn_FI1; by id ; run;

data final;
	merge Next5DayReturn_EQ1 Next5DayReturn_FI1 Next5DayReturn_FX1;
	by id;
run;

proc sort data=final; by DATE country; run;

data final;
	set final;
	EQ_ret=Log5DayRet;
	FX_ret=Log5DayRet_FX;
	drop Log5DayRet Log5DayRet_FX id dom;
run;

proc sort data=final; by country DATE; run;

/**linking political data ***/



