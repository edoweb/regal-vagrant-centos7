#!/usr/bin/env bash

source /vagrant/variables.conf

function installPackages(){
    sudo yum -y update
    sudo yum -y install httpd
    sudo yum -y install git
    sudo yum -y install java-1.8.0-openjdk-devel
    sudo yum -y install maven
    sudo yum -y install wget
    sudo yum -y install curl
    sudo yum -y install emacs
    sudo yum -y install unzip
    
    wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    yes|sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
    yum update -y
    sudo yum -y install mysql-server
    sudo systemctl start mysqld

    wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.1.1.noarch.rpm
    sudo rpm -i elasticsearch-1.1.1.noarch.rpm
    cd /usr/share/elasticsearch/
    sudo bin/plugin -install mobz/elasticsearch-head
    sudo bin/plugin install elasticsearch/elasticsearch-analysis-icu/2.1.0
    sudo bin/plugin -install com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1
    sudo echo "cluster.name:danrw-dev" > /etc/elasticsearch/elasticsearch.yml
}

function createRegalFolderLayout(){
    sudo mkdir $ARCHIVE_HOME
    sudo chown -R vagrant $ARCHIVE_HOME
    sudo su -l vagrant
    mkdir  $ARCHIVE_HOME/src
    mkdir  $ARCHIVE_HOME/apps
}

function downloadRegalSources(){
    cd /opt/regal/src
    git clone https://github.com/edoweb/regal-api 
    git clone https://github.com/edoweb/regal-install
    git clone https://github.com/hbz/thumby
    git clone https://github.com/hbz/etikett
    git clone https://github.com/hbz/zettel
    git clone https://github.com/hbz/skos-lookup
}

function installFedora(){
    cd $ARCHIVE_HOME/src/regal-install
    cp /vagrant/variables.conf .
    ./configure.sh
    ./install-fedora.sh
}

function installPlay(){
    cd $ARCHIVE_HOME/src/regal-install
    ./install-play.sh
}

function postProcess(){
    ln -s  $ARCHIVE_HOME/activator-dist-1.3.5  $ARCHIVE_HOME/activator
    mv  $ARCHIVE_HOME/fedora  $ARCHIVE_HOME/apps
    mv  $ARCHIVE_HOME/proai/  $ARCHIVE_HOME/apps
    rm -rf  $ARCHIVE_HOME/sync
    sudo chown -R vagrant $ARCHIVE_HOME
}

function installRegalModule(){
    VERSION=$1
    APPNAME=$2
    $ARCHIVE_HOME/activator/activator clean
    $ARCHIVE_HOME/activator/activator dist
    cp target/universal/$VERSION.zip  /tmp
    cd /tmp
    unzip $VERSION.zip
    mv $VERSION  $ARCHIVE_HOME/apps/$APPNAME
}

function installRegalModules(){
    cd  $ARCHIVE_HOME/src/thumby;
    installRegalModule thumby-0.1.0-SNAPSHOT thumby

    cd  $ARCHIVE_HOME/src/skos-lookup
    installRegalModule skos-lookup-0.1.0-SNAPSHOT skos-lookup

    cd  $ARCHIVE_HOME/src/etikett
    installRegalModule etikett-0.1.0-SNAPSHOT etikett

    cd  $ARCHIVE_HOME/src/zettel
    installRegalModule zettel-1.0-SNAPSHOT zettel

    cd  $ARCHIVE_HOME/src/regal-api
    installRegalModule regal-api-0.8.0-SNAPSHOT  regal-api
}

function configureRegalModules(){
    mysql -u root -Bse "CREATE DATABASE etikett  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;CREATE USER 'etikett'@'localhost' IDENTIFIED BY 'etikett';GRANT ALL ON etikett.* TO 'etikett'@'localhost';"
    sudo chown -R vagrant $ARCHIVE_HOME
}

function startRegalModules(){
    $ARCHIVE_HOME/apps/fedora/tomcat/bin/startup.sh
    nohup $ARCHIVE_HOME/apps/thumby/bin/thumby -Dconfig.file=$ARCHIVE_HOME/apps/thumby/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9001 &
    nohup $ARCHIVE_HOME/apps/etikett/bin/etikett -Dconfig.file=$ARCHIVE_HOME/apps/etikett/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9002 &
    nohup $ARCHIVE_HOME/apps/skos-lookup/bin/skos-lookup -Dconfig.file=$ARCHIVE_HOME/apps/skos-lookup/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9004 &
    nohup $ARCHIVE_HOME/apps/zettel/bin/zettel -Dconfig.file=$ARCHIVE_HOME/apps/zettel/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9003 &
    nohup $ARCHIVE_HOME/apps/regal-api/bin/regal-api -Dconfig.file=$ARCHIVE_HOME/apps/regal-api/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9100 &
}


installPackages
createRegalFolderLayout
downloadRegalSources
installFedora
installPlay
postProcess
installRegalModules
configureRegalModules
startRegalModules
