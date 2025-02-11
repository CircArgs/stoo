import requests
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

# Extract version numbers using regex
version_pattern = re.compile(rf"{PACKAGE_NAME}-(\d+\.\d+\.\d+)")  # Matches "package-0.0.4"
versions = version_pattern.findall(response.text)

if not versions:
    print("❌ No versions found")
    exit(1)

# Sort and get the latest version
latest_version = sorted(versions, key=lambda v: list(map(int, v.split('.'))))[-1]

print(f"✅ Latest version: {latest_version}")
