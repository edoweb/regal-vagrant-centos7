#!/usr/bin/env bash

SCRIPT_DIR=/vagrant

source $SCRIPT_DIR/variables.conf

function download(){
	cd $BIN
	filename=$1
	url=$2
	if [ -f $filename ]
	then
	    echo "$filename is already here! Stop downloading!"
	else
	    wget $url$filename
	fi
	cd -
}

function downloadBinaries(){
	download typesafe-activator-1.3.5.zip https://downloads.typesafe.com/typesafe-activator/1.3.5/
	download fcrepo-installer-3.7.1.jar httsp://sourceforge.net/projects/fedora-commons/files/fedora/3.7.1/
	download mysql-community-release-el7-5.noarch.rpm https://repo.mysql.com/
	download elasticsearch-1.1.0.noarch.rpm https://download.elastic.co/elasticsearch/elasticsearch/
	download heritrix-3.1.1-dist.zip http://builds.archive.org/maven2/org/archive/heritrix/heritrix/3.1.1/
	download apache-tomcat-8.5.39.zip http://ftp.halifax.rwth-aachen.de/apache/tomcat/tomcat-8/v8.5.39/bin/
	download drupal-7.36.tar.gz https://ftp.drupal.org/files/projects/
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
    
    
    yes|sudo rpm -ivh $BIN/mysql-community-release-el7-5.noarch.rpm
    yum update -y
    sudo yum -y install mysql-server
    sudo systemctl start mysqld

    
    sudo rpm -i $BIN/elasticsearch-1.1.0.noarch.rpm
    cd /usr/share/elasticsearch/
    sudo bin/plugin -install mobz/elasticsearch-head
    sudo bin/plugin install elasticsearch/elasticsearch-analysis-icu/2.1.0
    sudo bin/plugin -install com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1
    sudo echo "cluster.name: danrw-dev" > /etc/elasticsearch/elasticsearch.yml

    sudo yum -y install python34 python-pip
    sudo yum -y install drush
    sudo yum -y install php
    sudo yum -y install php5-librdf
    sudo yum -y install php5-curl
    sudo yum -y install php5-intl
    sudo yum -y install libapache2-mod-php5 
    sudo yum -y install php5-gd 
    sudo yum -y install php5-common 
    sudo yum -y install php-mysql 
    sudo yum -y install redhat-lsb 
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
    cp $SCRIPT_DIR/application.conf $ARCHIVE_HOME/src/regal-api/conf/application.conf
    git clone https://github.com/edoweb/regal-install
    git clone https://github.com/hbz/thumby
    git clone https://github.com/hbz/etikett
    git clone https://github.com/hbz/zettel
    git clone https://github.com/hbz/skos-lookup
}

function installFedora(){
    $SCRIPT_DIR/configure.sh
    export FEDORA_HOME=$ARCHIVE_HOME/fedora
    java -jar $BIN/fcrepo-installer-3.7.1.jar  $ARCHIVE_HOME/conf/install.properties
    cp $ARCHIVE_HOME/conf/fedora-users.xml $ARCHIVE_HOME/fedora/server/config/
    cp $ARCHIVE_HOME/conf/setenv.sh $ARCHIVE_HOME/fedora/tomcat/bin
    cp $ARCHIVE_HOME/conf/tomcat-users.xml /opt/regal/fedora/tomcat/conf/
}

function installPlay(){  
    if [ -d $ARCHIVE_HOME/activator-1.3.5 ]
    then
	echo "Activator already installed!"
    else
	unzip $BIN/typesafe-activator-1.3.5.zip -d $ARCHIVE_HOME 
    fi
}

function postProcess(){
    ln -s  $ARCHIVE_HOME/activator-dist-1.3.5  $ARCHIVE_HOME/activator
    mv  $ARCHIVE_HOME/proai/  $ARCHIVE_HOME/apps
    sudo chown -R vagrant $ARCHIVE_HOME
}

function installRegalModule(){
    app_version=$1
    APPNAME=$2
    $ARCHIVE_HOME/activator/activator clean
    yes r|$ARCHIVE_HOME/activator/activator dist
    $ARCHIVE_HOME/activator/activator eclipse
    cp target/universal/$app_version.zip  /tmp
    cd /tmp
    unzip $app_version.zip
    if [ -f $$ARCHIVE_HOME/apps/$APPNAME ]
    then
	  rm -rf $ARCHIVE_HOME/apps/$APPNAME
    fi
    mv $app_version  $ARCHIVE_HOME/apps/$APPNAME
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

    mysql -u root -Bse "CREATE DATABASE regal_api DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;CREATE USER 'regal_api'@'localhost' IDENTIFIED BY 'admin';GRANT ALL ON regal_api.* TO 'regal_api'@'localhost';"
}

function configureApache(){
    /usr/sbin/setsebool -P httpd_can_network_connect 1
    sed -i "1 s|$| api.localhost|" /etc/hosts
    mkdir /etc/httpd/sites-enabled
    echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
    cp $SCRIPT_DIR/regal.vagrant.conf /etc/httpd/sites-enabled/
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
	cp $SCRIPT_DIR/proai.properties $ARCHIVE_HOME/src/oaiprovider/src/config
	cp $SCRIPT_DIR/Identify.xml $ARCHIVE_HOME/apps/drupal
	cd $ARCHIVE_HOME/src/proai
	ant release
	cp dist/proai-1.1.3-1.jar ../oaiprovider/lib/
	cd $ARCHIVE_HOME/src/oaiprovider
	ant release
	cp dist/oaiprovider.war $ARCHIVE/fedora/tomcat/webapps/oai-pmh.war
}

