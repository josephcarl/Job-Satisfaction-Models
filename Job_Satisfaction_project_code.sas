*create dataset from Big NLSY Panel on desktop;
libname class "C:\\Users\carlx017\Desktop";
run;

data nlsy;
set class.big_nlsy_step2;
run;

*or;
data nlsy;
set "/folders/myfolders/big_nlsy_step2";
run;

*Summary of people who answered Job Satisfaction in 2008;
proc freq data=nlsy;
tables T1427900;
run;

****************************
Data Cleaning
****************************

*variables needed: job satisfaciton, education, work experience, income, #weeks worked/yr
gender, race, married, union status, 
workplace benefits (health ins, life ins, dental, pd mat/paternity leave, retirement,
flexible hours/schedule, profit sharing, training/educ opportunities, company provided child care),
# pd sick/vacation days (create # sick days), # vacation days;

*create dataset "jobsat08", includes only responses where people answered
job satisfaction in 2008;
data jobsat08;
set nlsy;
if T1427900=. Then delete;
run;

*rename T1427900 as "jobsat_binary", collapse to binary variable,
jobsat_binary: 1=satisfied, 0=unsatisfied;
data jobsat08;
set jobsat08;
if (T1427900 = 1) or (T1427900 = 2) then
jobsat_binary = 1;
else if (T1427900 = 3) or (T1427900=4) then
jobsat_binary=0;
else if T1427900=. then jobsat_binary=.;
run;

proc freq data= jobsat08;
tables jobsat_binary;
run;

