#!/usr/bin/env bash

source /vagrant/variables.conf

function cleanUp(){
kill `cat $ARCHIVE_HOME/apps/regal-api/RUNNING_PID`
kill `cat $ARCHIVE_HOME/apps/zettel/RUNNING_PID`
kill `cat $ARCHIVE_HOME/apps/skos-lookup/RUNNING_PID`
kill `cat $ARCHIVE_HOME/apps/etikett/RUNNING_PID`
kill `cat $ARCHIVE_HOME/apps/thumby/RUNNING_PID`
$ARCHIVE_HOME/apps/fedora/tomcat/bin/shutdown.sh
rm $ARCHIVE_HOME/apps/regal-api/RUNNING_PID
rm $ARCHIVE_HOME/apps/zettel/RUNNING_PID
rm $ARCHIVE_HOME/apps/skos-lookup/RUNNING_PID
rm $ARCHIVE_HOME/apps/etikett/RUNNING_PID
rm $ARCHIVE_HOME/apps/thumby/RUNNING_PID
}

function startRegalModules(){
$ARCHIVE_HOME/apps/fedora/tomcat/bin/startup.sh
    nohup $ARCHIVE_HOME/apps/thumby/bin/thumby -Dconfig.file=$ARCHIVE_HOME/apps/thumby/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9001 &
    nohup $ARCHIVE_HOME/apps/etikett/bin/etikett -Dconfig.file=$ARCHIVE_HOME/apps/etikett/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9002 &
    nohup $ARCHIVE_HOME/apps/skos-lookup/bin/skos-lookup -Dconfig.file=$ARCHIVE_HOME/apps/skos-lookup/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9004 &
    nohup $ARCHIVE_HOME/apps/zettel/bin/zettel -Dconfig.file=$ARCHIVE_HOME/apps/zettel/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9003 &
    nohup $ARCHIVE_HOME/apps/regal-api/bin/regal-api -Dconfig.file=$ARCHIVE_HOME/apps/regal-api/conf/application.conf -Dapplication.secret=`uuidgen` -Dhttp.port=9100 &
}

cleanUp
startRegalModules

