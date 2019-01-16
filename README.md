# About

This repository provides a working vagrant config to create a centos7 virtualbox with a running regal backend installed.

# Prerequisites

Newest version of vagrant installed. Newest version of virtualbox installed.

# How to
## Install

```
git clone https://github.com/edoweb/regal-vagrant-centos7
cd regal-vagrant-centos7
```

## Start

`vagrant up`

Running the first time this will download a lot of things and can last up to one hour.

## Stop

``vagrant halt``

## Login

``vagrant ssh``

## Remove

``vagrant destroy``

# Inside the box

```
/opt/regal/src
/opt/regal/apps
/opt/regal/activator
/opt/regal/logs
/opt/regal/tmp
/opt/regal/conf
 ```