*rename education into dummy variables (exclude "did not graduate hs")
HSGrad (no college): educ = 12, 
College (but didn't graduate): 13 le educ lt 16, 
CollegeGrad: educ ge 16
T1214300 = yrs educ in 2008;

proc freq data= jobsat08;
tables T1214300;
run;

*Years of education as of 2008 (T1214300);
data jobsat08;
set jobsat08;
if (T1214300 = 95) or (T1214300=.) then educ=.;
else educ = T1214300;
run;

proc freq data= jobsat08;
tables educ;
run;

*create education dummies to separate education levels:
did not finish high school (omitted), graduated hs but no college (hsgrad),
some college but didn't graduate (somecoll) and graduated college (collgrad);
data jobsat08;
set jobsat08;
if educ = 12 then hsgrad=1;
else hsgrad=0;
if (educ gt 12) and (educ lt 16) then somecoll=1;
else somecoll=0;
if educ ge 16 then collgrad=1;
else collgrad=0;
run;


*Work experience (Years)
*use Moodle example to sum up previous years' weeks worked to get estimate of
total work experience. When the sample switches to a biennial survey instead of
annual, I double "weeks worked" to estimate the total amount of work completed
in those two years. it will not be a perfect estimate but should hopefully be close.
Years of work experience in 2008 is then calculated by dividing total weeks worked
by 52;

data jobsat08;
set jobsat08;
workexp79 = weeksworked78 ;
workexp90= sum(workexp79, wkswk80,wkswk81,wkswk82,wkswk83,wkswk84,
wkswk85,wkswk86,wkswk87,wkswk88,wkswk89,wkswk90);
workexp92= sum(workexp90,wkswk91, wkswk92 ); 
workexp94= sum(workexp92, (2*wkswk94));
workexp96= sum(workexp94, (2*wkswk96));
workexp98= sum(workexp96, (2*wkswk98)); 
workexp2000= sum(workexp98, (2*wkswk2000));
workexp2002= sum(workexp2000, (2*wkswk2002));
workexp2004= sum(workexp2002, (2*wkswk2004));
workexp2006= sum(workexp2004, (2*wkswk2006));
workexp2008= sum(workexp2006, (2*wkswk2008));
exper08 = workexp2008/52;
run;

*exper08 values are truncated to the integer year;
data jobsat08;
set jobsat08;
exper = int(exper08);
run;

proc freq data=jobsat08;
tables exper;
run;
*exper has no missing values



*Income (T2209100) is hourly wage in cents
create hrwage for wage in dollars
if wage is missing, hrwage=0;
data jobsat08;
set jobsat08;
rename
T2209100 = wagecents;
run;

data jobsat08;
set jobsat08;
if wagecents=. then hrwage=0;
else hrwage = wagecents/100;
run;

proc means data=jobsat08;
var hrwage;
run;

data jobsat08;
set jobsat08;
if hrwage ne 0 then logwage = log(hrwage);
else logwage=.;
run;

proc means data=jobsat08;
var logwage;
run;


*Weeks worked in 2008 (wkswk2008);
proc freq data= jobsat08;
tables wkswk2008;
run;

*Hours per week worked (T1281800), rename to hrsperweek;
data jobsat08;
set jobsat08;
rename T1281800 = hrsperweek;
run;

proc freq data=jobsat08;
tables hrsperweek;
run;

*convert gender (gender79) to "Female" (1 if female, 0 if male);
*we can use gender79 since this variable has no missing values;
proc freq data= jobsat08;
tables gender79;
where T1427900 ne .;
run;

data jobsat08;
set jobsat08;
if gender79=2 then female=1;
else female=0;
run;

*marital status in 2008 (T2210500), if married then married08=1, otherwise married08=0;
data jobsat08;
set jobsat08;
if T2210500=1 then married08=1;
else if T2210500=. then married08=.;
else married08=0;
run;

proc freq data=jobsat08;
tables married08;
run;

*Union status in 2008 (T1427400): if in a union, union08=1, otherwise union08=0
this assumes that people who did not answer this question are not union members;
data jobsat08;
set jobsat08;
if T1427400=1 then union08=1;
else union08=0;
run;

*create race variables for Black, Hispanic (includes Cuban, Chicano, Mexican, Mexican-American,
Puerto Rican, Other Hispanic, Other Spanish),
these are the two non-white categories large enough to be useful, so these are the two race/ethnicity 
variables I will use in my analysis (omitted category: all non-Black, non-Hispanic people, mostly white);
data jobsat08;
set jobsat08;
if race1 = 1 then Black=1;
else Black=0;
if (race1=15) or (race1=16) or (race1=17) or (race1=18) or (race1=19) or (race1=20) or (race1=21) then Hispanic=1;
else Hispanic=0;
run;


*Workplace benefits: Health Insurance (T1392800), Life Insurance (T1392801),
Dental Benefits (T1392802), Protected Maternity/Paternity Leave (T1392803),
Retirement Plan (T1392804), Flexible Hours/Schedule (T1392805), 
Profit Sharing (T1392806), Training/Education Opportunities incl tuition reimbursement (T1392807),
Company Provided Child Care (T1392808) are already properly coded as binary variables
where "yes"=1 and "no"=0.
These variables simply need to be renamed;
data jobsat08;
set jobsat08;
rename
T1392800 = healthins
T1392801 = lifeins
T1392802 = dental
T1392803 = maternityleave
T1392804 = retirement
T1392805 = flexhours
T1392806 = profitshare
T1392807 = training_educ_tuition
T1392808 = childcare;
run;

*Workplace benefits: # Sick/Vacation days per year combined (T1393800) only has
~200 responses, so I am excluding it from my analysis for now.
# Vacation Days per year (T1394200) has >5000 responses, so I will keep
that in this analysis, rename it to "vacationdays";
data jobsat08;
set jobsat08;
rename
T1394200 = vacationdays;
run;

*********
Quick Aside to make variable for ordered model
*********

*create ordered model to reflect difference between dissatisfied with job (0),
satisfied with job (1), and very satisfied with job (2).
I'm interested in seeing what factors explain the difference between being
"satisfied" and "very satisfied" with one's job;

data jobsat08;
set jobsat08;
if T1427900 = 1 then jobsat_ordered=2;
else if T1427900 = 2 then jobsat_ordered=1;
else if (T1427900 = 3) or (T1427900=4) then jobsat_ordered=0;
run;

proc freq data=jobsat08;
tables jobsat_ordered;
run;
*jobsat_ordered has no missing values because missing responses already deleted;


*Save jobsat08 with newly made variables as a permanent dataset
so I don't have to recreate it every time I open this program;
data class.jobsat08;
set jobsat08;
run;


*******
Binary Models
*******

*Run PROC QLIM on model to estimate binary logit and binary probit models;

*Linear Probability model;
proc reg data=class.jobsat08;
model jobsat_binary = educ exper hrwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
title "Linear Probability Model";
run;
*Binary logit model;
proc qlim data=class.jobsat08;
model jobsat_binary = educ exper hrwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete(d=logit);
output out=margest_bin1 marginal;
title "Binary Logit Model";
run;
*avg marginal effect (mean of individual marginal effects for each observation;
proc means data=margest_bin1 n mean;
var Meff:;
run;

*for comparison: another binary logit model, but using logwage;
proc qlim data=class.jobsat08;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete(d=logit);
output out=margest_bin3 marginal;
title "Binary Logit Model with Logwage";
run;
*avg marginal effect (mean of individual marginal effects for each observation;
proc means data=margest_bin3 n mean;
var Meff:;
run;

*another logit model for comparison: binary logit with logwage and education dummies
instead of continuous educ variable;
proc qlim data=class.jobsat08;
model jobsat_binary = hsgrad somecoll collgrad exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete(d=logit);
output out=margest_bin4 marginal;
title "Binary Logit Model with Logwage and Educ Dummies";
run;
*avg marginal effect (mean of individual marginal effects for each observation;
proc means data=margest_bin4 n mean;
var Meff:;
run;


*Binary probit model;
proc qlim data=class.jobsat08;
model jobsat_binary = educ exper hrwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete;
output out=margest_bin2 marginal;
title "Binary Probit Model";
run;
*avg marginal effect;
proc means data=margest_bin2 n mean;
var Meff:;
run;

*for comparison: binary probit using logwage;
proc qlim data=class.jobsat08;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete;
output out=margest_bin5 marginal;
title "Binary Probit Model with Logwage";
run;
*avg marginal effect;
proc means data=margest_bin5 n mean;
var Meff:;
run;

*one more for comparison: binary probit with logwage & educ dummies;
proc qlim data=class.jobsat08;
model jobsat_binary = hsgrad somecoll collgrad exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays / discrete;
output out=margest_bin6 marginal;
title "Binary Probit Model with Logwage and Educ Dummies";
run;
*avg marginal effect;
proc means data=margest_bin6 n mean;
var Meff:;
run;

*marginal effects for binary variables: Difference in Probability for 0 and 1
Using the binary logit model with logwage
Discrete variables: female, married08, union08, Black, Hispanic, healthins,
lifeins, dental, maternityleave, retirement, flexhours, profitshare, training_educ_tuition,
childcare;
*create dataset for calculation;
data probdiff;
set class.jobsat08;
run;

*binary logit model with jobsat_binary=1 (using proc logistic);
proc logistic data=probdiff descending;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
run;

*calculate means of all explanatory variables and output to dataset;
proc means data=probdiff;
var educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
output out=means mean=;
run;

*create datasets from the "means" dataset that include extra observations with a 
missing dependent variable and the discrete explanatory variable set to 0 or 1.
female;
data margeff1;
set means;
jobsat_binary=.;
female=0;
run;
data margeff2;
set means;
jobsat_binary=.;
female=1;
run;
*married08;
data margeff3;
set means;
jobsat_binary=.;
married08=0;
run;
data margeff4;
set means;
jobsat_binary=.;
married08=1;
run;
*union08;
data margeff5;
set means;
jobsat_binary=.;
union08=0;
run;
data margeff6;
set means;
jobsat_binary=.;
union08=1;
run;
*Black;
data margeff7;
set means;
jobsat_binary=.;
Black=0;
run;
data margeff8;
set means;
jobsat_binary=.;
Black=1;
run;
*Hispanic;
data margeff9;
set means;
jobsat_binary=.;
Hispanic=0;
run;
data margeff10;
set means;
jobsat_binary=.;
Hispanic=1;
run;
*healthins;
data margeff11;
set means;
jobsat_binary=.;
healthins=0;
run;
data margeff12;
set means;
jobsat_binary=.;
healthins=1;
run;
*lifeins;
data margeff13;
set means;
jobsat_binary=.;
lifeins=0;
run;
data margeff14;
set means;
jobsat_binary=.;
lifeins=1;
run;
*dental;
data margeff15;
set means;
jobsat_binary=.;
dental=0;
run;
data margeff16;
set means;
jobsat_binary=.;
dental=1;
run;
*maternityleave;
data margeff17;
set means;
jobsat_binary=.;
maternityleave=0;
run;
data margeff18;
set means;
jobsat_binary=.;
maternityleave=1;
run;
*retirement;
data margeff19;
set means;
jobsat_binary=.;
retirement=0;
run;
data margeff20;
set means;
jobsat_binary=.;
retirement=1;
run;
*flexhours;
data margeff21;
set means;
jobsat_binary=.;
flexhours=0;
run;
data margeff22;
set means;
jobsat_binary=.;
flexhours=1;
run;
*profitshare;
data margeff23;
set means;
jobsat_binary=.;
profitshare=0;
run;
data margeff24;
set means;
jobsat_binary=.;
profitshare=1;
run;
*training_educ_tuition;
data margeff25;
set means;
jobsat_binary=.;
training_educ_tuition=0;
run;
data margeff26;
set means;
jobsat_binary=.;
training_educ_tuition=1;
run;
*childcare;
data margeff27;
set means;
jobsat_binary=.;
childcare=0;
run;
data margeff28;
set means;
jobsat_binary=.;
childcare=1;
run;

*combine these datasets to estimate the model and generate predicted values for all observations;
data margeff_combined;
set margeff1 margeff2 margeff3 margeff4 margeff5 margeff6 margeff7 margeff8 margeff9 margeff10
margeff11 margeff12 margeff13 margeff14 margeff15 margeff16 margeff17 margeff18 margeff19 margeff20
margeff21 margeff22 margeff23 margeff24 margeff25 margeff26 margeff27 margeff28 probdiff;
run;

*estimate the model using the combined dataset,
observations with missing dependent variable are excluded;
proc reg data=margeff_combined;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
output out=regresults p=predpov;
run;

*what is the difference in predicted probability for being satisfied with one's job for someone 
who is in a certain demographic category (female, black, hispanic, union) or receives benefits from his/her 
employer and whose other characteristics are set at mean values?;
proc print data=regresults;
where jobsat_binary=.;
var female married08 union08 Black Hispanic healthins lifeins dental maternityleave retirement 
flexhours profitshare training_educ_tuition childcare predpov;
run;

*determine percent correct for binary logit model: first using 50% as cutoff,
then using 8% as cutoff (the mean value for job satisfaction since there were so few dissatistfied people;
proc logistic data=class.jobsat08;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
output out=binlogpred pred=binlogitpred;
run;

data predictions;
set binlogpred;
if binlogitpred ne . then do;
if binlogitpred ge .5 then pred_sat=1;
else if binlogitpred lt 0.5 then pred_sat=0;
end;
diff50 = jobsat_binary - pred_sat;
if binlogitpred ne . then do;
if binlogitpred ge .08 then pred_sat08=1;
else if binlogitpred lt 0.08 then pred_sat08=0;
end;
diff08 = jobsat_binary - pred_sat08;
run;

proc freq data=predictions;
tables diff50 jobsat_binary*pred_sat diff08 jobsat_binary*pred_sat08;
run;
*view tables to see predicted probabilities;


*Marginal effects for the probit model
*Same process as above to get means of data and create margeff_combined

*estimate the model using proc probit and output predicted probabilities;
proc sort data=margeff_combined;
by descending jobsat_binary;
run;
proc probit data=margeff_combined order=data;
class jobsat_binary;
model jobsat_binary = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
output out=probitpred p=probitpred;
run;
proc print data=probitpred;
where jobsat_binary=.;
var jobsat_binary educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays probitpred;
run;


******************************
Ordered Model, 2008 data
******************************

*ordered logit model;
proc logistic data=jobsat08;
model jobsat_ordered = educ exper logwage wkswk2008 hrsperweek female married08 union08 Black Hispanic 
healthins lifeins dental maternityleave retirement flexhours profitshare training_educ_tuition childcare vacationdays;
run;

