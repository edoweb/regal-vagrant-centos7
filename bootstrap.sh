#!/usr/bin/env bash

source /vagrant/variables.conf

function download(){
	cd $BIN
	filename=$1
	url=$2
	if [ -f $filename ]
	then
	    echo "$filename is already here! Stop downloading!"
	else
	    wget $server$url
	fi
	cd -
}

function downloadBinaries(){
	download typesafe-activator-1.3.5.zip http://downloads.typesafe.com/typesafe-activator/1.3.5/
	download fcrepo-installer-3.7.1.jar http://sourceforge.net/projects/fedora-commons/files/fedora/3.7.1/
	download mysql-community-release-el7-5.noarch.rpm http://repo.mysql.com/
	download elasticsearch-1.1.0.noarch.rpm https://download.elastic.co/elasticsearch/elasticsearch/
	download heritrix-3.1.1-dist.zip http://builds.archive.org/maven2/org/archive/heritrix/heritrix/3.1.1/
        download apache-tomcat-8.0.23.zip http://ftp.halifax.rwth-aachen.de/apache/tomcat/tomcat-8/v8.0.23/bin/
	download drupal-7.36.tar.gz http://ftp.drupal.org/files/projects/
}

function installPackages(){
    sudo yum -y update
    sudo yum -y install epel-release
    sudo yum -y install httpd
    sudo yum -y install git
    sudo yum -y install java-1.8.0-openjdk-devel
    sudo yum -y install maven
    sudo yum -y install wget
    sudo yum -y install curl
    sudo yum -y install emacs
    sudo yum -y install unzip
    
    
    yes|sudo rpm -ivh /vagrant/mysql-community-release-el7-5.noarch.rpm
    yum update -y
    sudo yum -y install mysql-server
    sudo systemctl start mysqld

    
    sudo rpm -i /vagrant/elasticsearch-1.1.0.noarch.rpm
    cd /usr/share/elasticsearch/
    sudo bin/plugin -install mobz/elasticsearch-head
    sudo bin/plugin install elasticsearch/elasticsearch-analysis-icu/2.1.0
    sudo bin/plugin -install com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1
    sudo echo "cluster.name: danrw-dev" > /etc/elasticsearch/elasticsearch.yml

    sudo yum -y install python34 python-pip
    sudo yum -y install drush
    sudo yum -y install php5-librdf
    sudo yum -y install php5-curl
    sudo yum -y install php5-intl
}

function createRegalFolderLayout(){
    sudo mkdir $ARCHIVE_HOME
    sudo chown -R vagrant $ARCHIVE_HOME
    sudo su -l vagrant
    mkdir  $ARCHIVE_HOME/src
    mkdir  $ARCHIVE_HOME/apps
}

function downloadRegalSources(){
    cd $ARCHIVE_HOME/src
    git clone https://github.com/edoweb/regal-api 
    cp /vagrant/application.conf $ARCHIVE_HOME/src/regal-api/conf/application.conf
    git clone https://github.com/edoweb/regal-install
    git clone https://github.com/hbz/thumby
    git clone https://github.com/hbz/etikett
    git clone https://github.com/hbz/zettel
    git clone https://github.com/hbz/skos-lookup
}

function installFedora(){
    /vagrant/configure.sh
    export FEDORA_HOME=$ARCHIVE_HOME/fedora
    java -jar /vagrant/fcrepo-installer-3.7.1.jar  $ARCHIVE_HOME/conf/install.properties
    cp $ARCHIVE_HOME/conf/fedora-users.xml $ARCHIVE_HOME/fedora/server/config/
    cp $ARCHIVE_HOME/conf/setenv.sh $ARCHIVE_HOME/fedora/tomcat/bin
    cp $ARCHIVE_HOME/conf/tomcat-users.xml /opt/regal/fedora/tomcat/conf/
}

function installPlay(){
    cd $ARCHIVE_HOME/src/regal-install
  
    if [ -d $ARCHIVE_HOME/activator-1.3.5 ]
    then
	echo "Activator already installed!"
    else
	unzip /vagrant/typesafe-activator-1.3.5.zip -d $ARCHIVE_HOME 
    fi
}

function postProcess(){
    ln -s  $ARCHIVE_HOME/activator-dist-1.3.5  $ARCHIVE_HOME/activator
    mv  $ARCHIVE_HOME/proai/  $ARCHIVE_HOME/apps
    sudo chown -R vagrant $ARCHIVE_HOME
}

