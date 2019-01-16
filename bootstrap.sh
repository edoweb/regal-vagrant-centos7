#!/usr/bin/env bash
sudo yum -y update
sudo yum -y install httpd
sudo yum -y install git
sudo yum -y install java-1.8.0-openjdk-devel
sudo yum -y install maven
sudo yum -y install mysql-server
sudo yum -y install wget
sudo yum -y install curl
sudo yum -y install emacs
sudo yum -y install unzip

#wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.1.1.noarch.rpm
cd /vagrant
sudo rpm -i elasticsearch-1.1.1.noarch.rpm
cd /usr/share/elasticsearch/
sudo bin/plugin -install mobz/elasticsearch-head
sudo bin/plugin install elasticsearch/elasticsearch-analysis-icu/2.1.0
sudo bin/plugin -install com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1

sudo mkdir /opt/regal
sudo chown -R vagrant /opt/regal/
mkdir /opt/regal/src
mkdir /opt/regal/apps

cd /opt/regal/src
git clone https://github.com/edoweb/regal-api
git clone https://github.com/edoweb/regal-install
git clone https://github.com/hbz/thumby
git clone https://github.com/hbz/etikett
git clone https://github.com/hbz/zettel
git clone https://github.com/hbz/skos-lookup

cp /vagrant/start-regal.sh /opt/regal

cd regal-install/
cp /vagrant/variables.conf .
cp /vagrant/fcrepo-installer-3.7.1.jar .
cp /vagrant/typesafe-activator-1.3.5.zip .

./configure.sh
./install-fedora.sh
./install-play.sh

ln -s /opt/regal/activator-dist-1.3.5 /opt/regal/activator


function install(){
VERSION=$1
APPNAME=$2
/opt/activator/bin/activator clean
/opt/activator/bin/activator dist
cp target/universal/$VERSION.zip  /tmp
cd /tmp
unzip $VERSION.zip
mv $VERSION /opt/regal/apps/$APPNAME
}

cd /opt/regal/src/thumby;
install thumby-0.1.0-SNAPSHOT thumby

cd /opt/regal/src/etikett
install etikett-0.1.0-SNAPSHOT etikett

cd /opt/regal/src/zettel
install zettel-0.1.0-SNAPSHOT zettel

cd /opt/regal/src/regal-api
install regal-api-0.1.0-SNAPSHOT regal-api


