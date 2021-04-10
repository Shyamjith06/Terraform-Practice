#!/usr/bin/env bash
set -e

K8S_NAMESPACE=gradle

find_pod() {
    echo $(kubectl --namespace=${K8S_NAMESPACE} get pods --selector=app=gradle-enterprise --selector=component=$1 -o jsonpath='{.items[*].metadata.name}')
}

prompt="Please select a backup file:"
options=( $(kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- find /opt/gradle/backup/postgres -type f -name 'backup-*.zip' | sort -r | grep -E -o 'backup-[0-9]{8}-[0-9]{6}.zip') )

PS3="$prompt "
select opt in "${options[@]}" "Quit" ; do
    if (( REPLY == 1 + ${#options[@]} )) ; then
        exit
    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo "Copying Gradle Enterprise backup..."
        kubectl cp ${K8S_NAMESPACE}/$(find_pod database):opt/gradle/backup/postgres/${opt} . 1>/dev/null
        echo "Backup file copied to $(pwd)/${opt}"
        break
    else
        echo "Invalid option. Try another one."
    fi
done
