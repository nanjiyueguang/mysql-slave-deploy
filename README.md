#  手工部署MySQL从库

## 使用说明

1. 确认主实例开启binlog

2. 按照现有的pod 创建新的slave pod ， `注意参数一致`

3. 使用一致备份初始化slave 实例

   > 名字类似 XXX.consistent.dump.gz

4. 在主实例创建同步用户

   ```sql
   set sql_log_bin=off; 
   create user user@'%' identified by 'password';
   grant replication slave on *.* to user@'%';		
   ```

5. slave 初始化完成，执行change master

   ```sql
       CHANGE MASTER TO
       MASTER_HOST='XXXX',
       MASTER_USER='user',
       MASTER_PASSWORD='password',
       MASTER_PORT=port,
       MASTER_LOG_FILE='mysql-master-bin.000002', MASTER_LOG_POS=120,
       MASTER_CONNECT_RETRY=10;
   ```


## 脚本说明

>  myslave.sh :  生成主从的concifgmap文件，直接不带参数执行脚本获取帮助
>
>  doslave.sh :  生成deployment yaml文件，直接不带参数执行脚本获取帮助 
>
>  my.secret :  slave实例使用的密码文件，注意修改root密码
>
>  slave-error-restart目录下的文件是自动启动mysql失败的slave用的
>
>  
