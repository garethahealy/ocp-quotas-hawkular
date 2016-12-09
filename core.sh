#!/usr/bin/env bash

PROJECTS=$(oc get projects --no-headers | cut -d' ' -f1 | xargs)
PROJECTS_ARRAY=($PROJECTS)

for project in "${PROJECTS_ARRAY[@]}" ; do
    echo "Project: $project"

    QUOTA_ARRAY=$(oc get quota --output=json -n $project)

    if [ ! -z ${QUOTA_ARRAY+x} ]; then
        QUOTA_COUNT=$(echo $QUOTA_ARRAY | jq '.items | length')

        for ((i = 0; i < $QUOTA_COUNT; i++)); do
            QUOTA=$(echo $QUOTA_ARRAY | jq --arg i "$i" '.items[$i | tonumber]')
            QUOTA_HARD=$(echo $QUOTA | jq '.status.hard')
            QUOTA_USED=$(echo $QUOTA | jq '.status.used')

            echo $QUOTA_HARD
            echo $QUOTA_USED
        done
    fi
done

