libname POL 'E:\Drive\Local Disk F\political leanings\Political leanings fin data\Political leanings Value Mom'; run;

*Import data;

PROC IMPORT OUT=POL.Aug23
            DATAFILE= "E:\Drive\Local Disk F\political leanings\Political leanings fin data\Political leanings Value Mom\Pol leanings value mom 2017-08-23.xlsx" 
            DBMS=EXCEL REPLACE;
sheet="Political_leanings";
GETNAMES=YES;
MIXED=NO;
SCANTEXT=YES;
USEDATE=YES;
SCANTIME=YES;
RUN;

data POL.Aug23;
	set POL.Aug23;
	if Country_code in ('GRC','HKG') then delete;
	HML_FF1=input(HML_FF,best12.);
	HML_Devil1=input(HML_Devil,best12.);
	Election_dummy=input(Election_dummy1,best12.);
	drop HML_FF HML_Devil Election_dummy1;
run;

proc sort data=pol.Aug23; by Country_code Date_End_of_month; run;

data pol.Aug23_1;
	set pol.Aug23;
	if Election_dummy=1;
	keep Country_code Date_End_of_month;
run;

data pol.Aug23_1;
	set pol.Aug23_1;
	by Country_code;
	if first.Country_code=1;
run;

**Merging pol.Aug23 & pol.Aug23_1;

proc sql;
	create table pol.Aug23 as
	select distinct a.*
	from pol.Aug23 as a, pol.Aug23_1 as b
	where a.Country_code=b.Country_code and a.Date_End_of_month>=b.Date_End_of_month;
quit;

proc sort data=pol.Aug23; by Country_code Date_End_of_month; run;

data pol.Aug23_1;
	set pol.Aug23;
	post_election_month+1;
	by Country_code;
	if Election_dummy=1 then post_election_month=0;
run;


/*If there are missing values in a column, it replaces them with last non-missing values */

DATA pol.Aug23A (DROP = filledX) ;
SET pol.Aug23_1;
RETAIN filledX ; /* keeps the last non-missing value in memory */
IF NOT MISSING(Leaning_transition) THEN filledX = Leaning_transition ; /* fills the new variable with non-missing value */
Leaning_transition = filledX ;
RUN ;

data pol.Aug23c;
	set pol.Aug23a;
	if Leaning_transition='Center_to_Center' then Leaning_transition_code='CC';
	if Leaning_transition='Center_to_Left' then Leaning_transition_code='CL';
	if Leaning_transition='Center_to_Right' then Leaning_transition_code='CR';
	if Leaning_transition='Left_to_Left' then Leaning_transition_code='LL';
	if Leaning_transition='Left_to_Right' then Leaning_transition_code='LR';
	if Leaning_transition='NoGovt_to_NoGovt' then Leaning_transition_code='NN';
	if Leaning_transition='Right_to_Center' then Leaning_transition_code='RC';
	if Leaning_transition='Right_to_Left' then Leaning_transition_code='RL';
	if Leaning_transition='Right_to_NoGovt' then Leaning_transition_code='RN';
	if Leaning_transition='Right_to_Right' then Leaning_transition_code='RR';
	keep Leaning_transition Leaning_transition_code;
run;

proc sort data=pol.Aug23c nodupkey;by Leaning_transition Leaning_transition_code; run;

proc sql;
	create table pol.Aug23a as
	select distinct a.*,b.Leaning_transition_code
	from pol.Aug23a as a left join pol.Aug23c as b
	on a.Leaning_transition=b.Leaning_transition;
quit;
/**/
/*proc sql;*/
/*	create table pol.Aug23b as*/
/*	select distinct a.*,b.Leaning_transition_code*/
/*	from pol.Aug23b as a left join pol.Aug23c as b*/
/*	on a.Leaning_transition=b.Leaning_transition;*/
/*quit;*/

data pol.Aug23a;
	set pol.Aug23a;
	if Leaning_transition_code in ('LL','RL','LR','RR');
run;

