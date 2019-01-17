# About

This repository provides a working vagrant config to create a centos7 virtualbox with a running regal backend installed.

# Prerequisites

Newest version of vagrant installed. Newest version of virtualbox installed.

# How to

## Install

```
mkdir ~/regal-dev
git clone https://github.com/edoweb/regal-vagrant-centos7
cd regal-vagrant-centos7
```

## Start

`vagrant up`

Running the first time this will download a lot of things and can last up to one hour.

Enter the box

`vagrant ssh`

and start all Regal applications with

```
/vagrant/start-regal.sh
```

### First Time

To use the folder sync install vbguest additions:

```
vagrant plugin install vagrant-vbguest && vagrant reload
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



