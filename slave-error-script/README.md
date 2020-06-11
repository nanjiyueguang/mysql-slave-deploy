# 使用说明

## 首先需要修改密码

执行：`sed -i s/password=.*/password=$MYSQL_ROOT_PASSWORD/g .my.cnf`

## 修改密码之后，后台启动脚本

`nohup ./restart.sh &`

## 检查`/tmp`目录下是否生成文件

```shell
# cd /tmp
# ls 
dml-status.log.20200610  slave-io-error.log.20200610

注意：各版本输出内容可能不一样，有文件说明启动成功，主要关注slave-io-error.log.*文件

```

