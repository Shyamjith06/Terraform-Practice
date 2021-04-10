#!/usr/bin/env bash
set -e

cd "${BASH_SOURCE%/*}"

echo "Installing Gradle Enterprise into 'gradle' namespace..."



unset FAILED
kubectl --namespace gradle get secret replicatedregistrykey >/dev/null 2>&1 || kubectl --namespace gradle create secret generic replicatedregistrykey --type='kubernetes.io/dockerconfigjson' --from-file=.dockerconfigjson=docker_pull_secret.json
kubectl --namespace gradle apply -f gradle_enterprise.yml || FAILED=1

if [ ${FAILED} ]
then
    echo "Failed to apply Kubernetes configuration. See above errors for details."
    exit 1
fi

echo "Gradle Enterprise has been successfully installed into Kubernetes cluster."
