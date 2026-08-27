import requests

def fetch_sensitive_data(api_url):
    # CWE-295 Trigger: verify=False disables SSL certificate validation
    try:
        response = requests.get(api_url, verify=False)
        if response.status_code == 200:
            return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
    
    return None

if __name__ == "__main__":
    data = fetch_sensitive_data("https://api.example.com/v1/data")
    print(data)
