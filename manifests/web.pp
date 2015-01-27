# == Class: learninglocker::web
#
# Installs web component of Learning Locker
#
# === Parameters
#
# See readme
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# See readme
#
# === Examples
#
#  class { 'learninglocker::web':
#    $server_domain => 'lrs.example.com',
#  }
#
# === Authors
#
# Pan Luo <pan.luo@ubc.ca>
#
# === Copyright
#
# Copyright 2015 Centre for Teaching, Learning and Technology, UBC, unless otherwise noted.
#
class learninglocker::web (
  $server_domain,
  $doc_base = '/www_data/learninglocker',
  $default_fqdn = false,
  $port = 80,
  $ssl = false,
  $ssl_cert = undef,
  $ssl_key = undef,
  $ssl_port = 443,
  $db_name = 'learninglocker',
  $db_username = 'learninglocker',
  $db_password = 'learninglocker',
  $db_host = 'localhost',
  $db_port = 27017,
  $cache_host = 'localhost',
  $cache_port = 6379,
  $github_token = undef,
  $timezone = 'America/Vancouver',
  $dev = false,
  $version = 'master',
) {

  case $::osfamily {
    'RedHat': {
      case $::operatingsystemrelease {
        /^5.*/,/^6.*/: {
          include ius
          $php_package_prefix = 'php54-'
          $composer_php_package = 'php54-cli'
          $php_require = [Package['nginx'], Class['ius']]
          $manage_nodejs_repo = true
          $nodejs_require = [Yumrepo['epel']]
        }
        /^7.*/: {
          include epel
          $php_package_prefix = 'php-'
          $composer_php_package = 'php-cli'
          $php_require = [Package['nginx'], Yumrepo['epel']]
          $manage_nodejs_repo = false
          $nodejs_require = [Yumrepo['epel']]
        }
        default: {
          fail("Unsupported platform: ${::operatingsystem} ${::operatingsystemrelease}")
        }
      }
      $php_extensions = {
        'pecl-zendopcache' => {
          settings => {
            'OpCache/opcache.enable'      => '1',
            'OpCache/opcache.use_cwd'     => '1',
            'OpCache/opcache.save_comments' => '1',
            'OpCache/opcache.load_comments' => '1',
          }
        },
        'xml' => {},
        'mcrypt' => {},
        'pdo' => {},
        'pecl-mongo' => {},
        'mbstring' => {},
      }
      $nginx_user = 'nginx'
      $nginx_group = 'nginx'
    }
    'Debian': {
      case $::operatingsystemrelease {
        12.04: {
          $manage_nodejs_repo = true
        }
        default: {
          $manage_nodejs_repo = true
        }
      }
      $php_package_prefix = undef
      $php_require = [Package['nginx']]
      $php_extensions = {
        'mcrypt' => {},
        'mongo' => {},
      }
      $nginx_user = 'www-data'
      $nginx_group = 'www-data'
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem} ${::operatingsystemrelease}")
    }
  }

  class { 'firewall': }
  class { 'nodejs':
    manage_repo => $manage_nodejs_repo,
    require     => $nodejs_require,
  }

  # setup nginx
  class { 'nginx': }

  nginx::resource::upstream { 'learninglocker':
    ensure  => present,
    members => [
      '127.0.0.1:9000',
    ],
  }

  # we need an app user to run composer install as bower complains being running as root
  user { 'app':
    ensure  => present,
    groups  => [$nginx_group],
    home    => '/tmp',
    require => Package['nginx'],
  }

  # setup php
  class { 'php':
    ensure         => 'latest',
    fpm            => false,
    composer       => false,
    phpunit        => false,
    dev            => false,
    pear           => false,
    package_prefix => $php_package_prefix,
    extensions     => $php_extensions,
    require        => $php_require,
    settings       => {
        'Date/date.timezone' => $timezone,
    },
  } ->

  # install fpm and create learning locker pool
  class { 'php::fpm':
    ensure => present,
    pools  => {},
  }

  php::fpm::pool { 'learninglocker':
    ensure => present,
    user => $nginx_user,
    group => $nginx_group,
  }

  #class { 'php::fpm':
  #  pools   => {
  #    'learninglocker' => {
  #      user  => 'nginx',
  #      group => 'nginx'
  #    },
  #  },
  #  require => Package['nginx'],
  #} ->

  # remove default pool
  php::fpm::pool { 'www':
    ensure => absent,
  }

  class { 'composer':
    php_package     => $composer_php_package,
    suhosin_enabled => false,
    github_token    => $github_token,
    require => Class['php'],
  }

  package { 'bower':
    ensure   => present,
    provider => 'npm',
    require  => Class['nodejs'],
  }

  # install learning locker application
  $base_dir = dirname($doc_base)
  exec { "create ${base_dir}":
    command => "mkdir -p ${base_dir}",
    creates => $base_dir,
    path    => '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
  }->

  file { $base_dir:
    ensure  => present,
    owner   => 'app',
    mode    => '0755',
    require => User['app'],
  }->

  # hack to make bower insight module happy, it looks for $HOME for current user
  file { '/home/root':
    ensure  => directory,
    owner   => 'app',
    mode    => '0755',
    require => User['app'],
  }->

  # it looks like composer create-project doesn't play well with non-root user installation
