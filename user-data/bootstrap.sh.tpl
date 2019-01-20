#!/bin/sh
yum update -y
yum install wget unzip -y

### Download & Install JDK from oracle
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.rpm
sudo yum install -y jdk-8u141-linux-x64.rpm

### Set JAVA_HOME
echo "export JAVA_HOME=/usr/java/jdk1.8.0_141" >> /etc/profile
echo "export JRE_HOME=/usr/java/jdk1.8.0_141/jre" >> /etc/profile
echo "export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin" >> /etc/profile
export JAVA_HOME=/usr/java/jdk1.8.0_141
export JRE_HOME=/usr/java/jdk1.8.0_141/jre
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin

### Download & Install Apache Maven
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
sudo yum install -y apache-maven
mvn --version

### Download & Unzip spring_bot.zip from predefined s3 bucket
cd /home/ec2-user
aws --region us-east-1 s3 cp s3://${s3_bucket}/spring_bot.zip .
unzip spring_bot.zip
cd /home/ec2-user/spring_bot/
chmod 755 . -R

### Launching the app
/usr/bin/mvn spring-boot:run -Dspring.config.location=/tmp/application.properties
