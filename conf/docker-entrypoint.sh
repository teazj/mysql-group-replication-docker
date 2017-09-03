#!/bin/bash
mkdir /data/{s1,s2,s3}
chown -R mysql:mysql /data/s1
chown -R mysql:mysql /data/s2
chown -R mysql:mysql /data/s3
chown mysql:mysql /var/log/mysqld.log
[ -d /data/s1 ] && /usr/sbin/mysqld --initialize-insecure --user=mysql --basedir=/usr/sbin --datadir=/data/s1
[ -d /data/s2 ] && /usr/sbin/mysqld --initialize-insecure --user=mysql --basedir=/usr/sbin --datadir=/data/s2
[ -d /data/s3 ] && /usr/sbin/mysqld --initialize-insecure --user=mysql --basedir=/usr/sbin --datadir=/data/s3
/usr/sbin/mysqld --defaults-file=/data/my1.cnf --user=mysql 2>&1 &>/dev/null &
/usr/sbin/mysqld --defaults-file=/data/my2.cnf --user=mysql 2>&1 &>/dev/null &
/usr/sbin/mysqld --defaults-file=/data/my3.cnf --user=mysql 2>&1 &>/dev/null &
haproxy -f /etc/haproxy/haproxy.cfg

exec $1 $2