function installOpenwayback(){
        cd $ARCHIVE_HOME/src/regal-install
	unzip $BIN/apache-tomcat-8.5.39.zip
	mv apache-tomcat-8.5.39 $ARCHIVE_HOME
	ln -sfn $ARCHIVE_HOME/apache-tomcat-8.5.39 $ARCHIVE_HOME/tomcat-for-openwayback
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
	mv heritrix-3.1.1 $ARCHIVE_HOME/
	ln -s $ARCHIVE_HOME/heritrix-3.1.1 $ARCHIVE_HOME/heritrix
}

function installDeepzoomer(){
	echo "installDeepzoomer() not implemented yet!"
}

function installWpull(){
	#https://blog.teststation.org/centos/python/2016/05/11/installing-python-virtualenv-centos-7/
	sudo pip install -U pip
	sudo pip install -U virtualenv
	sudo virtualenv -p /usr/bin/python3 /opt/regal/python3
	sudo /opt/regal/python3/bin/pip3 install tornado==4.5.3
	sudo /opt/regal/python3/bin/pip3 install html5lib==0.9999999
	sudo /opt/regal/python3/bin/pip3 install wpull
}

function installDrush(){
	sudo yum -y install php-pear
	sudo pear channel-discover pear.drush.org
	sudo pear install drush/drush
	drush version
}

function installDrupal(){
	mysql -u root < /vagrant/drupal-db.sql

	mysql -u root -Bse "CREATE USER drupal IDENTIFIED BY 'admin';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY 'admin';"
	
        
	cd $ARCHIVE_HOME	
	tar -xzf $BIN/drupal-7.36.tar.gz
	ln -s drupal-7.36 $ARCHIVE_HOME/drupal
	chmod a+w $ARCHIVE_HOME/drupal/sites/default
	cp /vagrant/settings.php  $ARCHIVE_HOME/drupal/sites/default/settings.php
	mkdir $ARCHIVE_HOME/drupal/sites/default/files	
        chmod o+w $ARCHIVE_HOME/drupal/sites/default/files
	chcon -R -t httpd_sys_content_rw_t $ARCHIVE_HOME/drupal/sites/default/files/
        chcon -R -t httpd_sys_content_rw_t $ARCHIVE_HOME/drupal/sites/default/settings.php
	sudo setsebool -P httpd_can_sendmail on
	sudo chmod 755 $ARCHIVE_HOME/drupal/sites/default
	sudo chmod 755 $ARCHIVE_HOME/drupal/sites/default/settings.php
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
	git clone https://github.com/edoweb/zbmed-drupal-theme.git
}

function configureDrupalLanguages(){
	echo "configureDrupalLanguages() not implemented yet!"
}

function configureDrupal(){
	echo "configureDrupal() not implemented yet!"
}


function createStartStopScripts(){
	#cp $SCRIPT_DIR/init.d/* /etc/init.d
	#sudo service tomcat6 start;
	#sudo service elasticsearch start;
	#sudo service etikett start;
	#sudo service skos-lookup start;
	#sudo service zettel start;
	#sudo service thumby start;
	#sudo service tomcat-for-openwayback start;
	#sudo service tomcat-for-deepzoom start;
	#sudo service regal-api start;
	echo "Startscripts are not available for centos!"
}

function defineBootShutdownSequence(){
	#sudo update-rc.d tomcat6 defaults 90 27;
	#sudo update-rc.d elasticsearch defaults 91 26;
	#sudo update-rc.d etikett defaults 92 25;
	#sudo update-rc.d skos-lookup defaults 92 25;
	#sudo update-rc.d zettel defaults 93 24;
	#sudo update-rc.d thumby defaults 93 24 ;
	#sudo update-rc.d tomcat-for-openwayback defaults 94 22;
	#sudo update-rc.d tomcat-for-deepzoom defaults 95 21;
	#sudo update-rc.d regal-api defaults 96 20;
	#sudo chkconfig -add tomcat6 35 90 27
	echo "defineBootShutdownSequence() is defined in scripts"
}

function configureMonit(){
	echo "configureMonit() not implemented yet!"
}

function configureFirewall(){
	echo "configureFirewall() not implemented yet!"
}

function initialize(){
	sleep 10
	curl -uadmin:admin -XPOST -F"data=@/opt/regal/src/regal-api/conf/labels.json" -F"format-cb=Json" http://api.localhost/tools/etikett -i -L
	curl -uedoweb-admin:admin -XPOST http://api.localhost/context.json
	curl -i -uedoweb-admin:admin -XPUT http://api.localhost/resource/danrw:1234 -d'{"contentType":"monograph","accessScheme":"public"}' -H'content-type:application/json'
	curl -i -uedoweb-admin:admin -XPUT http://api.localhost/resource/danrw:1235 -d'{"parentPid":"danrw:1234","contentType":"file","accessScheme":"public"}' -H'content-type:application/json'
	curl -uedoweb-admin:admin -F"data=@/opt/regal/src/regal-api/test/resources/test.pdf;type=application/pdf" -XPUT http://api.localhost/resource/danrw:1235/data
	curl -uedoweb-admin:admin -XPOST "http://api.localhost/utils/lobidify/danrw:1234?alephid=HT018920238"
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
	/vagrant/start-regal.sh
	sleep 10
	initialize
}
main
