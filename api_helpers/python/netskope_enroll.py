import json
import os
import boto3
import requests
from botocore.exceptions import ClientError


def get_secret_from_aws(secret_name, region_name="us-east-1"):
    """Fetches the central Netskope API token from the AFT Management Account."""
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        print(f"❌ Error retrieving secret from AFT Management Account: {e}")
        raise e

    if "SecretString" in get_secret_value_response:
        secret = get_secret_value_response["SecretString"]
        try:
            secret_dict = json.loads(secret)
            return secret_dict.get("token", secret)
        except json.JSONDecodeError:
            return secret

    return None


def get_account_name_from_ddb(account_id, region_name="us-east-1"):
    """Queries the local AFT metadata table directly from the Management session."""
    dynamodb = boto3.client('dynamodb', region_name=region_name)
    table_name = "aft-request-metadata"

    try:
        print(f"🔍 Querying table '{table_name}' for Account ID: {account_id}...")
        response = dynamodb.get_item(
            TableName=table_name,
            Key={'id': {'S': str(account_id)}}
        )
        
        item = response.get('Item')
        if item and 'account_name' in item:
            account_name = item['account_name']['S']
            print(f"✅ Found match in AFT registry: '{account_name}'")
            return account_name
        
        print(f"⚠️ Warning: No explicit database entry found for ID {account_id}.")
        return "Unknown-AFT-Account"

    except Exception as e:
        print(f"❌ Database Query Failure: {e}")
        return "Unknown-AFT-Account"


def add_app_instances(tenant_url, token, instances_payload):
    """Dispatches the payload directly to the Netskope core API."""
    if not tenant_url.startswith("https://"):
        tenant_url = f"https://{tenant_url}"

    url = f"{tenant_url}/api/v1/app_instances"
    params = {"token": token, "op": "add"}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(
            url, params=params, headers=headers, json=instances_payload
        )
        response.raise_for_status()
        print(f"✅ Netskope API Status Code: {response.status_code}")
        print("Response Body:")
        print(json.dumps(response.json(), indent=4))
        return response.json()
    except Exception as err:
        print(f"❌ Netskope API Connection Error: {err}")


if __name__ == "__main__":
    TENANT_URL = "agero.goskope.com"
    AWS_SECRET_NAME = "my-netskope-secret"  
    AWS_REGION = "us-east-1"                 
    JSON_FILE_PATH = os.path.join(os.path.dirname(__file__), "instances.json")

    print("🚀 Booting AFT Native Pipeline API Helper Wrapper...")

    # 1. Grab environment variable natively broadcasted by CodeBuild container
    target_account_id = os.environ.get("VENDED_ACCOUNT_ID")
    
    if not target_account_id:
        print("❌ Fatal Error: VENDED_ACCOUNT_ID environment variable is missing.")
        exit(1)

    # 2. Resolve Account Name dynamically using local Management session
    target_account_name = get_account_name_from_ddb(target_account_id, AWS_REGION)
    print(f"🎯 Target Profile Scoped -> ID: {target_account_id} | Name: {target_account_name}")

    # 3. Load Template Schema
    try:
        with open(JSON_FILE_PATH, "r") as file:
            payload_data = json.load(file)
    except FileNotFoundError:
        print(f"❌ Error: Missing instances.json file next to script.")
        exit(1)

    # 4. In-Memory Replace
    modified_count = 0
    for instance in payload_data.get("instances", []):
        if instance.get("instance_id") == "replacewithaccountid":
            instance["instance_id"] = target_account_id
            modified_count += 1
        if instance.get("instance_name") == "replacewithaccountname":
            instance["instance_name"] = target_account_name

    print(f"📋 Tailored {modified_count} instance profiles for submission.")

    # 5. Extract Secret Token from local account and Enroll
    api_token = get_secret_from_aws(AWS_SECRET_NAME, AWS_REGION)
    if api_token:
        add_app_instances(TENANT_URL, api_token, payload_data)
    else:
        print("❌ Fatal Error: Token validation empty.")
        exit(1)