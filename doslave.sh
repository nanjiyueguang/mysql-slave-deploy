#!/bin/bash
if [ $# -ne 5 ];then
echo "input sort : namespace service image configmap size_number"
exit 0;
fi
namespace=$1
service_name=$2
secretKeyRef=slave-secret
mysqlimage=$3
configmap=$4 
size=$5

echo "
apiVersion: apps/v1
kind: StatefulSet
metadata:
  annotations:
  name: slave-${service_name}
  namespace: ${namespace}
spec:
  podManagementPolicy: OrderedReady
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: slave-${service_name}
  serviceName: slave-${service_name}
  template:
    metadata:
      annotations:
        prometheus.io/path: /metrics
        prometheus.io/port: \"9104\"
        prometheus.io/scrape: \"true\"
      creationTimestamp: null
      labels:
        app: slave-${service_name}
    spec:
      containers:
      - env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-root-password
              name: slave-secret
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              key: mysql-sys-repl
              name: slave-secret
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-sys-repl-pass
              name: slave-secret
        image: ${mysqlimage}
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -ec
            - mysqladmin -uroot -p\${MYSQL_ROOT_PASSWORD} ping
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: mysql
        ports:
        - containerPort: 3306
          name: mysql-port
          protocol: TCP
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -ec
            - mysql -h127.0.0.1 -uroot -p\${MYSQL_ROOT_PASSWORD} -e \"SELECT 1\"
          failureThreshold: 3
          initialDelaySeconds: 5
          periodSeconds: 2
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          requests:
            cpu: 1
            memory: 4Gi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/lib/mysql
          name: mysql-data
          subPath: mysql
        - mountPath: /etc/mysql/conf.d
          name: config-map
      - args:
        - --collect.binlog_size
        - --collect.engine_innodb_status
        - --collect.global_status
        - --collect.global_variables
        - --collect.info_schema.innodb_metrics
        - --collect.info_schema.processlist
        - --collect.info_schema.processlist.min_time
        - \"0\"
        - --collect.info_schema.query_response_time
        - --collect.slave_hosts
        env:
        - name: DATA_SOURCE_NAME
          value: exporter:MCzTabsdYCgm@(localhost:3306)/
        image: harbor.cloudminds.com/library/mysqld-exporter:master
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 9104
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        name: prometheus-mysql-exporter
        ports:
        - containerPort: 9104
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 9104
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          limits:
            cpu: 200m
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 128Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: conf
      - configMap:
          defaultMode: 420
          name: ${configmap}
        name: config-map
  updateStrategy:
    rollingUpdate:
      partition: 0
    type: RollingUpdate
  volumeClaimTemplates:
  - metadata:
      creationTimestamp: null
      name: mysql-data
    spec:
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: ${size}Gi
      storageClassName: gfs-sc-one-replica
    status:
      phase: Pending
">${namespace}.${service_name}.yaml
echo "successful:${namespace}.${service_name}.yaml"
