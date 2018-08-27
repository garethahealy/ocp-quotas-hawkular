[![Build Status](https://travis-ci.org/garethahealy/ocp-quotas-hawkular.svg?branch=master)](https://travis-ci.org/garethahealy/ocp-quotas-hawkular)
[![License](https://img.shields.io/hexpm/l/plug.svg?maxAge=2592000)]()

# ocp-quotas-hawkular
A PoC to look into retrieving quotas from OCP and pushing into Hawkular Metrics so they can be viewed by grafana

## tenant config
- https://docs.openshift.com/container-platform/3.10/admin_guide/multiproject_quota.html#multi-project-quotas-viewing-applicable-clusterresourcequotas
- oc new-project grafana
- oc adm policy add-role-to-user edit system:serviceaccount:grafana:default
- oc sa new-token default
