data  assign.ecommerce;
set _TEMP1.ECOMMERCE;
RUN;
proc contents data = assign.ecommerce;
run;
proc means data = assign.ecommerce mean median std;
var avg_order_value;
run;
/*Missing vaues*/
proc means data = assign.ecommerce NMISS;
run; 
proc print data =assign.ecommerce;
run;
/*imputation for avg_orders_value*/
proc sort data = assign.ecommerce;
by preferred_category;
run; 
proc stdize data=assign.ecommerce
            out=assign.ecommerce_imputed
            method=median
            reponly;     
   by preferred_category;
   var avg_order_value;
run;
/*imputation for email_open_rate*/ 
proc mi data=assign.ecommerce_imputed nimpute=1 out=assign.ecommerce_imputed_final;
   var loyalty_score churn_risk total_orders avg_order_value email_open_rate;
   monotone reg(email_open_rate = loyalty_score churn_risk total_orders avg_order_value);
run;
proc print data=assign.ecommerce_imputed_final; run;
proc means data=assign.ecommerce_imputed_final nmiss; run;
/*handle artificial outliers*/
data assign.ecommerce_final1;
   set assign.ecommerce_imputed_final;
   if email_open_rate < 0 then email_open_rate = 0; 
   if email_open_rate > 100 then email_open_rate = 100;
run;
/*outliers before imputation*/
proc univariate data= assign.ecommerce;
run;
/*outliers after imputation*/
proc univariate data= assign.ecommerce_imputed_final;
run;
/*  duplication*/
proc sort data=assign.ecommerce out=assign.ecom_nodup nodupkey dupout=assign.ecom_dups;
   by _all_; 
run;
proc sql;
   select count(*) as Nb_Duplications
   from assign.ecom_m_dups;
quit;
/*log transformation*/
data assign.ecommerce_final;
   set assign.ecommerce_final1;
   log_avg_order_value = log(avg_order_value);
run;
proc print data= assign.ecommerce_final;
run; 
/*statistical summary*/
proc means data =assign.ecommerce mean var std q1 median  q3 ;
run;

/*Creat new variable*/
data  assign.ecommerce;/*final dataset*/
    set assign.ecommerce_final;          
    length churn_level $20;  
run;

proc sql;
UPDATE assign.ecommerce
SET churn_level = CASE
    WHEN churn_risk < 0.3 THEN 'Low'
    WHEN churn_risk BETWEEN 0.3 AND 0.7 THEN 'Medium'
    ELSE 'High'
    end;
quit;

proc freq data = assign.ecom_m;
tables is_fraudulent is_fraudulent*country is_fraudulent*preferred_category churn_level churn_level*country;
run;
/*outliers*/
proc sort data= assign.ecommerce;
by is_fraudulent;
run;
proc boxplot data=assign.ecommerce; 
plot total_orders*is_fraudulent; 
plot log_avg_order_value*is_fraudulent;
plot last_purchase*is_fraudulent;
plot email_open_rate*is_fraudulent;
plot loyalty_score*is_fraudulent;
plot is_fraudulent*churn_risk;
run;
/* Graph for exploratory data analysis */
proc sgplot data=assign.ecom_m;
    histogram total_orders / group=churn_level transparency=0.5;
    density total_orders / type=kernel group=churn_level;
    xaxis label="Total Orders";
    yaxis label="Frequency";
    title "Distribution of Total Orders by Churn Level";
run;
proc sgplot data=assign.ecommerce;
    vbar churn_level / response=total_orders stat=sum datalabel;
    xaxis label="Churn Level";
    yaxis label="Total Orders";
    title "Total Orders by Churn Level";
run;
proc sgplot data=assign.ecommerce;
    histogram log_avg_order_value / group=churn_level transparency=0.5;
    density log_avg_order_value / type=kernel group=churn_level;
    xaxis label="og_avg_order_value";
    yaxis label="Frequency";
    title "Distribution of average order value by Churn Level";
run;
proc sgscatter data=assign.ecommerce; 
plot churn_risk*loyalty_score; 
run;
proc sgscatter data=assign.ecommerce; 
plot total_orders*log_avg_order_value;
run;
proc sgplot data=assign.ecommerce; 
vbar preferred_category/ response=avg_order_value stat=sum datalabel;
run;
proc sgscatter data=assign.ecommerce; 
plot loyalty_score*total_orders;
run;
proc sgscatter data=assign.ecommerce; 
plot loyalty_score*log_avg_order_value;
run; 
proc sgplot data=assign.ecommerce;
 density email_open_rate / type=kernel group=churn_level;
histogram email_open_rate/ group =churn_level transparency=0.5;
 run;