data pol.Aug23aL;
	set pol.Aug23a;
	if Leaning_transition_code in ('LL','RL');
run;
data pol.Aug23aR;
	set pol.Aug23a;
	if Leaning_transition_code in ('LR','RR');
run;

/**/
/*proc sort data=pol.Aug23ar nodupkey; by Date_End_of_month; run;*/
/*data pol.Aug23ar ;*/
/*	set pol.Aug23ar ;*/
/*	gap=intck('month',Date_End_of_month,lag(Date_End_of_month));*/
/*	keep Date_End_of_month gap;*/
/*run;*/


**transposing the factors from wide to long;
data pol.Aug23a1;
	set pol.Aug23a;
	nrow=_N_;
	keep Leaning_transition_code post_election_month HML_FF1 HML_Devil1 Momentum nrow;
run;

proc transpose data=pol.Aug23a1 out=pol.Aug23a2;
  by nrow;
  var HML_FF1 HML_Devil1 Momentum;
/*  id var1;*/
run;

**merging with original dataset;
proc sql;
	create table pol.Aug23a2 as
	select distinct b.Leaning_transition_code, b.post_election_month, a._NAME_ as Factor, a.col1 as Factor_value
	from pol.Aug23a2 as a right join pol.Aug23a1 as b
	on a.nrow=b.nrow;
quit;

**Descriptive stats;

***N_obs, Mean, T-stat;
proc sort data=pol.Aug23a2; by Leaning_transition_code post_election_month Factor; run;


proc means data=pol.Aug23a2 noprint;
  by Leaning_transition_code post_election_month Factor;
  var Factor_value;
  output out=pol.N_obs N=Factor_value;
quit;

proc means data=pol.Aug23a2 noprint;
  by Leaning_transition_code post_election_month Factor;
  var Factor_value;
  output out=pol.Mean mean=Factor_value;
quit;

proc means data=pol.Aug23a2 noprint;
  by Leaning_transition_code post_election_month Factor;
  var Factor_value;
  output out=pol.tstat t=Factor_value;
quit;


data pol.N_obs;
  set pol.N_obs;
  drop _Type_ _Freq_;
  Var=1;
  Stat='N_obs';
run;

data pol.Mean;
  set pol.Mean;
  drop _Type_ _Freq_;
  Var=2;
  Stat='Mean';
run;

data pol.tstat;
  set pol.tstat;
  drop _Type_ _Freq_;
  Var=3;
  Stat='T-Stat';
run;

data pol.TestStats;
  length Stat $ 10;
  set pol.N_obs pol.Mean pol.Tstat;
run;


proc sort data=pol.TestStats; by Leaning_transition_code post_election_month Stat; run;

proc transpose data=pol.TestStats out=pol.TestStats1;
  by Leaning_transition_code post_election_month Stat;
  var Factor_value;
  id Factor;
run;
proc sort data=pol.TestStats1; by Leaning_transition_code post_election_month Stat; run;

proc transpose data=pol.TestStats1 out=pol.TestStats2;
  by Leaning_transition_code post_election_month Stat;
  var HML_FF1 HML_Devil1 Momentum;
  id Stat;
run;

data pol.mean1;
  set pol.TestStats1;
  if Stat='Mean';
run;

data pol.N_obs1;
  set pol.TestStats1;
  if Stat='N_obs';
run;

data pol.tstat1;
  set pol.TestStats1;
  if Stat='T-Stat';
run;

proc sql;
	create table pol.final_descriptives as
	select distinct a.*,b.HML_FF1 as HML_FF1_nobs,b.HML_Devil1 as HML_Devil1_nobs,b.Momentum as Mom_nobs
/*	c.HML_FF1 as HML_FF1_tstat,c.HML_Devil1 as HML_Devil1_tstat,c.Momentum as Mom_tstat*/
	from  pol.mean1 as a left join pol.N_obs1 as b /*left join pol.tstat1 as c */
	on a.Leaning_transition_code=b.Leaning_transition_code and /*=c.Leaning_transition_code */
	a.post_election_month=b.post_election_month/*=c.post_election_month*/;
