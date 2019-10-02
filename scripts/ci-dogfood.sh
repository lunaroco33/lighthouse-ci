#!/bin/bash

# This script requires LHCI_CANARY_SERVER_URL and LHCI_CANARY_SERVER_TOKEN variables to be set.

if [[ "$TRAVIS_NODE_VERSION" != "10" ]]; then
  echo "Not running dogfood script on node versions other than 10";
  exit 0;
fi

set -euox pipefail

# Start up our LHCI server.
yarn start:server --port=9009 &
# Wait for the server to start before hitting it with data.
sleep 10

# Seed the database with some data for us to audit.
yarn start:seed-database
# Collect our LHCI results.
rm -rf .lighthouseci/
for url in $(LHCI_ROOT_URL=http://localhost:9009 node ./scripts/ci-dogfood-get-urls.js); do
  yarn start collect "--url=$url" --additive
done

# Upload the results to our canary server.
yarn start upload --serverBaseUrl="$LHCI_CANARY_SERVER_URL" --token="$LHCI_CANARY_SERVER_TOKEN"

# Kill the LHCI server from earlier.
kill $!