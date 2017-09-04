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

## 添加节点
	set global group_replication_group_seeds="172.22.0.6:3301,172.22.0.7:3302,172.22.0.8:3303"
	show variables like '%group_replication_group_seeds%';


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

## 详解

	group replication是MySQL官方开发的一个开源插件，是实现MySQL高可用集群的一个工具。第一个GA版本正式发布于MySQL5.7.17中；想要使用group replication只需要从官网上下载MySQL5.7.17及以后的版本即可

	group replication发布以后，有3种方法来实现MySQL的高可用集群：

	①：异步复制

	②：半同步复制

	③：group replication



	---注意：

	  异步复制是实现最早也是最简单的高可用方法。相比异步复制而言，半同步复制提高了MySQL集群的可靠性。group replication则是MySQL复制今后发展的方向，与前两者相比，不仅是可靠性更好，在易用性上也有巨大提高；



	1、组的概念：

	    group replication插件中有组（group）的概念，被group replication插件连接在一起的MySQL服务器是一个高可用组，组内的MySQL服务器被称为成员。组的概念贯穿与group replication的使用和内部实现之中。group replication内部集成了组管理服务，实现了很多组内成员的自动化管理功能，这使得group replication的使用和管理变得非常简单。

	用户对group replication组的管理有三种操作，分别如下：

	①：创建组：当组的第一个成员启动时，需要对组进行初始化

	②：加入组：将MySQL服务器加入到一个村子的group replication组内

	③：离开组：从一个group replication组内移除一台MySQL服务器；



	---当组初始化后，组的第一个成员会自动成为master，新加入的成员会自动从组内的master上复制数据。这些使用到的通道由group replication插件自动控制，不需要用户的干预。特别是当MySQL服务器出现故障需要做切换的时候，选择新的master之后，整个切换过程会自动完成，不必像主从那样使用命令手动来完成切换；



	2、多主复制：

	   group replication支持像异步、半同步复制一样可以做一主多从的复制，group replication称为单主复制。除此之外，group replication还提供了一种更高级的复制技术，叫 多主复制。在多主模式下，所有成员同时对外提供的读写服务都是master，彼此之间会自动进行数据复制。这是一种真正意义的多主并发复制，用户可以向一个MySQL上更新数据一样，并发的多个成员上更新数据。group replication插件能够将这些并发事务的更新操作同步到每个成员上，使他们数据保持一致；



	2.1、多主复制的优势：

	①：当一个成员发生故障时，只会造成一部分连接失效，对应用程序的影响会小一些；

	②：当需要关闭某个MySQL服务器时，可以先将其上的连接平滑的转移到其他成员上后关闭这个成员，不会造成应用的瞬时中断；

	③：多主模式的性能很好，对瞬时的高并发有着很好的承载能力；



	3、group replication在传输数据时，使用了paxos协议。

	   paxos协议保证了数据传输的一致性和原子性。group replication基于paxos协议构建了一个分布式的状态复制机制，这是实现多主复制的核心技术。这个技术为group replication带来3个主要优点，如下：

	①：group replication中不会出现脑裂现象

	②：group replication的冗余能力很好，能够保证binlog event至少被复制到超过一半的成员上，只要同时宕机的成员不超过半数就不会导致数据丢失；

	③：group replication还保证只要binlog event没被传输到半数以上的成员，本地成员不会将事务的binlog event写入binlog文件和提交事务，从而保证宕机的服务器上不会有组内在线成员上不存在的数据。因此宕机的服务器重启后，不再需要特殊的处理就可以加入组；



	4、group replication服务模式：

	group replication组对外提供服务的时候有2种服务模式：单主模式    多主模式 



	4.1、单主模式：

	  单主模式下只有一个成员提供更新服务，其他成员只提供查询服务。提供更新服务的成员叫做 主成员，只提供查询服务的叫做 从成员。group replication的单主模式是异步复制和半同步复制的替代方案。单主复制模式的特点如下：

	①：主成员的自动选取和切换：

	  单主模式下，组内的成员会自动选举出主成员。初始化时，被初始化的成员自动选举为主成员，其他成员称为从成员。当主成员出现故障的时候，会从组内的其他成员选出一个新的主成员。选取的方法就是对所有在线的成员的UUID进行排序，然后选取UUID最小的成员作为主成员；

	  在任何一个成员的服务器上都能使用命令查看主成员的UUID：

	  show global status like "group_replication_primary_member"; 或 select * from performance_schema.global_status where variable_name='group_replication_primary_member';



	②：读写模式的自动切换：

	  当一个成员加入组时，group replication插件会自动将MySQL变成只读模式，只有被选取为主成员后才会自动切换回读写模式。对MySQL只读模式的控制是通过下面的sql语句进行的：

	  set global super_read_only=1;

	  set global super_read_only=0;



	注意：当主成员故障时，组内会自动选出新的主成员，复制也能正常进行。因此组内的failover是完全自动化的，不需要用户干预；





	4.2、多主模式：

	   多主模式下，组中所有的成员同时对外提供查询和更新服务，且没有主从之分，成员之间是完全对等的。客户端连接到任何一个成员上，都能进行读写操作，就好像在操作同一个MySQL服务器；

	①：自增段的处理：

	  当使用多主模式时，需要设置autoincrement相关的参数来保证自增字段在每个成员上产生不同的值。group replication提供了两种配置方式，分别如下：

	  “直接配置MySQL的系统变量”：set global auto_increment_offset=N;  set global auto_increment_increment=N;

	  “通过group replication插件来配置”：set group_replication_auto_increment_increment=N; (默认值是7，一般不用修改)



	注意：在实践中，server_id  最好是使用：1,2,3，之类的自增值，如果不是，就需要手动来配置MySQL的自增变量；（auto_increment_increment代表段的大小，自增字段的大小依赖于group replication组中成员的多少。auto_increment_increment最小要等于group replication组内成员的数量。如果段的大小等于组内成员的数量，则所有的自增值都会被使用）



	②：多主模式的限制：

	不支持串行的隔离级别。单个MySQL服务器中，通过锁的方式来实现串行化的隔离级别。而多主模式时，多个成员之间的并发操作无法通过锁来实现串行的隔离级别；

	不支持外键的级联操作；

	参数：group_replication_enforce_update_everywhere_checks=TRUE 是用来控制是否做以上限制的检测，如果开启了这个参数，当发现这些情况时就会报错；



	③：DDL语句并发执行问题：

	MySQL5.7上的DDL不是原子操作无法回滚，因此group replication没有对DDL做冲突检测。换句话说，DDL语句不会和其他任何语句冲突（包括DML和DDL）。如果DDL和有冲突的语句在不同的成员上同时执行，可能导致错误或数据不一致；



	④：使用多主模式的条件：

	应用或中间件要能够把写请求分发到多个成员上

	要能够控制DDL的使用，当DDL要执行时，能够把所有的写请求转移到同一台MySQL上去执行；



	注意：group replication将单主模式设为了默认模式。如果要使用多主模式，则需要在加入组前将这个变量设置为OFF。服务模式是不能在线切换的，必须使组内的所有成员退出组，然后重新初始化组为要使用的服务模式，再把其他成员加进来；

	set global group_replication_single_primary_mode=OFF;



	5、binlog event的多线程执行：

	5.1、group_replication_applier通道：

	   group replication插件会自动创建一个通道来执行接收到的binlog event，通道的名字是group_replication_applier。当加入组是，group replication插件会自动启动group_replication_applier通道的执行线程。如果用户需要调整group_replication_applier执行线程的参数，

	也可以手动停止和启动这个通道的执行线程，操作命令如下：

	start slave sql_thread  for  channel 'group_replication_applier';

	stop slave sql_thread  for  channel 'group_replication_applier';



	5.2、基于主键的并行执行：

	group replication中的binlog event的执行也支持多线程并行执行，配置方法：

	set global slave_parallel_type='logical_clock';

	set global slave_parallel_workers=N;

	set global slave_preserve_commit_order=ON;



	---注意：

	  group replication的并行复制算法和异步复制中的 logical_clock算法并不相同。group replication并发策略中的逻辑时间是基于主键计算出来的，比异步复制基于锁计算出来的逻辑时间的并发性能要好很多。

	基于主键的并发复制有以下两个 特点：

	①：如果两个事物更新了同一行数据，则要按顺序执行，否则，就可以并发执行；

	②：DDL不能和任何事物并发执行，必须等待它前门的所有事务执行完毕后才能开始执行。后面的事务也必须要等待DDL执行完毕后，才能开始执行；

	注意：为了保证同一个session中的事务按照同样的顺序提交，group replication在开启并行复制时，要求必须设置slave_preserve_commit_order的值为ON;



 

## 技术交流
	QQ：58847393