quit;

proc sql;
	create table pol.final_descriptives as
	select distinct a.*,c.HML_FF1 as HML_FF1_tstat,c.HML_Devil1 as HML_Devil1_tstat,c.Momentum as Mom_tstat
	from  pol.final_descriptives as a left join pol.tstat1 as c 
	on a.Leaning_transition_code=c.Leaning_transition_code and a.post_election_month=c.post_election_month;
quit;


***********************************
**pooled analysis;
***********************************

***N_obs, Mean, T-stat;

proc sort data=pol.Aug23a2; by post_election_month Factor; run;

proc means data=pol.Aug23a2 noprint;
  by post_election_month Factor;
  var Factor_value;
  output out=pol.N_obs N=Factor_value;
quit;

proc means data=pol.Aug23a2 noprint;
  by post_election_month Factor;
  var Factor_value;
  output out=pol.Mean mean=Factor_value;
quit;

proc means data=pol.Aug23a2 noprint;
  by post_election_month Factor;
  var Factor_value;
  output out=pol.tstat t=Factor_value;
quit;


data pol.N_obs;
  set pol.N_obs;
  drop _Type_ _Freq_;
  Var=1;
  Stat='N_obs';
run;

data pol.Mean;
  set pol.Mean;
  drop _Type_ _Freq_;
  Var=2;
  Stat='Mean';
run;

data pol.tstat;
  set pol.tstat;
  drop _Type_ _Freq_;
  Var=3;
  Stat='T-Stat';
run;

data pol.TestStats;
  length Stat $ 10;
  set pol.N_obs pol.Mean pol.Tstat;
run;

proc sort data=pol.TestStats; by post_election_month Stat; run;

proc transpose data=pol.TestStats out=pol.TestStats1;
  by post_election_month Stat;
  var Factor_value;
  id Factor;
run;


data pol.mean1;
  set pol.TestStats1;
  if Stat='Mean';
run;

data pol.N_obs1;
  set pol.TestStats1;
  if Stat='N_obs';
run;

data pol.tstat1;
  set pol.TestStats1;
  if Stat='T-Stat';
run;

proc sql;
	create table pol.final_descriptives1 as
	select distinct a.*,b.HML_FF1 as HML_FF1_nobs,b.HML_Devil1 as HML_Devil1_nobs,b.Momentum as Mom_nobs
	from  pol.mean1 as a left join pol.N_obs1 as b 
	on a.post_election_month=b.post_election_month;
quit;

proc sql;
	create table pol.final_descriptives1 as
	select distinct a.*,c.HML_FF1 as HML_FF1_tstat,c.HML_Devil1 as HML_Devil1_tstat,c.Momentum as Mom_tstat
	from  pol.final_descriptives1 as a left join pol.tstat1 as c 
	on a.post_election_month=c.post_election_month;
quit;



***********************************************************
*******      Momentum Trading Strategy *******************;

*(a)Equal-weighted for all the countries;

***N_obs, Mean, T-stat;

proc sort data=pol.Aug23aR; by Date_End_of_month; run;

proc means data=pol.Aug23aR noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.N_obs N=Momentum;
quit;

proc means data=pol.Aug23aR noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.Mean mean=Momentum;
quit;

proc means data=pol.Aug23aR noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.tstat t=Momentum;
quit;


data pol.N_obs;
  set pol.N_obs;
  drop _Type_ _Freq_;
  Var=1;
  Stat='N_obs';
run;

data pol.Mean;
  set pol.Mean;
  drop _Type_ _Freq_;
  Var=2;
  Stat='Mean';
run;

data pol.tstat;
  set pol.tstat;
  drop _Type_ _Freq_;
  Var=3;
  Stat='T-Stat';
run;

data pol.TestStats;
  length Stat $ 10;
  set pol.N_obs pol.Mean pol.Tstat;
run;

proc sort data=pol.TestStats; by Date_End_of_month Stat; run;

