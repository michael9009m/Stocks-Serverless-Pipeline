import json
import os
import boto3
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key

# AWS DynamoDB client
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """Main Lambda entry point - called by API Gateway GET /movers"""
    print(f"API request received at {datetime.now().isoformat()}")

    # CORS headers so the S3 frontend can call this API
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Content-Type': 'application/json'
    }

    try:
        table_name = os.environ['DYNAMODB_TABLE_NAME']
        table = dynamodb.Table(table_name)

        # Generate the last 7 dates to query
        today = datetime.now().date()
        last_7_days = [
            (today - timedelta(days=i)).isoformat()
            for i in range(7)
        ]

        # Fetch each day's top mover from DynamoDB
        results = []
        for date_str in last_7_days:
            try:
                response = table.get_item(Key={'date': date_str})
                item = response.get('Item')
                if item:
                    results.append({
                        'date': item['date'],
                        'ticker': item['ticker'],
                        'pct_change': float(item['pct_change']),
                        'close_price': float(item['close_price'])
                    })
            except Exception as e:
                print(f"ERROR fetching item for {date_str}: {str(e)}")
                continue

        # Sort by date descending so most recent is first
        results.sort(key=lambda x: x['date'], reverse=True)

        print(f"Returning {len(results)} records")

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(results)
        }

    except Exception as e:
        print(f"FATAL ERROR: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }