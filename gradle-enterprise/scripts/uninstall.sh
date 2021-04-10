#!/usr/bin/env bash
set -e

# Warn the user that this is a destructive operation and explicitly require them to accept
echo "******************************************************************************************"
echo "* WARNING: You are about to remove all Gradle Enterprise components from your Kubernetes *"
echo "*          cluster. For storage classes with a 'delete' reclaim policy this will mean    *"
echo "*          that all data will also be lost.                                              *"
echo "*****************************************************************************************"
read -r -p "Proceed? [y/N] " response


echo "Removing Gradle Enterprise components from 'gradle' namespace..."

cd "${BASH_SOURCE%/*}"
unset FAILED
kubectl --namespace gradle delete secret replicatedregistrykey
kubectl --namespace gradle delete -f gradle_enterprise.yml || FAILED=1

if [ ${FAILED} ]
then
    echo "Failed to delete Kubernetes components. See above errors for details."
    exit 1
fi

echo "Gradle Enterprise has been successfully uninstalled."
