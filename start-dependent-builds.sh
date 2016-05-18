#!/bin/bash

start_build() {
    body='{"request":{"branch":"'${TRAVIS_BRANCH}'"}}'
    curl -s -X POST -H "Content-Tpe: application/json" -H "Accept: application/json" -H "Travis-API-Version: 3" -H "Authorization: token ${AUTH_TOKEN}" -d "${body}" https://api.travis-ci.org/repo/${1}/requests
}

travis_slugs=("ibm-bluemix-mobile-services%2Fbms-clientsdk-swift-analytics" "ibm-bluemix-mobile-services%2Fbms-clientsdk-swift-analyticsspec" "ibm-bluemix-mobile-services%2Fbms-clientsdk-swift-push")

for travis_slug in "${travis_slugs[@]}"
do
  start_build "$travis_slug"
done
