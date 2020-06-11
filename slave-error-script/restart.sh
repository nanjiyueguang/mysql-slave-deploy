#!/bin/bash
timestamp=`date +%Y%m%d`
echo "start slave io thread monitor PID: $$" >> /tmp/slave-io-error.log.${timestamp}
while true 
do
echo "INFO: mysql dml status @ `date`" >> /tmp/dml-status.log.${timestamp}
mysql --defaults-file=.my.cnf -Ne "show global status  where Variable_name in ('com_insert','com_update','com_delete');">>/tmp/dml-status.log.${timestamp}
slave_status=`mysql --defaults-file=.my.cnf -e "show slave status \G" |grep Slave_IO_Running|awk '{print $2}'`
if [ $slave_status = 'No' ];then
echo "ERR: slave io thread stoped @ `date` and restarted @ `date`" >> /tmp/slave-status.log.${timestamp}
mysql --defaults-file=.my.cnf -e "show slave status \G" >>/tmp/slave-status.log.${timestamp}
echo -e "\n\n" >>/tmp/slave-status.log.${timestamp}
echo "ERR: slave io thread stoped @ `date` and restarted @ `date`" >> /tmp/slave-io-error.log.${timestamp}
mysql --defaults-file=.my.cnf -e "start slave io_thread;"
fi
sleep 2; 
find /tmp/ -mtime +5 -type d |xargs rm -rf 
done
