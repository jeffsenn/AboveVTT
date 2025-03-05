#remember: pip install pyjwt cryptography
import jwt
import time
import requests
import os
import base64
env = dict([a.split("=",1) for a in open('env').read().strip().split('\n')])

def generate_token():
    private_key = base64.b64decode(os.environ.get('PRIVATE_KEY_BASE64')).decode('utf-8')
    payload = {
        "iss": env['APP_STORE_CONNECT_API_ISSUER_ID'],
        "iat": int(time.time()) - 20,  # Issued at
        "exp": int(time.time()) + 19*60,  # 19 min max
        "aud": "appstoreconnect-v1",
    }
    headers = {
        "alg": "ES256",
        "kid": env['APP_STORE_CONNECT_API_KEY_ID']
    }
    token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return token

# Fetch latest TestFlight version
def fetch_latest_testflight_version():
    token = generate_token()
    url = f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={env['APP_ID']}&sort=-version"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    }

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        builds = response.json().get("data", [])
        if builds:
            latest_build = builds[0]  # First item is the latest version
            version = latest_build["attributes"]["version"]
            print(int(version)+1)
    else:
        raise Exception(f"Error fetching data: {response.status_code} - {response.text}")

# Run the script
if __name__ == "__main__":
    fetch_latest_testflight_version()
    
