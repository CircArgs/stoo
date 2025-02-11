import requests
from bs4 import BeautifulSoup
import re

# Configuration
ARTIFACTORY_URL = "https://artifactory.cloud.capitalone.com:443/artifactory"
REPO_KEY = "pypi-internalfacing"
PACKAGE_NAME = "c1-genai-workflow-dev-client"

# Construct the Artifactory API URL
api_url = f"{ARTIFACTORY_URL}/api/pypi/{REPO_KEY}/simple/{PACKAGE_NAME}/"

# Fetch package versions
response = requests.get(api_url)
if response.status_code != 200:
    print("❌ Failed to fetch package versions")
    exit(1)

# Parse the HTML response with BeautifulSoup
soup = BeautifulSoup(response.text, "html.parser")

# Extract all links and find version numbers
version_pattern = re.compile(rf"{PACKAGE_NAME}-(\d+\.\d+\.\d+)")
versions = [match.group(1) for link in soup.find_all("a") if (match := version_pattern.search(link.text))]

if not versions:
    print("❌ No versions found")
    exit(1)

# Sort and get the latest version
latest_version = sorted(versions, key=lambda v: list(map(int, v.split('.'))))[-1]

print(f"✅ Latest version: {latest_version}")
