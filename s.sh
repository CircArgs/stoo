#!/bin/bash

PACKAGE_NAME="c1-genai-workflow-dev-client"
ARTIFACTORY_URL="https://artifactory.cloud.capitalone.com:443/artifactory"
REPO_KEY="pypi-internalfacing"

# Get installed version
INSTALLED_VERSION=$(pip show "$PACKAGE_NAME" | grep -i "Version:" | awk '{print $2}')

# Get the latest available version from Artifactory
LATEST_VERSION=$(curl -s "$ARTIFACTORY_URL/api/pypi/$REPO_KEY/simple/$PACKAGE_NAME/" | grep -oP '(?<=<a href=")[^"]+' | sort -V | tail -n 1)

if [[ -z "$INSTALLED_VERSION" ]]; then
    echo "⚠️  $PACKAGE_NAME is not installed."
    exit 1
fi

if [[ -z "$LATEST_VERSION" ]]; then
    echo "⚠️  Unable to fetch latest version."
    exit 1
fi

# Compare versions
if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
    echo "🚀 A new version ($LATEST_VERSION) is available! You are using $INSTALLED_VERSION."
    read -p "Would you like to update now? (y/n): " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Updating..."
        pip install --index-url "$ARTIFACTORY_URL/api/pypi/$REPO_KEY/simple" --upgrade "$PACKAGE_NAME"
        echo "✅ Update complete! Restart the CLI to use the latest version."
    else
        echo "❌ Update skipped. You may experience issues with an outdated version."
    fi
else
    echo "✅ You are using the latest version ($INSTALLED_VERSION)."
fi
