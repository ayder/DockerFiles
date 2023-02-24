FROM redhat/ubi8

RUN yum -y install https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm && yum -y install mysql-shell mysql-router


CMD ["bash"]
