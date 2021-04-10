#!/usr/bin/env bash
set -e

if [[ $# -eq 0 ]] ; then
    echo "Please provide the backup to be restored as argument."
    echo ""
    echo "Example: restore_backup.sh backup-20180525-111555.zip"
    exit 0
fi

if [ ! -f $1 ]; then
	echo "Error: $1 doesn't exist"
    exit 0
fi

K8S_NAMESPACE=gradle

find_pod() {
    echo $(kubectl --namespace=${K8S_NAMESPACE} get pods --selector=app=gradle-enterprise --selector=component=$1 -o jsonpath='{.items[*].metadata.name}')
}

echo "Restoring Backup"

kubectl --namespace=${K8S_NAMESPACE} scale --replicas=0 deployment/gradle-server
kubectl --namespace=${K8S_NAMESPACE} scale --replicas=0 deployment/gradle-build-cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- supervisorctl stop database
kubectl --namespace=${K8S_NAMESPACE} cp $1 $(find_pod database):/opt/gradle/backup/postgres
kubectl --namespace=${K8S_NAMESPACE} exec -it $(find_pod database) -- ./opt/gradle/scripts/restore_snapshot.sh -y /opt/gradle/backup/postgres/$1
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- supervisorctl start database
kubectl --namespace=${K8S_NAMESPACE} scale --replicas=1 deployment/gradle-build-cache
kubectl --namespace=${K8S_NAMESPACE} scale --replicas=1 deployment/gradle-server

echo "Backup restored"
