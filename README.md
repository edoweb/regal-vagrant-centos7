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

### First Time

```
vagrant plugin install vagrant-vbguest && vagrant reload
```

Running the first time this will download a lot of things and can last up to one hour.

## Stop

``vagrant halt``

## Login

``vagrant ssh``

## Remove

``vagrant destroy``

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