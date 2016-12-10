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
            QUOTA_NAME=$(echo $QUOTA | jq '.metadata.name' | tr -d '"')
            QUOTA_NAMESPACE=$(echo $QUOTA | jq '.metadata.namespace' | tr -d '"')

            QUOTA_HARD=$(echo $QUOTA | jq '.status.hard | to_entries')
            if [ ! -z ${QUOTA_HARD+x} ]; then
                QUOTA_HARD_COUNT=$(echo $QUOTA_HARD | jq length)
                for ((j = 0; j < $QUOTA_HARD_COUNT; j++)); do
                    ITEM=$(echo $QUOTA_HARD | jq --arg j "$j" '.[$j | tonumber]')
                    ITEM_KEY=$(echo $ITEM | jq '.key' | tr -d '"')
                    ITEM_VALUE=$(echo $ITEM | jq '.value' | tr -d '"')

                    METRIC_ID="$QUOTA_NAMESPACE-$QUOTA_NAME-$ITEM_KEY"
                    echo "Hard; $METRIC_ID = $ITEM_VALUE"

                    HAWKULAR_URL="https://hawkular-metrics.apps.10.2.2.2.xip.io/hawkular/metrics"
                    HAWKULAR_TOKEN=$(oc whoami -t)
                    HAWKULAR_TENANT="custom"

                    CREATE_JSON_PAYLOAD=$(cat <<EOF
{
  "id" : "$METRIC_ID",
  "tags" : {
    "namespace" : "$QUOTA_NAMESPACE",
    "quota" : "true"
  },
  "type" : "counter",
  "tenantId" : "$HAWKULAR_TENANT"
}
EOF
)

                    ADD_JSON_PAYLOAD=$(cat <<EOF
[
  {
    "timestamp": $(date +%s%N | cut -b1-13),
    "value": $ITEM_VALUE,
    "tags" : {
      "namespace" : "$QUOTA_NAMESPACE",
      "quota" : "true"
    }
  }
]
EOF
)

                    # Check metric does exist and create
                    HTTP_STATUS=$(curl -k -X GET --write-out %{http_code} --silent --output /dev/null -H "Content-Type: application/json" -H "Hawkular-Tenant: $HAWKULAR_TENANT" -H "Authorization: Bearer $HAWKULAR_TOKEN" $HAWKULAR_URL/counters/$METRIC_ID)
                    if [ $HTTP_STATUS == "204" ]; then
                        echo $CREATE_JSON_PAYLOAD | curl -k -X POST -H "Content-Type: application/json" -H "Hawkular-Tenant: $HAWKULAR_TENANT" -H "Authorization: Bearer $HAWKULAR_TOKEN" $HAWKULAR_URL/counters -d @-
                    fi

                    # Create datapoints
                    echo $ADD_JSON_PAYLOAD | curl -k -X POST -H "Content-Type: application/json" -H "Hawkular-Tenant: $HAWKULAR_TENANT" -H "Authorization: Bearer $HAWKULAR_TOKEN" $HAWKULAR_URL/counters/$METRIC_ID/raw -d @-
                done
            fi

            #QUOTA_USED=$(echo $QUOTA | jq '.status.used | to_entries')
            #if [ ! -z ${QUOTA_USED+x} ]; then
            #    $QUOTA_USED
            #fi
        done
    fi
done
