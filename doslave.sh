#!/bin/bash
if [ $# -ne 5 ];then
echo "input sort : namespace service image configmap size_number"
exit 0;
fi
namespace=$1
service=$2
secretKeyRef=slave-secret
mysqlimage=$3
configmap=$4
size=$5
pvcname="pvc-slave-${namespace}-${service}"

echo "
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pvcname}
  namespace: ${namespace}
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: ${size}Gi
  storageClassName: gfs-sc
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: slave-${service}
  name: slave-${service}
  namespace: ${namespace}
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: slave-${service}
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: slave-${service}
    spec:
      containers:
      - env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-root-password
              name: ${secretKeyRef}
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              key: mysql-sys-repl
              name: ${secretKeyRef}
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              key: mysql-sys-repl-pass
              name: ${secretKeyRef}
        image: ${mysqlimage}
        name: slave-${service}
        ports:
        - containerPort: 3306
          name: mysql-port
          protocol: TCP
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - mysqladmin ping -u root -p\${MYSQL_ROOT_PASSWORD}
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - mysqladmin ping -u root -p\${MYSQL_ROOT_PASSWORD}
          failureThreshold: 3
          initialDelaySeconds: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/lib/mysql
          name: mysqldb-data
        - mountPath: /etc/mysql/conf.d
          name: config-map
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - rm
        - -fr
        - /var/lib/mysql/lost+found
        image: busybox:1.25.0
        imagePullPolicy: IfNotPresent
        name: remove-lost-found
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/lib/mysql
          name: mysqldb-data
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - name: mysqldb-data
        persistentVolumeClaim:
          claimName: ${pvcname}
      - configMap:
          defaultMode: 420
          name: ${configmap}
        name: config-map
">${namespace}/new_file.yaml
