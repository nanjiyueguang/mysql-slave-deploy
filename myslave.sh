#!/bin/bash
# made by wsl 

function reportLog(){
echo "[`date "+%Y-%m-%d %T"`] $@"
}
export -f reportLog

function slavecm(){
local v_namespace=$1
local v_cm=$2
local v_service=$3
local cmdir=${v_namespace}
kubectl get cm ${v_cm} -n ${v_namespace} -o yaml > ${cmdir}/slave_${v_service}.yaml
reportLog "slave cm file is ${cmdir}/slave_${v_service}.yaml"

sed -i s/'name:.*'/"name: slave-${v_service}"/g ${cmdir}/slave_${v_service}.yaml
sed -i 's/server_id.*/server_id=2002/g' ${cmdir}/slave_${v_service}.yaml
sed -i 's/server-id.*/server_id=2020/g' ${cmdir}/slave_${v_service}.yaml
sed -i 's/expire_logs_days.*/expire_logs_days=7/g' ${cmdir}/slave_${v_service}.yaml
sed -i 's/log-bin.*/log-bin=mysql-slave-bin/g' ${cmdir}/slave_${v_service}.yaml
sed -i 's/max_binlog_size.*/max_binlog_size=100M/g' ${cmdir}/slave_${v_service}.yaml
sed -i s/creationTimestamp.*//g ${cmdir}/slave_${v_service}.yaml
sed -i s/resourceVersion.*//g ${cmdir}/slave_${v_service}.yaml
sed -i s/selfLink.*//g ${cmdir}/slave_${v_service}.yaml
sed -i s/uid.*//g ${cmdir}/slave_${v_service}.yaml
sed -i s/annotations:.*//g ${cmdir}/slave_${v_service}.yaml
sed -i "/^[[:space:]]*$/d" ${cmdir}/slave_${v_service}.yaml

## /**
##add the no exists variables like :
##	log_slave_updates 
##
##
if ! grep -i "log_slave_updates" ${cmdir}/slave_${v_service}.yaml >/dev/null
  then
    sed -i '/\[mysqld\]/a\    log_slave_updates = on' ${cmdir}/slave_${v_service}.yaml
fi

}



function mastercm(){
local v_namespace=$1
local v_cm=$2
local v_service=$3
local cmdir=${v_namespace}
kubectl get cm ${v_cm} -n ${v_namespace} -o yaml > ${cmdir}/master_${v_service}.yaml
reportLog "new master cm file is ${cmdir}/master_${v_service}.yaml"

sed -i 's/server_id.*/server_id=1/g' ${cmdir}/master_${v_service}.yaml
sed -i 's/expire_logs_days.*/expire_logs_days=7/g' ${cmdir}/master_${v_service}.yaml
sed -i 's/log-bin.*/log-bin=mysql-master-bin/g' ${cmdir}/master_${v_service}.yaml
}


function modifySecret(){
dir=./
namespace=$1
sed -i "s/namespace:.*/namespace: ${namespace}/g" $dir/my.secret
cp $dir/my.secret ${namespace}/my.secret
}

_main(){
if [ $# -ne 3 ];then
    echo 'eg. ./myslave.sh {namespace} {cm} {service}'
    exit 0;
fi
# input vars:
v_namespace=$1
v_cm=$2
v_service=$3
# cm yaml file :slave_{service}.yaml
if [ ! -d ${v_namespace} ];
then
    mkdir -pv ${v_namespace} | xargs -I{} bash -c 'reportLog {}'
fi

slavecm ${v_namespace} ${v_cm} ${v_service}
mastercm ${v_namespace} ${v_cm} ${v_service}
modifySecret ${v_namespace}
}

_main $@
