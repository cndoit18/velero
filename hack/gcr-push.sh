#!/bin/sh

if [[ -z "$TRAVIS" ]]; then
    echo "This script is intended to be run only on Travis." >&2
    exit 1
fi

# Return value is written into HIGHEST
HIGHEST=""
function highest_release() {
    # Loop through the tags since pre-release versions come before the actual versions.
    # Iterate til we find the first non-pre-release

    # This is not necessarily the most recently made tag; instead, we want it to be the highest semantic version.
    # The most recent tag could potentially be a lower semantic version, made as a point release for a previous series.
    # As an example, if v1.3.0 exists and we create v1.2.2, v1.3.0 should still be `latest`.
    # `git describe --tags $(git rev-list --tags --max-count=1)` would return the most recently made tag.

    for t in $(git tag -l --sort=-v:refname);
    do
        # If the tag has alpha, beta or rc in it, it's not "latest"
        if [[ "$t" == *"beta"* || "$t" == *"alpha"* || "$t" == *"rc"* ]]; then
            continue
        fi
        HIGHEST="$t"
        break
    done
}

gcloud auth activate-service-account --key-file OUR_KEY_FILE
unset GIT_HTTP_USER_AGENT

# only publish for master or if a tag is defined
if [ "$BRANCH" == "master" ]; then
    VERSION="$BRANCH" DOCKER="gcloud docker -- " make all-containers all-push
elif [ ! -z "$TRAVIS_TAG" ]; then
    # Calculate the latest release
    highest_release

    # Default to pre-release
    TAG_LATEST=false
    if [[ "$TRAVIS_TAG" == "$HIGHEST" ]]; then
        TAG_LATEST=true
    fi

    VERSION="$TRAVIS_TAG" TAG_LATEST="$TAG_LATEST" DOCKER="gcloud docker -- " make all-containers all-push
fi