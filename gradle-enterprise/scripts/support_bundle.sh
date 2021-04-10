#!/usr/bin/env bash

K8S_NAMESPACE=gradle
SUPPORT_BUNDLE_FILENAME=support-bundle-$(date +'%Y%m%d-%H%M%S').tgz

find_pod() {
    echo $(kubectl --namespace=${K8S_NAMESPACE} get pods --selector=app=gradle-enterprise --selector=component=$1 -o jsonpath='{.items[*].metadata.name}')
}

echo "Generating support bundle..."

cd "${BASH_SOURCE%/*}"
rm -rf bundle_temp
mkdir -p bundle_temp/server bundle_temp/database bundle_temp/build-cache bundle_temp/proxy bundle_temp/metrics bundle_temp/admin bundle_temp/keycloak
cd bundle_temp

kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod database) > ./database/stdout.log
kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod database) -c database-upgrade > ./database/init-stdout.log
kubectl cp ${K8S_NAMESPACE}/$(find_pod database):opt/gradle/data/upgrade-logs/upgrade.log ./database
kubectl cp ${K8S_NAMESPACE}/$(find_pod database):opt/gradle/data/logs/database.log ./database
kubectl cp ${K8S_NAMESPACE}/$(find_pod database):opt/gradle/data/logs/cron.log ./database

kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod scans-server) > ./server/stdout.log
kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod scans-server) -c scans-server-migrator > ./server/init-stdout.log
kubectl cp ${K8S_NAMESPACE}/$(find_pod scans-server):opt/gradle/data/logs/server.log ./server
kubectl cp ${K8S_NAMESPACE}/$(find_pod scans-server):opt/gradle/data/migrator-logs/scans-server-database-migrator.log ./server

kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod build-cache-server) > ./build-cache/stdout.log
kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod build-cache-server) -c gradle-build-cache-migrator > ./build-cache/init-stdout.log
kubectl cp ${K8S_NAMESPACE}/$(find_pod build-cache-server):opt/gradle/data/logs/build-cache.log ./build-cache
kubectl cp ${K8S_NAMESPACE}/$(find_pod build-cache-server):opt/gradle/data/migrator-logs/build-cache-database-migrator.log ./build-cache

kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod admin-server) > ./admin/stdout.log
kubectl cp ${K8S_NAMESPACE}/$(find_pod admin-server):opt/gradle/data/logs/admin.log ./admin

kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod keycloak-server) > ./keycloak/stdout.log
kubectl --namespace=${K8S_NAMESPACE} logs $(find_pod keycloak-server) -c gradle-keycloak-config-initializer > ./keycloak/init-stdout.log
kubectl cp ${K8S_NAMESPACE}/$(find_pod keycloak-server):opt/gradle/data/logs/keycloak.log ./keycloak
kubectl cp ${K8S_NAMESPACE}/$(find_pod keycloak-server):opt/gradle/data/migrator-logs/keycloak-config-initializer.log ./keycloak

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod scans-server) -- curl -s http://localhost:8080/info/secure/metrics > ./server/info-secure-metrics.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod scans-server) -- curl -s http://localhost:8080/info/health > ./server/info-health.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod scans-server) -- sh -c "find /opt/gradle/data/logs -type f -mtime -5 -name 'server*.log.gz' | sort | xargs -r gzip -cdfq | cat - /opt/gradle/data/logs/server.log" > ./server/server-5days.log

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/active_slow_queries.sql > ./database/active_slow_queries
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/db_stats.sql > ./database/db_stats-dotcom
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/db_diskusage.sql > ./database/db_diskusage-dotcom
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/tbl_diskusage.sql > ./database/tbl_diskusage-dotcom
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/tbl_bloat.sql > ./database/tbl_bloat-dotcom
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/idx_stats.sql > ./database/idx_stats-dotcom
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -d gcs_build_cache -f /opt/gradle/support/db_stats.sql > ./database/db_stats-gcs_build_cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -d gcs_build_cache -f /opt/gradle/support/db_diskusage.sql > ./database/db_diskusage-gcs_build_cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -d gcs_build_cache -f /opt/gradle/support/tbl_diskusage.sql > ./database/tbl_diskusage-gcs_build_cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -d gcs_build_cache -f /opt/gradle/support/tbl_bloat.sql > ./database/tbl_bloat-gcs_build_cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -d gcs_build_cache -f /opt/gradle/support/idx_stats.sql > ./database/idx_stats-gcs_build_cache
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- du -h /var/lib/postgresql/data/ > ./database/du_postgresql_data
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/db_build_cnt.sql > ./database/db_build_cnt
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod database) -- psql -U dotcom -f /opt/gradle/support/db_build_size_distribution.sql > ./database/db_build_size_dist

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod build-cache-server) -- curl -s http://localhost:8081/cache-info/secure/metrics > ./build-cache/info-secure-metrics.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod build-cache-server) -- curl -s http://localhost:8081/cache-info/health > ./build-cache/info-health.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod build-cache-server) -- sh -c "find /opt/gradle/data/logs -type f -mtime -5 -name 'build-cache*.log.gz' | sort | xargs -r gzip -cdfq | cat - /opt/gradle/data/logs/build-cache.log" > ./build-cache/build-cache-5days.log

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod admin-server) -- curl -s http://localhost:8082/admin-info/secure/metrics > ./admin/info-secure-metrics.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod admin-server) -- curl -s http://localhost:8082/admin-info/health > ./admin/info-health.log
kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod admin-server) -- sh -c "find /opt/gradle/data/logs -type f -mtime -5 -name 'admin*.log.gz' | sort | xargs -r gzip -cdfq | cat - /opt/gradle/data/logs/admin.log" > ./admin/admin-5days.log

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod keycloak-server) -- sh -c "find /opt/gradle/data/logs -type f -mtime -5 -name 'keycloak*.log.gz' | sort | xargs -r gzip -cdfq | cat - /opt/gradle/data/logs/keycloak.log" > ./keycloak/keycloak-5days.log

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod proxy) -- sh -c "find /opt/gradle/data/logs -type f -mtime -5 -name 'proxy-error.log-*.gz' | sort | xargs -r gzip -cdfq | cat - /opt/gradle/data/logs/proxy-error.log" > ./proxy/proxy-error.log

kubectl --namespace=${K8S_NAMESPACE} exec $(find_pod metrics) -- tar -C /opt/graphite/storage -cO whisper > ./metrics/statsd.tar

tar -zcf ../${SUPPORT_BUNDLE_FILENAME} .
cd ..
rm -rf bundle_temp

echo "Support bundle file $(pwd)/${SUPPORT_BUNDLE_FILENAME} created"