#  composer::project { 'learninglocker':
#    project_name => 'learninglocker/learninglocker',
#    target_dir => $doc_base,
#    stability => 'stable',
#    user      => 'app',
#    keep_vcs  => true,
#    dev       => $dev,
#  }->

  vcsrepo { $doc_base:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/LearningLocker/learninglocker.git',
    user     => 'app',
    revision => $version,
  } ->

  composer::exec { 'learninglocker-install':
      cmd         => 'install',
      cwd         => $doc_base,
      scripts     => true,
      timeout     => 0,
      dev         => false,
      prefer_dist => true,
      user        => 'app',
      unless      => "test -f ${doc_base}/vendor/autoload.php",
      require     => Package['bower'],
  } ->

  file { ["${doc_base}/app/storage", "${doc_base}/app/storage/cache",
    "${doc_base}/app/storage/logs", "${doc_base}/app/storage/meta",
    "${doc_base}/app/storage/sessions", "${doc_base}/app/storage/views"]:
    ensure  => directory,
    owner   => $nginx_user,
    mode    => '0775',
    require => Composer::Exec['learninglocker-install']
  }

  file { ["${doc_base}/app/storage/meta/services.json"]:
    ensure  => present,
    owner   => $nginx_user,
    mode    => '0774',
    require => Composer::Exec['learninglocker-install']
  }

  file {"${doc_base}/app/config/database.php":
    ensure  => present,
    content => template('learninglocker/database.php.erb'),
    tag     => $::domain,
    require => Composer::Exec['learninglocker-install']
  }

  file {"${doc_base}/app/config/cache.php":
    ensure  => present,
    content => template('learninglocker/cache.php.erb'),
    tag     => $::domain,
    require => Composer::Exec['learninglocker-install']
  }

  file {"${doc_base}/app/config/session.php":
    ensure  => present,
    content => template('learninglocker/session.php.erb'),
    tag     => $::domain,
    require => Composer::Exec['learninglocker-install']
  }

  $server_name = $default_fqdn ? {
      true  => [$server_domain, $::fqdn],
      false => [$server_domain],
  }
  nginx::resource::vhost {$server_domain:
    ensure               => present,
    www_root             => "${doc_base}/public",
    listen_port          => $port,
    server_name          => $server_name,
    vhost_cfg_prepend    => {
      'add_header' => "X-APP-Server ${::hostname}"
    },
    ssl                  => $ssl,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_port             => $ssl_port,
    use_default_location => false,
    proxy_set_header     => ['Host $host', 'X-Real-IP $remote_addr', 'X-Forwarded-For $proxy_add_x_forwarded_for']
  }

  nginx::resource::location { "php_root_${server_domain}":
    ensure                      => present,
    vhost                       => $server_domain,
    location                    => '/',
    www_root                    => "${doc_base}/public",
    location_custom_cfg_prepend => {
      'if (-f $request_filename)' => '{ break; }',
      'if (-d $request_filename)' => '{ break; }'
    },
    location_custom_cfg_append  => {
      'rewrite' => '^(.+)$ /index.php?url=$1 last;'
    }
  }

  nginx::resource::location { "php_${server_domain}":
    ensure               => present,
    vhost                => $server_domain,
    location             => '~ \.php$',
    fastcgi              => 'learninglocker',
    fastcgi_param        => {
      'SCRIPT_FILENAME' => "${doc_base}/public/\$fastcgi_script_name",
    },
    location_cfg_prepend => {
      fastcgi_read_timeout => 600
    },
  }

  firewall { '100 allow http and https access':
    port   => [$port],
    proto  => tcp,
    action => accept,
  }
}
