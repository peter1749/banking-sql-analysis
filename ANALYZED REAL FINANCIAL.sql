-- PART 1: BANK REVENUE MODEL
-- Q1: TOTAL BANK REVENUE
SELECT SUM(COALESCE(loan_amount,0) * COALESCE(interest_rate,0)) + SUM(COALESCE(fee_amount,0)) AS total_revenue
FROM real_financial;
-- Q2: REVENUE BY BRANCH, PRODUCT TYPE, REGION
-- REVENUE BY BRANCH
SELECT branch, 
SUM(COALESCE(loan_amount,0) * COALESCE(interest_rate,0)) + SUM(COALESCE(fee_amount,0)) AS revenue
FROM real_financial
GROUP BY branch;
-- REVENUE BY PRODUCT TYPE
SELECT product_type, 
SUM(COALESCE (interest_rate,0) * COALESCE (loan_amount,0)) + SUM(COALESCE(fee_amount,0)) AS revenue
FROM real_financial
GROUP BY product_type;
-- REVENUE BY REGION
SELECT region, 
SUM(COALESCE (interest_rate,0) * COALESCE (loan_amount,0)) + SUM(COALESCE(fee_amount,0)) AS revenue
FROM real_financial
GROUP BY region;
-- PART 2: LOAN QUALITY AND PERFORMANCE
-- Q3: NON-PERFORMING LOAN
SELECT customer_id, customer_name, loan_class
FROM (
SELECT customer_id, customer_name,  
CASE
WHEN days_past_due > 90 OR default_flag = 1 THEN 'Non-performing Loan' ELSE 'Performing Loan'END AS Loan_class
FROM real_financial
)T
GROUP BY customer_id, customer_name, loan_class
HAVING loan_class = 'Non-performing Loan';
-- Q4: NPL RATIO
SELECT COUNT(*) AS total_loans, 
COUNT(CASE WHEN loan_class = 'Non-performing Loan' THEN 1 END) AS total_NPL,
ROUND(
COUNT(CASE WHEN loan_class = 'Non-performing Loan' THEN 1 END) 
/
COUNT(*), 2) AS NPL_RATIO
FROM(
SELECT Loan_amount, 
CASE
WHEN days_past_due > 90 OR default_flag = 1 THEN 'Non-performing Loan' ELSE 'Performing Loan'END AS Loan_class
FROM real_financial
)T;
-- Q5: LOAN RECOVERY RATE
SELECT 
ROUND(
SUM(COALESCE(repayment_amount,0))
/
SUM(COALESCE(loan_amount,0)),2) AS Loan_recovery_rate
FROM real_financial;

-- PART 3: CUSTOMER RISK SCORING
-- Q6: DEBT TO INCOME RATIO
SELECT customer_id, customer_name, existing_debt, monthly_income,
ROUND(
existing_debt/monthly_income, 2) AS DTI_ratio
FROM real_financial;
-- Q7: RISK LEVEL
SELECT customer_id, customer_name, default_flag, DTI_ratio, employment_status,
CASE
WHEN default_flag = 1 OR DTI_ratio > 0.6 OR employment_status ='unemployed' THEN 'High risk'
WHEN DTI_ratio BETWEEN 0.3 AND 0.6 THEN 'Medium risk'
ELSE 'Low risk'
END AS risk_level
FROM(
SELECT customer_id, customer_name, default_flag,
ROUND( 
existing_debt/monthly_income,2) AS DTI_ratio, employment_status
FROM real_financial
)T;
-- PART 4: CUSTOMER PROFITABILITY
-- Q8: CUSTOMER PROFIT
SELECT customer_id, customer_name, 
ROUND(
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate, 0)) + SUM(COALESCE(fee_amount,0)),2) AS total_profit
FROM real_financial
GROUP BY customer_id, customer_name ;
-- Q9: TOP 5 CUSTOMER PROFIT BASED ON TOTAL PROFIT
SELECT customer_id, customer_name, 
ROUND(
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate, 0)) + SUM(fee_amount), 2) AS total_profit
FROM real_financial
GROUP BY customer_id, customer_name
ORDER BY total_profit DESC
LIMIT 5;

