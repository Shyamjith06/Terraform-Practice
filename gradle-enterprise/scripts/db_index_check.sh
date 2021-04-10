#!/usr/bin/env bash
set -e

K8S_CMD=kubectl
K8S_NS_OPT=--namespace=gradle
SCANS_POD="$($K8S_CMD $K8S_NS_OPT get pods --selector=app=gradle-enterprise --selector=component=scans-server -o jsonpath='{.items[*].metadata.name}')"

$K8S_CMD $K8S_NS_OPT exec $SCANS_POD -c gradle-server -- curl -s http://localhost:8080/info/secure/admin-db-index-check
echo
