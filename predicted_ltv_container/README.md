# README

## Requirments

This code is prepared to run on ECS instances. You can find the ECS instance definition on this same directory.
In order to make it work you have to provide the following ENV variables

```
DB_USER = user to connect to the database
DB_PASS = authorized user pass
DB_HOST = database host
DB_PORT = database port
DB_NAME = database name
DESTINATION_TABLE = table with the required structure to dump the information generated 
					by this file (it should exist before running the script). 
BUCKET_NAME = s3 bucket name were CSV produced will be stored
OUTPUT_CSV_FILENAME = filename for the CSV (without .csv extension)
```

SQL for current table structure
```
CREATE TABLE IF NOT EXISTS csv_imports.predicted_ltv
(
	user_id INTEGER 
	,"first" DATE
	,expected_txn REAL
	,avg_sales_per_txn DOUBLE PRECISION
	,expected_12mo_spend DOUBLE PRECISION
)
```
