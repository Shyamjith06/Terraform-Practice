#!/usr/bin/env bash
set -e

K8S_CMD=kubectl
K8S_NS_OPT=--namespace=gradle
DB_POD="$($K8S_CMD $K8S_NS_OPT get pods --selector=app=gradle-enterprise --selector=component=database -o jsonpath='{.items[*].metadata.name}')"

$K8S_CMD $K8S_NS_OPT exec $DB_POD -c database -- /opt/gradle/scripts/system_backup.sh