-- PART 5: CUSTOMER LIFETIME VALUE
-- Q10: CALCULATE CLV (TOTAL REVENUE GENERATED PER CUSTOMER)
SELECT customer_id, customer_name,
ROUND(
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate, 0)) + SUM(fee_amount), 2) AS CLV
FROM real_financial
GROUP BY customer_id, customer_name
ORDER BY CLV DESC;
-- Q11: SEGMENT CUSTOMERS
SELECT customer_id, customer_name, CLV,
CASE
 WHEN CLV > 1000000 THEN 'High value' 
 WHEN CLV BETWEEN 500000 AND 1000000 THEN 'Medium Value'
 WHEN CLV < 500000 THEN 'Low value'
END AS customers_segment
FROM(
SELECT customer_id, customer_name, 
ROUND(
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate, 0)) + SUM(fee_amount), 2) AS CLV
FROM real_financial
GROUP BY customer_id, customer_name
)T;

-- PART 6: BEHAVIOUR ANALYSIS
-- Q12: CALCULATE TOTAL DEPOSITS, WITHDRAWALS, AND NET CASH FLOW PER CUSTOMER
SELECT customer_id, customer_name, total_deposit,total_withdrawal, 
total_deposit - total_withdrawal AS net_cash_flow
FROM(
SELECT customer_id, customer_name,
SUM(CASE WHEN transaction_type ='Deposit' THEN COALESCE (amount,0) ELSE 0 END) AS Total_deposit,
SUM(CASE WHEN transaction_type ='Withdrawal' THEN COALESCE (amount,0) ELSE 0 END) AS Total_withdrawal
FROM real_financial
GROUP BY customer_id, customer_name
)T;
-- Q13: DETERMINE HIGH ACTIVITY CUSTOMERS (CUSTOMERS WITH MORE THAN 3 TRANSACTIONS)
SELECT customer_id, customer_name, COUNT(*) AS number_of_transaction
FROM real_financial
GROUP BY customer_id, customer_name
HAVING number_of_transaction >3;

-- PART 7: ADVANCED DECISION MODEL
-- Q14: LOAN APPROVAL CRITERION
SELECT customer_id,customer_name, loan_amount, 
ROUND(
(existing_debt * 1.0 / NULLIF(monthly_income,0)),2) AS dti,
CASE 
WHEN credit_score >= 750 AND default_flag = 0 AND (existing_debt * 1.0 / monthly_income) < 0.4
THEN 'APPROVED'
WHEN credit_score BETWEEN 650 AND 749 AND default_flag = 0 AND (existing_debt * 1.0 / monthly_income) < 0.6
THEN 'CONDITIONAL APPROVAL'
ELSE 'REJECTED'
END AS loan_decision
FROM real_financial;
-- PART 8: TIME AND TREND ANALYSIS
-- Q15: DETERMINE MONTHLY REVENUE, MONTHLY DEFAULT TREND, MONTHLY LOAN DISBURSEMENT
-- MONTHLY REVENUE
SELECT  month(transaction_date) AS month,  SUM(COALESCE(loan_amount,0) * COALESCE(interest_rate,0)) + SUM(COALESCE(fee_amount,0)) AS Total_revenue
FROM real_financial
GROUP BY month( transaction_date);
-- MONTHLY DEFAULT TREND
SELECT month(transaction_date) AS month, COUNT(*) AS monthly_default
FROM real_financial
where default_flag = 1
GROUP BY month(transaction_date);
-- MONTHLY LOAN DISBURSEMENT
SELECT month(transaction_date) AS month, count(CASE WHEN transaction_type = 'Disbursement' THEN 1 END) AS Disbursement
FROM real_financial
 GROUP BY month(transaction_date);
 -- PART 9: DEEP BUSINESS QUESTION 
 -- WHICH BRANCH HAS HIGHEST NPL
 SELECT branch,
