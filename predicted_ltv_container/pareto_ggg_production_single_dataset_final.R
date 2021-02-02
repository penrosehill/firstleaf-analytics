#' import relevant packages
library(BTYDplus)
library(BTYD)
library(data.table)
library(dplyr)
library("aws.s3")
library(RPostgres)
library(redshiftTools)

#' set up connection to redshift
print ("setting up connection to redshift")
dbuser <- Sys.getenv('DB_USER') 
dbpass <- Sys.getenv('DB_PASS')
dbhost <- Sys.getenv('DB_HOST')
dbport <- Sys.getenv('DB_PORT')
dbname <- Sys.getenv('DB_NAME')
bucket_name <- Sys.getenv('BUCKET_NAME')
dest_table <- Sys.getenv('DESTINATION_TABLE')

conn <- dbConnect(RPostgres::Postgres(), 
                  dbname=dbname,
                  host=dbhost,
                  port=dbport,
                  user=dbuser, 
                  password=dbpass,
                  sslmode='require')

#' reading data from redshift: analytics_data_science.ltv_orders. This pulls all active users.
print ("reading data from redshift: analytics_data_science.ltv_orders")
df <- dbGetQuery(conn, "SELECT * FROM analytics_data_science.ltv_orders WHERE active_subscriber = TRUE")
# df <- dbReadTable(conn, "analytics_data_science.ltv_orders")

#' select only the key columns for model
orders <- select(df, "user_id", "order_created_date", "order_total")

#' convert datetime stamps to date 
orders$order_created_date <- as.Date(orders$order_created_date, "%Y-%m-%d")

library(plyr)
#' rename columns so usage of embedded package functions don't break
orders <- rename(orders, c("user_id"="cust", "order_created_date"="date", "order_total"="sales"))

#' Convert from event log to customer-by-sufficient-statistic summary.
#' Split into calibration (training), and holdout (testing) period. 
#' T.cal is for the cut off between calibration and holdout data. We'll use all data for training.
print ("creating CBS file")
max_date <- max(orders$date)
cbs <- elog2cbs(orders, T.cal = max_date)
head (cbs)

#' Draw Pareto/GGG parameters and report median estimates. Note, that we only
#' use a relatively short MCMC chain for quicker run times
print ("running MCMC paramater draws")
pggg.draws <- pggg.mcmc.DrawParameters(cal.cbs = cbs, mcmc = 500, burnin = 500, chains = 2, thin = 50, trace = 50)

#' draw future transaction
#' T.star indicates the total timeperiod of holdout data in "# of weeks"
#' we'll run this for forward looking 52-week (1yr LTV) time period
print ("running future transaction draws")
xstar.pggg.draws <- mcmc.DrawFutureTransactions(cbs, pggg.draws, T.star = 52, sample_size = 1000)

#' calculate mean over future transaction draws for each customer
print ("doing final calculations")
cbs$expected_txn <- apply(xstar.pggg.draws, 2, mean)

#' drop any blank customers
cbs <- cbs[!is.na(cbs$cust),]
cbs <- cbs[!(cbs$cust == ""), ]

#' calculate avg sales per txn and drop nulls
cbs$avg_sales_per_txn <- (cbs$sales.x/cbs$x)
cbs <- cbs[!is.na(cbs$avg_sales_per_txn),]
cbs <- cbs[!(cbs$avg_sales_per_txn == ""), ]

#' calculate total 1y LTV
cbs$expected_12mo_spend <- (cbs$avg_sales_per_txn*cbs$expected_txn)

#' output the final results into csv file and send back to S3
output <- subset(cbs, select=c("cust","first", "expected_txn", "avg_sales_per_txn", "expected_12mo_spend"))
output <- rename(output, c("cust"="user_id"))

#' write out the final dataset to csv
print ("writing out the final output")
output_file_name <- sprintf("pareto_ggg_output_%s.csv", max_date)
output_main_file <- "pareto_ggg_output.csv"
write.csv(output, output_main_file, row.names = FALSE)

print ("uploading file to s3")
put_object(file = output_main_file, object = sprintf('final-ltv-files/archive/%s',output_file_name), bucket = bucket_name)
put_object(file = output_main_file, object = sprintf('final-ltv-files/%s',output_main_file), bucket = bucket_name)

sprintf ("dump information into %s table", dest_table)
rs_replace_table(output, dbcon = conn, table_name = dest_table, bucket = bucket_name, split_files = 4, region = 'us-east-1')
