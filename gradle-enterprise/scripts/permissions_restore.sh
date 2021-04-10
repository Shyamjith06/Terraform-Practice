#!/usr/bin/env bash


GRADLE_USER_ID="${GRADLE_USER_ID:-999}"
GRADLE_GROUP_ID="${GRADLE_GROUP_ID:-0}"
NAMESPACE="gradle"

echo "Scaling Gradle Enterprise deployment in namespace ${NAMESPACE}"
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-admin
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-proxy
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-server
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-build-cache
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-keycloak
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-database
kubectl --namespace=${NAMESPACE} scale --replicas=0 deployment/gradle-metrics

echo "Creating script"
kubectl --namespace=${NAMESPACE} create configmap gradle-permission-restore-entrypoint --from-file="$(dirname $0)/_permissions_restore_entrypoint.sh"

echo "Running job"
kubectl --namespace=${NAMESPACE}  apply -f - << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: gradle-restore-permissions
  namespace: "${NAMESPACE}"
spec:
  backoffLimit: 5
  activeDeadlineSeconds: 600
  template:
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - name: gradle-permissions
        image: busybox:1.31
        command: ["/entrypoint.sh"]
        env:
        - name: PG_LOCATION
          value: /opt/gradle/data/postgresql
        - name: BACKUP_LOCATION
          value: /opt/gradle/backups
        - name: LOG_ROOT
          value: /opt/gradle/logs
        - name: BUILD_CACHE_ROOT
          value: /opt/gradle/data/build-cache
        - name: METRICS_LOCATION
          value: /opt/gradle/metrics
        - name: GRADLE_USER_ID
          value: "${GRADLE_USER_ID}"
        - name: GRADLE_GROUP_ID
          value: "${GRADLE_GROUP_ID}"
        - name: GRADLE_K8S_DATA_MOVE
          value: "1"
        volumeMounts:
        - mountPath: /opt/gradle/logs/proxy
          name: proxy-logs
          subPath: proxy
        - mountPath: /opt/gradle/metrics
          name: metrics-storage
        - mountPath: /opt/gradle/data/postgresql
          name: postgres-data
          subPath: data
        - mountPath: /opt/gradle/logs/database
          name: database-logs
          subPath: database
        - mountPath: /opt/gradle/data/build-cache
          name: build-cache
        - mountPath: /entrypoint.sh
          name: entrypoint
          subPath: _permissions_restore_entrypoint.sh
      volumes:
      - name: proxy-logs
        persistentVolumeClaim:
          claimName: gradle-proxy-logs-volume
      - name: metrics-storage
        persistentVolumeClaim:
          claimName: gradle-metrics-volume
      - name: postgres-data
        persistentVolumeClaim:
          claimName: gradle-database-volume
      - name: database-logs
        persistentVolumeClaim:
          claimName: gradle-database-logs-volume
      - name: build-cache
        persistentVolumeClaim:
          claimName: gradle-build-cache-volume
      - name: entrypoint
        configMap:
          name: gradle-permission-restore-entrypoint
          defaultMode: 0777
      restartPolicy: Never
EOF

TIMEOUT_IN_SECONDS=600
echo "Waiting ${TIMEOUT_IN_SECONDS}s for job to complete"
kubectl --namespace=${NAMESPACE} wait --for=condition=complete --timeout=${TIMEOUT_IN_SECONDS}s job/gradle-restore-permissions
WAIT_RESULT=$?
if [[ ${WAIT_RESULT} -ne 0 ]]; then
    echo "Error: Job did not complete"
    exit ${WAIT_RESULT}
fi

echo "Deleting job and script"
kubectl --namespace=${NAMESPACE}  delete configmap gradle-permission-restore-entrypoint
kubectl --namespace=${NAMESPACE}  delete job gradle-restore-permissions

echo "Scaling Gradle Enterprise"
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-admin
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-proxy
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-server
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-build-cache
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-keycloak
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-database
kubectl --namespace=${NAMESPACE} scale --replicas=1 deployment/gradle-metrics

echo "Done."

