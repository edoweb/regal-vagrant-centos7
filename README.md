# About

This repository provides a working vagrant config to create a centos7 virtualbox with a running regal backend installed. If fully installed, all regal endpoints can be made available under `https://api.localhost` on your host machine. 
The virtualbox will autmoatically provide the source code of all running regal components in a shared folder together with eclipse project files. You can import those projects directly to your eclipse IDE on your host system. 
**Settings**
hdd 40GB
cpu 2core
ram 2048G

# Prerequisites

Newest version [of vagrant](https://www.vagrantup.com/downloads.html) installed. Current version of virtualbox installed.

e.g.

```
sudo apt-get install virtualbox
```
e.g.
```
cd /tmp
wget https://releases.hashicorp.com/vagrant/2.2.3/vagrant_2.2.3_x86_64.deb
sudo dpkg -i vagrant_2.2.3_x86_64.deb
```

# How to

## Install

First create a directory for your vagrant guest to share some folders. The standard path for the shared folder is defined in the `Vagrantfile` by ` config.vm.synced_folder "~/regal-dev", "/opt/regal/src",type: "virtualbox"`. So please make sure that the path `~/regal-dev` exists.
```
mkdir ~/regal-dev
```
Now, check out this repo at any location. And install the vagrant `vbguest` additions.
```
git clone https://github.com/edoweb/regal-vagrant-centos7
cd regal-vagrant-centos7
vagrant plugin install vagrant-vbguest && vagrant reload
```

It is recommended to download some third party packages into the vagrant directory before proceeding with `vagrant up`
```
wget http://downloads.typesafe.com/typesafe-activator/1.3.5/typesafe-activator-1.3.5.zip
wget http://sourceforge.net/projects/fedora-commons/files/fedora/3.7.1/fcrepo-installer-3.7.1.jar
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.1.0.noarch.rpm
```

## Start

`vagrant up`

Running the first time this will download a lot of things and can last up to one hour. 

### Enter the box

`vagrant ssh`

and start all Regal applications with

```
/vagrant/start-regal.sh
```
### First Time

1. As soon as all services are up and runnig. Configure the rdf handling of regal-api by executing the following two commands:

```
vagrant ssh
curl -uadmin:admin -XPOST -F"data=@/opt/regal/src/regal-api/conf/labels.json" -F"format-cb=Json" http://api.localhost/tools/etikett -i -L
curl -uedoweb-admin:admin -XPOST http://api.localhost/ontext.json
```
2. Insert a first object

```
curl -i -uedoweb-admin:admin -XPUT http://api.localhost/resource/danrw:1234 -d'{"type":"monograph","accessScheme":"public"}' -H'content-type:application/json'
```
Create child object
```
curl -i -uedoweb-admin:admin -XPUT http://api.localhost/resource/danrw:1235 -d'{"parentPid":"danrw:1234","type":"file","accessScheme":"public"}' -H'content-type:application/json'
```
Add data to file object

```
curl -uedoweb-admin:admin -F"data=@/opt/regal/src/regal-api/test/resources/test.pdf;type=application/pdf" -XPUT http://api.localhost/resource/danrw:1235/data
```
Add Metadata to parent object

```
 curl -uedoweb-admin:admin -XPOST "http://api.localhost/utils/lobidify/danrw:1234?alephid=HT018920238"
```

## Stop

``vagrant halt``

## Login

``vagrant ssh``

## Remove

``vagrant destroy``

# Accessing the box

Several port forwards are enabled. 

```
8080 --> 8080 tomcat/fedora 
9200 --> 9200 elasticsearch 
9001 --> 9001 thumby
9002 --> 9002 etikett
9003 --> 9003 zettel
9004 --> 9004 skos-lookup
9100 --> 9005 regal-api
```

# Inside the box

You can use `vagrant ssh` to login to the box

You will find:

```
/opt/regal/src
/opt/regal/apps
/opt/regal/activator
/opt/regal/logs
/opt/regal/tmp
/opt/regal/conf
 ```

# Development

## IDE & GIT

By default vagrant will share the `/opt/regal/src` directory at the guest system to `~/regal-dev`. the content is

```
etikett
regal-api
regal-install
skos-lookup
thumby
zettel
```

You can import all of these projects into your eclipse IDE. All projects are version controlled by git. 

## Apache config

For development it is recommended to provide a proper apache config on your host. A standard config for an ubuntu apache installation is included in the repo. To use the configuration you have to add `api.localhost` to your `/etc/hosts` config.

```
127.0.0.1	localhost api.localhost

``` 

I use the following entries to provide all regal functionalities via my apache2 webserver at the host. 

Standard address for regal-api is `http://api.localhost`.

```
<VirtualHost *:80>
    ServerName api.localhost
    ServerAlias api.localhost
    ServerAdmin admin@localhost
    LimitRequestBody 0

    <Location "/">
               Options Indexes FollowSymLinks
               Require all granted
	       LimitRequestBody 0
    </Location>

    ProxyPreserveHost On
    RewriteEngine on

    RewriteRule ^/fedora(.*) http://localhost:8080/fedora$1 [P]
    RewriteRule ^/oai-pmh(.*)  http://localhost:8080/oai-pmh$1 [P]
   
    <Proxy http://localhost:9200>
       <Limit POST PUT DELETE>
           order deny,allow
      </Limit>
    </Proxy>
    ProxyPass /search http://localhost:9200
    ProxyPassReverse /search http://localhost:9200

    <Proxy http://localhost:9001/>
       <LimitExcept GET HEAD>
           Require all granted
       </LimitExcept>
    </Proxy>
    ProxyPass /tools/thumby http://localhost:9001/tools/thumby
    ProxyPassReverse /tools/thumby http://localhost:9001/tools/thumby

    <Proxy http://localhost:9002/>
       <LimitExcept GET HEAD>
           Order deny,allow
           Require all granted
       </LimitExcept>
    </Proxy>

    ProxyPass /tools/etikett http://localhost:9002/tools/etikett
    ProxyPassReverse /tools/etikett http://localhost:9002/tools/etikett

    <Proxy http://localhost:9003/>
       <LimitExcept GET HEAD>
           Order deny,allow
           Require all granted
       </LimitExcept>
    </Proxy>

    ProxyPass /tools/zettel http://localhost:9003/tools/zettel
    ProxyPassReverse /tools/zettel http://localhost:9003/tools/zettel

    <Proxy http://localhost:9004/>
       <LimitExcept GET HEAD>
           Order deny,allow
           Require all granted
       </LimitExcept>
    </Proxy>

    ProxyPass /tools/skos-lookup http://localhost:9004/tools/skos-lookup
    ProxyPassReverse /tools/skos-lookup http://localhost:9004/tools/skos-lookup
 
   ProxyPass /public/resources.json http://localhost:9002/tools/etikett/context.json
   ProxyPassReverse /public/resources.json http://localhost:9002/tools/etikett/context.json
  
   <Proxy http://localhost:9100/>
      LimitRequestBody 0
    </Proxy>
   ProxyPass / http://localhost:9100/ Keepalive=On
   ProxyPassReverse / http://localhost:9100/
    
</VirtualHost>
```

# Troubleshooting

If something went wrong during `vagrant up` ,please do the following:

```
cd regal-vagrant-centos7
vagrant destroy
vagrant up 2>&1 | tee regal-vagrant-centos7-install.log
```
Now you can [open an issue](https://github.com/edoweb/regal-vagrant-centos7/issues/new) an attach the install.log to it or just paste relevant parts into it.
