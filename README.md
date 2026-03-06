# Stocks Serverless Pipeline

A fully automated serverless data pipeline that tracks 6 tech stocks daily, identifies the top mover by percentage change, stores the result in DynamoDB, and displays the history on a public website. The entire system runs on AWS and requires zero manual intervention once deployed.

**Live Demo:** http://stocks-pipeline-frontend.s3-website-us-west-2.amazonaws.com

**API Endpoint:** https://fn7s5qprh4.execute-api.us-west-2.amazonaws.com/prod/movers

---

## How It Works

### Ingestion Lambda

Runs automatically every day at 4:30pm PST via EventBridge cron. For each ticker in the watchlist it:

1. Fetches the previous trading day's open and close price from the Massive API
2. Calculates percentage change using `((close - open) / open) * 100`
3. Compares all results by absolute value to find the biggest mover
4. Writes one record to DynamoDB with the actual trading date from the API timestamp

### API Lambda

Triggered by `GET /movers` requests from API Gateway. It:

1. Queries DynamoDB for the last 7 calendar dates
2. Returns only dates that have data (skips weekends and holidays)
3. Returns a JSON array sorted most recent first

---

## Architecture

The system has two completely separate data flows:

**Write Flow** (automated, runs daily at 4:30pm PST):
```
EventBridge Cron → Ingestion Lambda → Massive API → DynamoDB
```

**Read Flow** (on demand, triggered by user visiting website):
```
Browser → S3 Frontend → API Gateway → API Lambda → DynamoDB
```

### AWS Services Used

| Service | Purpose |
|---|---|
| AWS Lambda | Two functions: one for ingestion, one for the API |
| Amazon EventBridge | Cron schedule triggering daily ingestion at 4:30pm PST |
| Amazon DynamoDB | Stores one record per trading day (date, ticker, pct_change, close_price) |
| Amazon API Gateway | REST API exposing GET /movers endpoint to the frontend |
| Amazon S3 | Hosts the static frontend website |
| AWS Secrets Manager | Securely stores the Massive API key at runtime |
| AWS IAM | Least-privilege roles for each Lambda function |
| Amazon CloudWatch | Automatic logging for all Lambda executions |

---

## Prerequisites

Before deploying, ensure you have the following installed and configured:

- **AWS CLI** v2+ — configured with `aws configure`
- **Terraform** v1.0+ — [Install Terraform](https://developer.hashicorp.com/terraform/install)
- **Python** 3.11+
- **A Massive API key** — sign up for free at [massive.com](https://massive.com) (no credit card required)
- An AWS account with sufficient permissions to create Lambda, DynamoDB, API Gateway, S3, IAM, EventBridge, and Secrets Manager resources

---

## Deployment

### Step 1 — Clone the Repository

```bash
git clone https://github.com/michael9009m/Stocks-Serverless-Pipeline.git
cd Stocks-Serverless-Pipeline
```

### Step 2 — Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-west-2
# Default output format: json
```

### Step 3 — Create Terraform State Bucket

Terraform remote state is stored in S3. Create the bucket before initializing:

```bash
aws s3 mb s3://stocks-pipeline-tfstate-michael --region us-west-2
```

### Step 4 — Store the Massive API Key in Secrets Manager

```bash
aws secretsmanager create-secret \
  --name "stocks-pipeline/massive-api-key" \
  --secret-string '{"api_key":"YOUR_MASSIVE_API_KEY"}' \
  --region us-west-2
```

Replace `YOUR_MASSIVE_API_KEY` with your actual key from the Massive dashboard.

### Step 5 — Build Lambda Zip Files

The Lambda functions require dependencies to be packaged with the code:

```bash
# Ingestion Lambda
cd lambdas/ingestion
pip install -r requirements.txt -t . --break-system-packages
zip -r ingestion.zip .
cd ../..

# API Lambda
cd lambdas/api
zip -r api.zip .
cd ../..
```

### Step 6 — Deploy Infrastructure with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. This deploys all 27 AWS resources.

After apply completes, Terraform will output:

```
api_url = "https://YOUR_API_ID.execute-api.us-west-2.amazonaws.com/prod/movers"
dynamodb_table_name = "stock-movers"
website_url = "stocks-pipeline-frontend.s3-website-us-west-2.amazonaws.com"
```

### Step 7 — Deploy the Frontend to S3

```bash
cd ..
aws s3 sync frontend s3://stocks-pipeline-frontend --region us-west-2
```

### Step 8 — Test the Pipeline

Manually invoke the ingestion Lambda to verify it runs correctly:

```bash
aws lambda invoke \
  --function-name stocks-pipeline-ingestion \
  --region us-west-2 \
  --log-type Tail \
  output.json && cat output.json
```

You should see a 200 response with the top mover's date, ticker, pct_change, and close_price.

Verify the record was written to DynamoDB:

```bash
aws dynamodb scan \
  --table-name stock-movers \
  --region us-west-2 \
  --no-cli-pager
```

Then open the website URL in your browser and confirm the table displays the data.

---

## Watchlist

```python
WATCHLIST = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA']
```

## Percentage Change Formula

```
((Close Price - Open Price) / Open Price) * 100
```

The stock with the highest **absolute value** percentage change wins — so -5% beats +3%.

---

## Security

- **Massive API key** is stored in AWS Secrets Manager and fetched at Lambda runtime via boto3. It is never hardcoded or committed to GitHub.
- **IAM roles** follow least privilege — the ingestion Lambda can only write to DynamoDB and read from Secrets Manager. The API Lambda can only read from DynamoDB.
- **`.gitignore`** excludes `.env` files, Terraform state files, Lambda zip files, and all Python dependency folders.