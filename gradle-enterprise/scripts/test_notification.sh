#!/usr/bin/env bash
set -e

K8S_NAMESPACE=gradle

find_pod() {
    echo $(kubectl --namespace=${K8S_NAMESPACE} get pods --selector=app=gradle-enterprise --selector=component=$1 -o jsonpath='{.items[*].metadata.name}')
}

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod scans-server) -- curl -s http://localhost:8080/info/secure/admin-notification-test
