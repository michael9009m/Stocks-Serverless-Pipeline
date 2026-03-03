import json
import os
import boto3
import requests
from datetime import datetime, date, timedelta

# AWS clients
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager', region_name='us-west-2')

# Stock watchlist from the project requirements
WATCHLIST = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA']

def get_api_key():
    """Fetch the Massive API key from Secrets Manager at runtime"""
    try:
        secret_name = os.environ['SECRET_NAME']
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        return secret['api_key']
    except Exception as e:
        print(f"ERROR fetching secret: {str(e)}")
        raise

def get_stock_data(ticker, api_key):
    """Fetch previous day open and close price for a single ticker"""
    try:
        # Using the v2 aggregates endpoint which returns previous day OHLC data
        url = f"https://api.massive.com/v2/aggs/ticker/{ticker}/prev"
        params = {
            "adjusted": "true",
            "apiKey": api_key
        }
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()

        # Check the API returned results
        if data.get('status') != 'OK' or not data.get('results'):
            print(f"NO DATA for {ticker}: {data.get('status')}")
            return None

        result = data['results'][0]
        open_price = result['o']
        close_price = result['c']

        # Calculate percentage change formula from project requirements
        pct_change = ((close_price - open_price) / open_price) * 100

        return {
            'ticker': ticker,
            'pct_change': pct_change,
            'close_price': close_price
        }

    except requests.exceptions.Timeout:
        print(f"TIMEOUT fetching data for {ticker}")
        return None
    except requests.exceptions.HTTPError as e:
        print(f"HTTP ERROR for {ticker}: {str(e)}")
        return None
    except KeyError as e:
        print(f"MISSING DATA for {ticker}: {str(e)}")
        return None
    except Exception as e:
        print(f"UNEXPECTED ERROR for {ticker}: {str(e)}")
        return None

def lambda_handler(event, context):
    """Main Lambda entry point - runs daily via EventBridge"""
    print(f"Starting ingestion at {datetime.now().isoformat()}")

    try:
        # Get API key from Secrets Manager
        api_key = get_api_key()

        # Fetch data for all stocks in watchlist
        results = []
        for ticker in WATCHLIST:
            print(f"Fetching data for {ticker}")
            stock_data = get_stock_data(ticker, api_key)
            if stock_data:
                results.append(stock_data)
            else:
                print(f"Skipping {ticker} due to fetch error")

        # Check we got at least some results
        if not results:
            print("ERROR: No stock data retrieved for any ticker")
            return {
                'statusCode': 500,
                'body': 'Failed to retrieve stock data'
            }

        # Find the top mover by absolute percentage change
        top_mover = max(results, key=lambda x: abs(x['pct_change']))
        print(f"Top mover: {top_mover['ticker']} with {top_mover['pct_change']:.2f}% change")

        # Use yesterday's date since /prev endpoint returns previous trading day data
        # This must be set BEFORE writing to DynamoDB
        trading_date = (date.today() - timedelta(days=1)).isoformat()

        # Store result in DynamoDB
        table_name = os.environ['DYNAMODB_TABLE_NAME']
        table = dynamodb.Table(table_name)

        table.put_item(Item={
            'date': trading_date,
            'ticker': top_mover['ticker'],
            'pct_change': str(round(top_mover['pct_change'], 4)),
            'close_price': str(top_mover['close_price'])
        })

        print(f"Successfully stored top mover for {trading_date}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'date': trading_date,
                'ticker': top_mover['ticker'],
                'pct_change': round(top_mover['pct_change'], 4),
                'close_price': top_mover['close_price']
            })
        }

    except Exception as e:
        print(f"FATAL ERROR: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Fatal error: {str(e)}'
        }