function installRegalModule(){
    VERSION=$1
    APPNAME=$2
    $ARCHIVE_HOME/activator/activator clean
    yes r|$ARCHIVE_HOME/activator/activator dist
    $ARCHIVE_HOME/activator/activator eclipse
    cp target/universal/$VERSION.zip  /tmp
    cd /tmp
    unzip $VERSION.zip
    mv $VERSION  $ARCHIVE_HOME/apps/$APPNAME
}

function installRegalModules(){
    cd  $ARCHIVE_HOME/src/thumby;
    installRegalModule thumby-0.1.0-SNAPSHOT thumby

    cd  $ARCHIVE_HOME/src/skos-lookup
    installRegalModule skos-lookup-1.0-SNAPSHOT skos-lookup

    cd  $ARCHIVE_HOME/src/etikett
    installRegalModule etikett-0.1.0-SNAPSHOT etikett

    cd  $ARCHIVE_HOME/src/zettel
    installRegalModule zettel-1.0-SNAPSHOT zettel

    cd  $ARCHIVE_HOME/src/regal-api
    installRegalModule regal-api-0.8.0-SNAPSHOT  regal-api
}

function configureRegalModules(){
    mysql -u root -Bse "CREATE DATABASE etikett  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;CREATE USER 'etikett'@'localhost' IDENTIFIED BY 'etikett';GRANT ALL ON etikett.* TO 'etikett'@'localhost';"
}

function configureApache(){
    /usr/sbin/setsebool -P httpd_can_network_connect 1
    sed -i "1 s|$| api.localhost|" /etc/hosts
    mkdir /etc/httpd/sites-enabled
    echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
    cp /vagrant/regal.vagrant.conf /etc/httpd/sites-enabled/
}

function installProai(){
	echo "installProai() not implemented yet!"
mysql -u root -Bse " CREATE DATABASE proai; CREATE USER 'proai'@'localhost' IDENTIFIED BY 'proai'; SET PASSWORD FOR 'proai'@'localhost' = PASSWORD('proai'); GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP ON proai.* TO 'proai'@'localhost';"
	cd $ARCHIVE_HOME/src
	git clone https://github.com/jschnasse/proai.git
	git clone https://github.com/jschnasse/oaiprovider.git
	cd proai;
	git checkout dates;
	cd $ARCHIVE_HOME/src/oaiprovider
	git checkout dates;
	cp /vagrant/proai.properties $ARCHIVE_HOME/src/oaiprovider/src/config
	cp /vagrant/Identify.xml $ARCHIVE_HOME/apps/drupal
	cd $ARCHIVE_HOME/src/proai
	ant release
	cp dist/proai-1.1.3-1.jar ../oaiprovider/lib/
	cd $ARCHIVE_HOME/src/oaiprovider
	ant release
	cp dist/oaiprovider.war $ARCHIVE/fedora/tomcat/webapps/oai-pmh.war
}

