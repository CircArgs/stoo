LATEST_VERSION=$(curl -s "$ARTIFACTORY_URL/api/pypi/$REPO_KEY/simple/$PACKAGE_NAME/" | sed -n 's/.*'"$PACKAGE_NAME"'-\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' | sort -V | tail -n 1)

echo "Latest version: $LATEST_VERSION"
