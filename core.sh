#!/usr/bin/env bash

PROJECTS=$(oc get projects --no-headers | cut -d' ' -f1 | xargs)
PROJECTS_ARRAY=($PROJECTS)

for project in "${PROJECTS_ARRAY[@]}" ; do
    echo "Project: $project"

    oc get quota --output=json -n $project | jq '.items'

    echo
done
