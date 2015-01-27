# Puppet module for managing Learning Locker

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with learninglocker](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module will setup all dependencies required by Learning Locker, e.g., PHP, Mongo, etc.

It's tested under CentOS 6.5.

## Module Description

This module have the following components, which can be install on the same or separate servers.
* Web - PHP 5.4, Nginx, Composer, Bower, Learning Locker
* Database - MongoDB
* Cache - Redis

## Setup

    sudo puppet install compass/learninglocker

## Usage

    # web node
    class { 'learninglocker::web':
        server_domain => 'lrs.example.com',
        github_token=>'YOUR_GITHUB_TOKEN'
    }
    # db node
    class { 'learninglocker::db': }
    # cache node
    class { 'learninglocker::cache': }

* The GitHub token is a toke you can generate from your github account. It will give you more API calls 
when downloading modules from github. Otherwise, you may run into limitation when installing the Learning Locker.
* All three nodes can be installed on one server or separate ones.

## Reference

### Classes

#### Public Classes

* `learninglocker::web`: Installs web component of Learning Locker
* `learninglocker::db`: Installs database component of Learning Locker
* `learninglocker::cache`: Installs cache component of Learning Locker

### Parameters

#### learninglocker::web
Learning Locker web role.

##### `server_domain` (required)
The domain name of the server.
##### `$doc_base` (default: "/www_data/learninglocker")
The base location where Learning Locker will be installed to.
##### `default_fqdn` (default: false)
Whether to include the default fqdn on nginx server name.
##### `port` (default: 80)
Learning Locker web server port.
##### `ssl` (default: false)
Whether to enable SSL on web server.
##### `ssl_cert` (default: undef)
Location of the SSL certificate.
##### `ssl_key` (default: undef)
Location of the SSL private key.
##### `ssl_port` (default: 443)
The port for SSL web server.
##### `db_name` (default: 'learninglocker')
The database name used for Learning Locker.
##### `db_username` (default: 'learninglocker')
The username to connect to the database.
##### `db_password` (default: 'learninglocker')
The password to connect to the database.
##### `db_host` (default: 'localhost')
The host/IP of the database.
##### `db_port` (default: 27017)
The port of the database
##### `cache_host` (default: 'localhost')
The host/IP for the cache.
##### `cache_port` (default: 6379)
The port for the cache.
##### `github_token` (default: undef)
The github token. It can be generated from GitHub. See here for more details: https://help.github.com/articles/creating-an-access-token-for-command-line-use/
##### `timezone` (default: 'America/Vancouver')
The timezone set in php.ini.
##### `dev` (default: 'false')
Whether to enable dev mode. E.g. installing dev dependencies.
##### `version` (default: 'master')
The version of Learning Locker to be installed. Can be a release version number, branch name or a commit.

#### learninglocker::db
Learning Locker database role.
##### `port` (default: 27017)
##### `database` (default: 'learninglocker')
##### `username` (default: 'learninglocker')
##### `password` (default: 'learninglocker')

#### learninglocker::cache
Learning Locker cache role.

## Development

### Running tests

#### Spec tests

    rake spec

#### Acceptance tests

    vagrant up

## Contributions

Any pull request is welcome!