COUNT(CASE WHEN days_past_due > 90 OR default_flag = 1 THEN 1 END) AS total_npl
FROM real_financial
GROUP BY branch
ORDER BY total_npl DESC
LIMIT 1;
-- WHICH REGION HAS THE HIGHEST DEFAULT RATE?
SELECT region,
ROUND(
COUNT(CASE WHEN default_flag = 1 THEN 1 END) * 1.0 
/ COUNT(*), 2) AS default_rate
FROM real_financial
GROUP BY region
ORDER BY default_rate DESC;
-- WHAT IS THE AVERAGE LOAN AMOUNT PER BRANCH?
SELECT branch, 
ROUND(
AVG(COALESCE(loan_amount,0)), 2) AS avg_loan
FROM real_financial
GROUP BY branch;
-- WHICH PRODUCT TYPE GENERATE THE HIGHEST REVENUE
SELECT product_type,
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate,0)) + SUM(COALESCE (fee_amount,0)) AS revenue
FROM real_financial
GROUP BY product_type
ORDER BY revenue DESC;
-- WHICH CUSTOMERS ARE HIGH RISK BUT HIGH VALUE?
SELECT customer_id, customer_name,
SUM(COALESCE(loan_amount,0) * COALESCE(interest_rate,0) 
+ COALESCE(fee_amount,0)) AS total_value,
CASE 
    WHEN default_flag = 1 OR days_past_due > 90 THEN 'High Risk'
    ELSE 'Low Risk'
END AS risk_level
FROM real_financial
GROUP BY customer_id, customer_name, default_flag, days_past_due
HAVING risk_level = 'High Risk'
ORDER BY total_value DESC;
-- WHAT IS THE AVERAGE LOAN AMOUNT PER BRANCH?
SELECT branch, 
ROUND(
AVG(COALESCE(loan_amount,0)),2) AS avg_loan
FROM real_financial
GROUP BY branch 
ORDER BY avg_loan DESC;
-- WHICH CUSTOMERS CONTRIBUTE MOST TO BANK REVENUE?
SELECT customer_id, customer_name,
ROUND(
SUM(COALESCE(loan_amount,0) * COALESCE(interest_rate,0) 
+ COALESCE(fee_amount,0)), 2)AS total_revenue
FROM real_financial
GROUP BY customer_id, customer_name
ORDER BY total_revenue DESC
LIMIT 5;
-- WHAT IS THE DEFAULT RATE BY EMPLOYMENT STATUS?
SELECT employment_status,
COUNT(CASE WHEN default_flag = 1 THEN 1 END) AS total_default,
COUNT(*) AS total_loan,
ROUND(
COUNT(CASE WHEN default_flag = 1 THEN 1 END) 
/
COUNT(*),2) AS default_rate
FROM real_financial
GROUP BY employment_status;
-- WHICH MONTH HAS THE HIGHEST LOAN DEFAULT?
SELECT MONTH(transaction_date) AS month, COUNT(CASE WHEN default_flag = 1 OR days_past_due > 90 THEN 1 END) AS loan_default
FROM real_financial
GROUP BY MONTH(transaction_date);
-- WHAT IS THE AVERAGE DTI PER RISK CATEGORY?
SELECT risk_category, dti_ratio
FROM(
SELECT 
CASE
WHEN default_flag= 1 OR days_past_due> 90 THEN 'High risk' 
ELSE 'Low risk' END AS risk_category,
ROUND(
AVG(existing_debt) / AVG(monthly_income ),2)AS dti_ratio
FROM real_financial
GROUP BY risk_category
)T;
-- TOP 5 MOST PROFITABLE BRANCH
SELECT branch,
SUM(COALESCE (loan_amount,0) * COALESCE (interest_rate,0)) + SUM( COALESCE (fee_amount, 0)) AS total_profit
FROM real_financial
GROUP BY branch
ORDER BY total_profit DESC
LIMIT 5;
