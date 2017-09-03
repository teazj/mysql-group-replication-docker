## mysql mgr docker环境


## 初始化数据库
	chown -R mysql:mysql /data/s1
	[ -d /data/s1 ] && /usr/sbin/mysqld --initialize-insecure --user=mysql --basedir=/usr/sbin --datadir=/data/s1
	/usr/sbin/mysqld --defaults-file=/data/my1.cnf --user=mysql 2>&1 &>/dev/null &

## mysql主设置
	SET SQL_LOG_BIN=0;
	CREATE USER rpl_user@'%';
	GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%' IDENTIFIED BY 'rpl_pass';
	SET SQL_LOG_BIN=1;
	CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='rpl_pass' FOR CHANNEL 'group_replication_recovery';
	INSTALL PLUGIN group_replication SONAME 'group_replication.so';
	SHOW PLUGINS;
	SET GLOBAL group_replication_bootstrap_group=ON;
	START GROUP_REPLICATION;
	SET GLOBAL group_replication_bootstrap_group=OFF;
	SELECT * FROM performance_schema.replication_group_members;



## 从库设置
	SET SQL_LOG_BIN=0;
	CREATE USER rpl_user@'%';
	GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%' IDENTIFIED BY 'rpl_pass';
	SET SQL_LOG_BIN=1;
	CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='rpl_pass' FOR CHANNEL 'group_replication_recovery';
	INSTALL PLUGIN group_replication SONAME 'group_replication.so';
	START GROUP_REPLICATION;
	SELECT * FROM performance_schema.replication_group_members;



## HA测试
	global
	    log 127.0.0.1   local3
	    maxconn 4096
	    user haproxy
	    group haproxy
	    daemon
	    debug

	listen mysql 0.0.0.0:3306
	    mode tcp
	    log global
	    retries 3
	    timeout connect 5000000000000ms
	    option redispatch
	    timeout client 2000000000000000ms
	    timeout server 200000000000000000ms
	    option tcplog
	    option clitcpka
	#    balance leastconn
	    balance roundrobin
	    server  S1 127.0.0.1:3316  check inter 2000 rise 2 fall 5 weight 5
	    server  S2 127.0.0.1:3326  check inter 2000 rise 2 fall 5 weight 5
	    server  S3 127.0.0.1:3336  check inter 2000 rise 2 fall 5 weight 5



## 查看轮询到那太服务器上
	mysql -h 127.0.0.1 -P 3306 -e "select @@PORT"


## 设置变量general_log以开启通用查询日志
	set @@global.general_log=1;
	set global general_log=1;


## 数据库操作
	update mysql.user set authentication_string=password('12wsxCDE#') where user='root' and Host = 'localhost';
	CREATE DATABASE IF NOT EXISTS test default charset utf8 COLLATE utf8_general_ci;
	use test;
	CREATE TABLE `t3` (
	  `id` int(30) unsigned NOT NULL AUTO_INCREMENT,
	  `name` char(30) NOT NULL COMMENT 'name',
	  `sex` char(30) NOT NULL COMMENT 'sex',
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

	use test;
	insert into t3(name,sex) values('t1',11);


## 添加数据
	ab -c 5 -n 9999 http://localhost/update.php

## 查看数据
	ab -c 5 -n 9999 http://localhost/index.php

## 查看数据操作日志
	tail -f data/s3/mgr.log  | grep -v "COMMIT" | grep -v "BEGIN"


## 手动提交事务
	set autocommit=0;
	insert into test set name='123' where id=1;
	commit;


## 开始事务
	start transaction;
	update test set name="123" where id=1;
	commit;


## 技术交流
	QQ：58847393