#!/usr/bin/env bash

sudo su

set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

PROJ_NAME=celk
PROJ_DIR=/home/vagrant

echo '' >> $PROJ_DIR/.bashrc
echo 'PATH=$PATH:.' >> $PROJ_DIR/.bashrc
source $PROJ_DIR/.bashrc

apt-get update
apt-get install openjdk-7-jdk -y
apt-get install nginx -y
apt-get install git -y
apt-get install expect -y

#apt-get install openssh-server
#apt-get install ssh

#sed -i "s/RSAAuthentication yes/RSAAuthentication yes/g" /etc/ssh/sshd_config
#sed -i "s/PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
#sed -i "s/ChallengeResponseAuthentication no/ChallengeResponseAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM yes/UsePAM no/g" /etc/ssh/sshd_config
sh -c "echo '' >> /etc/ssh/ssh_config"
sh -c "echo '	StrictHostKeyChecking no' >> /etc/ssh/ssh_config"
sh -c "echo '	IdentityFile ~/.ssh/myCert.pem' >> /etc/ssh/ssh_config"

chown -Rf vagrant:vagrant /home/vagrant/.ssh
cd /home/vagrant/.ssh
rm -Rf /home/vagrant/.ssh/id_rsa
ssh-keygen -t rsa -C "dhong@example.com" -f /home/vagrant/.ssh/id_rsa -N ''

openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=SF/L=SF/O=Dis/CN=www.example.com" \
    -key /home/vagrant/.ssh/id_rsa \
    -out /home/vagrant/.ssh/myCert.pem
    
cat id_rsa.pub >> authorized_keys

#openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
#    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.test.com" \
#    -keyout /home/vagrant/.ssh/myCert.key  -out /home/vagrant/.ssh/myCert.pem 

chmod 600 /home/vagrant/.ssh/myCert.pem 

eval `ssh-agent -s`
ssh-add /home/vagrant/.ssh/id_rsa  

service ssh restart

#ssh localhost

#useradd -g staff -d /home/gmonitor -s /bin/bsh -m gmonitor
#sudo passwd gmonitor

cd /home/vagrant
git clone https://github.com/gruter/cloumon-elk.git
cd cloumon-elk

chown -Rf vagrant:vagrant /home/vagrant

sed -i "s/read/#read/g" /home/vagrant/cloumon-elk/sample-installer.sh
sed -i "s/vi env.sh/#vi env.sh/g" /home/vagrant/cloumon-elk/sample-installer.sh

sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/alert/delta-percolate-alert.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/alert/missing-alert.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/alert/percolate-alert.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/elasticsearch-template/config/elasticsearch.yml
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/logstash-template/config/flume-jmx-to-es.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/logstash-template/config/hadoop-jmx-to-es.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/logstash-template/config/hbase-jmx-to-es.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/logstash-template/config/tajo-jmx-to-es.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/logstash-template/config/zookeeper-jmx-to-es.config
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/install
sed -i "s/gmonitor/vagrant/g" /home/vagrant/cloumon-elk/remote-es
#find  . -name \*.* -exec  grep -l gmonitor {} \;

./sample-installer.sh

exit 0;

### [conf nginx] ############################################################################################################
cp /vagrant/resources/nginx/nginx.conf /etc/nginx/nginx.conf
#http {
#    log_format main '$http_host '
#                    '$remote_addr [$time_local] '
#                    '"$request" $status $body_bytes_sent '
#                    '"$http_referer" "$http_user_agent" '
#                    '$request_time '
#                    '$upstream_response_time';
#    access_log  /var/log/nginx/access.log  main;
#}
nginx -s stop
nginx