data pol.mean1;
  set pol.TestStats;
  if Stat='Mean';
run;

data pol.N_obs1;
  set pol.TestStats;
  if Stat='N_obs';
run;

data pol.tstat1;
  set pol.TestStats;
  if Stat='T-Stat';
run;

proc sql;
	create table pol.final_descriptives2 as
	select distinct a.*,b.Momentum as Nobs
	from  pol.mean1 as a left join pol.N_obs1 as b 
	on a.Date_End_of_month=b.Date_End_of_month;
quit;

proc sql;
	create table pol.final_descriptives2 as
	select distinct a.*,b.Momentum as Tstat
	from  pol.final_descriptives2 as a left join pol.Tstat1 as b 
	on a.Date_End_of_month=b.Date_End_of_month;
quit;


*(b)Equal-weighted conditional on elections;

**check if there was an election in that country in the past one year;

data pol.test;
	set pol.Aug23aR;
	past1yrdate=intnx('month',Date_End_of_month,-12);
	Election_dummy1=input(Election_dummy,best8.);
	format past1yrdate date9.;
run;


proc sql;
	create table pol.test as
	select distinct a.*,b.Date_End_of_month as middle_date,b.Election_dummy1 as ED
	from pol.test as a left join pol.test as b
	on a.Country_code=b.Country_code and a.past1yrDate<b.Date_End_of_month<a.Date_End_of_month
	order by a.Country_code, a.Date_End_of_month, b.Date_End_of_month, a.past1yrDate;
quit;

proc sql;
	create table pol.test as
	select distinct Country_code, Date_End_of_month, sum(input(ED,best12.)) as Election_held
	from pol.test 
	group by Country_code, Date_End_of_month;
quit;

**create dataset only where elections are held;

proc sql;
	create table pol.test1 as
	select distinct a.*,b.Election_held
	from pol.Aug23aR as a left join pol.test as b
	on a.Country_code=b.Country_code and a.Date_End_of_month=b.Date_End_of_month
	order by a.Country_code, a.Date_End_of_month;
quit;

data pol.test1;
  set pol.test1;
  if missing(Election_held)=0 and Election_held>0;
run;

***N_obs, Mean, T-stat;

proc sort data=pol.test1; by Date_End_of_month; run;

proc means data=pol.test1 noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.N_obs N=Momentum;
quit;

proc means data=pol.test1 noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.Mean mean=Momentum;
quit;

proc means data=pol.test1 noprint;
  by Date_End_of_month;
  var Momentum;
  output out=pol.tstat t=Momentum;
quit;


data pol.N_obs;
  set pol.N_obs;
  drop _Type_ _Freq_;
  Var=1;
  Stat='N_obs';
run;

data pol.Mean;
  set pol.Mean;
  drop _Type_ _Freq_;
  Var=2;
  Stat='Mean';
run;

data pol.tstat;
  set pol.tstat;
  drop _Type_ _Freq_;
  Var=3;
  Stat='T-Stat';
run;

data pol.TestStats;
  length Stat $ 10;
  set pol.N_obs pol.Mean pol.Tstat;
run;

proc sort data=pol.TestStats; by Date_End_of_month Stat; run;

data pol.mean1;
  set pol.TestStats;
  if Stat='Mean';
run;

data pol.N_obs1;
  set pol.TestStats;
  if Stat='N_obs';
run;

data pol.tstat1;
  set pol.TestStats;
  if Stat='T-Stat';
run;

proc sql;
	create table pol.final_descriptives2b as
	select distinct a.*,b.Momentum as Nobs
	from  pol.mean1 as a left join pol.N_obs1 as b 
	on a.Date_End_of_month=b.Date_End_of_month;
quit;

proc sql;
	create table pol.final_descriptives2b as
	select distinct a.*,b.Momentum as Tstat
	from  pol.final_descriptives2b as a left join pol.Tstat1 as b 
	on a.Date_End_of_month=b.Date_End_of_month;
quit;
