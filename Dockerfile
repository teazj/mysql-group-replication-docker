FROM centos:centos7
MAINTAINER  zhang.jian@chinaebi.com
ADD https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-client-5.7.17-1.el7.x86_64.rpm  /build/
ADD https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-common-5.7.17-1.el7.x86_64.rpm  /build/
ADD https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-libs-5.7.17-1.el7.x86_64.rpm   /build/
ADD https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-server-5.7.17-1.el7.x86_64.rpm /build/
RUN yum makecache
RUN yum -y localinstall /build/*.rpm
RUN yum -y install numactl openssh-server php httpd haproxy
COPY conf/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
VOLUME /var/lib/mysql
EXPOSE 3306 22
CMD ["/usr/sbin/sshd","-D"]