function installOpenwayback(){
        cd $ARCHIVE_HOME/src/regal-install
	echo "installOpenwayback() not implemented yet!"
	unzip $BIN/apache-tomcat-8.0.23.zip
	mv apache-tomcat-8.0.23 $ARCHIVE_HOME
	ln -s $ARCHIVE_HOME/apache-tomcat-8.0.23 $ARCHIVE_HOME/tomcat-for-openwayback
	#Configure tomcat
	cp templates/openwayback-server.xml $ARCHIVE_HOME/tomcat-for-openwayback/conf/server.xml
	cp templates/setenv.sh $ARCHIVE_HOME/tomcat-for-openwayback/bin
	rm -rf $ARCHIVE_HOME/tomcat-for-openwayback/webapps/ROOT* 
	#Get openwayback code
	cd $ARCHIVE_HOME
	git clone https://github.com/iipc/openwayback.git
	cd -
	cd $ARCHIVE_HOME/openwayback
	#Check out tag
	git checkout tags/openwayback-2.2.0
	#Build openwayback
	mvn package -DskipTests
	#Copy build to tomcat
	cp wayback-webapp/target/openwayback-2.2.0.war $ARCHIVE_HOME/tomcat-for-openwayback/webapps/ROOT.war
	#start tomcat
	chmod u+x $ARCHIVE_HOME/tomcat-for-openwayback/bin/*.sh
	$ARCHIVE_HOME/tomcat-for-openwayback/bin/startup.sh
	cd -
	#copy openwayback config
	sleep 5
	cp templates/wayback.xml $ARCHIVE_HOME/tomcat-for-openwayback/webapps/ROOT/WEB-INF/
	cp templates/BDBCollection.xml $ARCHIVE_HOME/tomcat-for-openwayback/webapps/ROOT/WEB-INF/
	cp templates/CDXCollection.xml $ARCHIVE_HOME/tomcat-for-openwayback/webapps/ROOT/WEB-INF/
	#stop tomcat
	$ARCHIVE_HOME/tomcat-for-openwayback/bin/shutdown.sh
}

function installHeritrix(){
	echo "installHeritrix() not implemented yet!"
	unzip $BIN/heritrix-3.1.1-dist.zip
	mv $BIN/heritrix-3.1.1 $ARCHIVE_HOME/
	ln -s $ARCHIVE_HOME/heritrix-3.1.1 $ARCHIVE_HOME/heritrix
}

function installDeepzoomer(){
	echo "installDeepzoomer() not implemented yet!"
}

function installWpull(){
	#https://blog.teststation.org/centos/python/2016/05/11/installing-python-virtualenv-centos-7/
	pip install -U pip
	pip install -U virtualenv
	virtualenv -p /usr/bin/python3 /opt/regal/python3
	/opt/regal/python3/bin/pip3 install tornado==4.5.3
	/opt/regal/python3/bin/pip3 install html5lib==0.9999999
	/opt/regal/python3/bin/pip3 install wpull
}


function installDrupal(){
	mysql -u root -Bse "CREATE DATABASE drupal;CREATE USER drupal IDENTIFIED BY 'admin';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY 'admin';"
	drush qd --profile=minimal --cache --core=drupal-7.36 --yes --root $ARCHIVE_HOME/drupal --db-su drupal --db-su-pw admin --account-name admin --account-pass admin
}

function installRegalDrupal(){
	cd $ARCHIVE_HOME/drupal/sites/all/modules
	git clone https://github.com/edoweb/regal-drupal.git
	cd regal-drupal
	git submodule update --init
	cd $ARCHIVE_HOME/drupal/sites/all/modules
	curl https://ftp.drupal.org/files/projects/entity-7.x-1.1.tar.gz | tar xz
	curl https://ftp.drupal.org/files/projects/entity_js-7.x-1.0-alpha3.tar.gz | tar xz
	curl https://ftp.drupal.org/files/projects/ctools-7.x-1.3.tar.gz | tar xz
}

function installDrupalThemes(){
	cd $ARCHIVE_HOME/drupal/sites/all/themes
	git clone https://github.com/edoweb/edoweb-drupal-theme.git
	git clone https://github.com/edoweb/edoweb-drupal-theme.git
}

function configureDrupalLanguages(){
	echo "configureDrupalLanguages() not implemented yet!"
}

function configureDrupal(){
	echo "configureDrupal() not implemented yet!"
}


function createStartStopScripts(){
	echo "createStartStopScripts() not implemented yet!"
}

function defineBootShutdownSequence(){
	#sudo update-rc.d tomcat6 defaults 90 27;
	#sudo update-rc.d elasticsearch defaults 91 26;
	#sudo update-rc.d etikett defaults 92 25;
	#sudo update-rc.d zettel defaults 93 24;
	#sudo update-rc.d thumby defaults 93 24 ;
	#sudo update-rc.d tomcat-for-openwayback defaults 94 22;
	#sudo update-rc.d tomcat-for-deepzoom defaults 95 21;
	#sudo update-rc.d regal-api defaults 96 20;
	#sudo chkconfig -add tomcat6 35 90 27
	echo "defineBootShutdownSequence() not implemented yet!"
}

function configureMonit(){
	echo "configureMonit() not implemented yet!"
}

function configureFirewall(){
	echo "configureFirewall() not implemented yet!"
}


function main(){
	downloadBinaries
	installPackages
	createRegalFolderLayout
	downloadRegalSources
	installFedora
	installPlay
	postProcess
	installRegalModules
	installProai
	configureRegalModules
	installOpenwayback
	installHeritrix
	installDeepzoomer
	installWpull
	installDrush
	installDrupal
	installRegalDrupal
	installDrupalThemes
	configureDrupalLanguages
	configureDrupal
	createStartStopScripts
	defineBootShutdownSequence
	configureApache
	configureMonit
	configureFirewall
	sudo chown -R vagrant $ARCHIVE_HOME
}

main
