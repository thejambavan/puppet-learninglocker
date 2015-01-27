require 'spec_helper'

RSpec.configure do |c|
  c.default_facts = {
    :kernel => 'Linux',
    :concat_basedir => '/',
    :domain => 'lrs.example.com',
  }
end
describe 'learninglocker::web', :type => :class do
  let(:params) { { :server_domain => 'lrs.example.com' }}

  describe 'when called with no parameters on Redhat 6' do
    let(:facts) {{
      :osfamily  => 'Redhat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '6.5',
      :operatingsystemmajrelease => '6',
    }}

    it {
      should contain_class('ius')
      should contain_class('nodejs').with({
        'manage_repo' => true,
      }).that_requires('Yumrepo[epel]')
      should contain_class('nginx')
      should contain_nginx__resource__upstream('learninglocker').with({
        'ensure'  => 'present',
        'members' => [
          '127.0.0.1:9000',
        ],
      })

      should contain_user('app').with({
        'ensure'  => 'present',
        'groups'  => ['nginx'],
        'home'    => '/tmp',
      }).that_requires('Package[nginx]')

      should contain_class('php').with({
        'ensure'         => 'latest',
        'fpm'            => false,
        'composer'       => false,
        'phpunit'        => false,
        'dev'            => false,
        'pear'           => false,
        'package_prefix' => 'php54-',
        'extensions'     => {
          'pecl-zendopcache' => {
            'settings' => {
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
        },
        'settings'       => {
          'Date/date.timezone' => 'America/Vancouver',
        }
      }).that_requires('Package[nginx]')
      .that_requires('Class[ius]')

      should contain_class('php::fpm').with({
        'ensure' => 'present',
        'pools'  => {},
      }).that_requires('Class[php]')

      should contain_php__fpm__pool('learninglocker').with({
        'ensure' => 'present',
        'user'   => 'nginx',
        'group'  => 'nginx',
      })
      should contain_php__fpm__pool('www').with({
        'ensure' => 'absent',
      })

      should contain_class('composer').with({
        'php_package'     => 'php54-cli',
        'suhosin_enabled' => false,
      }).that_requires('Class[php]')

      should contain_package('bower').with({
        'ensure'   => 'present',
        'provider' => 'npm',
      }).that_requires('Class[nodejs]')

      should contain_exec('create /www_data').with({
        'command' => 'mkdir -p /www_data',
      })

      should contain_file('/www_data').with({
        'ensure'  => 'present',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_file('/home/root').with({
        'ensure'  => 'directory',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_vcsrepo('/www_data/learninglocker').with({
        'ensure'   => 'present',
        'provider' => 'git',
        'source'   => 'https://github.com/LearningLocker/learninglocker.git',
        'user'     => 'app',
        'revision' => 'master',
      })

      should contain_composer__exec('learninglocker-install').with({
        'cmd'         => 'install',
        'cwd'         => '/www_data/learninglocker',
        "scripts"     => true,
        "timeout"     => 0,
        "dev"         => false,
        'prefer_dist' => true,
        'user'        => 'app',
        "unless"      => "test -f /www_data/learninglocker/vendor/autoload.php",
      }).that_requires('Package[bower]')

      should contain_file('/www_data/learninglocker/app/storage')
      should contain_file('/www_data/learninglocker/app/storage/cache')
      should contain_file('/www_data/learninglocker/app/storage/logs')
      should contain_file('/www_data/learninglocker/app/storage/meta')
      should contain_file('/www_data/learninglocker/app/storage/sessions')
      should contain_file('/www_data/learninglocker/app/storage/views').with({
        'ensure'  => 'directory',
        'owner'   => 'nginx',
        'mode'    => '0775',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file('/www_data/learninglocker/app/storage/meta/services.json').with({
        'ensure'  => 'present',
        'owner'   => 'nginx',
        'mode'    => '0774',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/database.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/cache.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/session.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')
    }
  end

  describe 'when called with no parameters on Redhat 7' do
    let(:facts) {{
      :osfamily  => 'Redhat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0.1406',
      :operatingsystemmajrelease => '7',
    }}

    it {
      should_not contain_class('ius')
      should contain_class('nodejs').with({
        'manage_repo' => false,
        'require'     => 'Yumrepo[epel]',
      })
      should contain_class('nginx')
      should contain_nginx__resource__upstream('learninglocker').with({
        'ensure'  => 'present',
        'members' => [
          '127.0.0.1:9000',
        ],
      })

      should contain_user('app').with({
        'ensure'  => 'present',
        'groups'  => ['nginx'],
        'home'    => '/tmp',
      }).that_requires('Package[nginx]')

      should contain_class('php').with({
        'ensure'         => 'latest',
        'fpm'            => false,
        'composer'       => false,
        'phpunit'        => false,
        'dev'            => false,
        'pear'           => false,
        'package_prefix' => 'php-',
        'extensions'     => {
          'pecl-zendopcache' => {
            'settings' => {
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
        },
        'settings'       => {
          'Date/date.timezone' => 'America/Vancouver',
        }
      }).that_requires('Package[nginx]')

      should contain_class('php::fpm').with({
        'ensure' => 'present',
        'pools'  => {},
      }).that_requires('Class[php]')

      should contain_php__fpm__pool('learninglocker').with({
        'ensure' => 'present',
        'user'   => 'nginx',
        'group'  => 'nginx',
      })
      should contain_php__fpm__pool('www').with({
        'ensure' => 'absent',
      })

      should contain_class('composer').with({
        'php_package'     => 'php-cli',
        'suhosin_enabled' => false,
      }).that_requires('Class[php]')

      should contain_package('bower').with({
        'ensure'   => 'present',
        'provider' => 'npm',
      }).that_requires('Class[nodejs]')

      should contain_exec('create /www_data').with({
        'command' => 'mkdir -p /www_data',
      })

      should contain_file('/www_data').with({
        'ensure'  => 'present',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_file('/home/root').with({
        'ensure'  => 'directory',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_vcsrepo('/www_data/learninglocker').with({
        'ensure'   => 'present',
        'provider' => 'git',
        'source'   => 'https://github.com/LearningLocker/learninglocker.git',
        'user'     => 'app',
        'revision' => 'master',
      })

      should contain_composer__exec('learninglocker-install').with({
        'cmd'         => 'install',
        'cwd'         => '/www_data/learninglocker',
        "scripts"     => true,
        "timeout"     => 0,
        "dev"         => false,
        'prefer_dist' => true,
        'user'        => 'app',
        "unless"      => "test -f /www_data/learninglocker/vendor/autoload.php",
      }).that_requires('Package[bower]')

      should contain_file('/www_data/learninglocker/app/storage')
      should contain_file('/www_data/learninglocker/app/storage/cache')
      should contain_file('/www_data/learninglocker/app/storage/logs')
      should contain_file('/www_data/learninglocker/app/storage/meta')
      should contain_file('/www_data/learninglocker/app/storage/sessions')
      should contain_file('/www_data/learninglocker/app/storage/views').with({
        'ensure'  => 'directory',
        'owner'   => 'nginx',
        'mode'    => '0775',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file('/www_data/learninglocker/app/storage/meta/services.json').with({
        'ensure'  => 'present',
        'owner'   => 'nginx',
        'mode'    => '0774',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/database.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/cache.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/session.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')
    }
  end

  describe 'when called with no parameters on Ubuntu 12.04' do
    let(:facts) {{
      :osfamily  => 'Debian',
      :operatingsystem => 'Ubuntu',
      :operatingsystemrelease => '12.04',
      :lsbdistid => 'Ubuntu',
      :lsbdistcodename => 'precise',
    }}

    it {
      should_not contain_class('ius')
      should contain_class('nodejs').with({
        'manage_repo' => true,
      })
      should contain_class('nginx')
      should contain_nginx__resource__upstream('learninglocker').with({
        'ensure'  => 'present',
        'members' => [
          '127.0.0.1:9000',
        ],
      })

      should contain_user('app').with({
        'ensure'  => 'present',
        'groups'  => ['www-data'],
        'home'    => '/tmp',
      }).that_requires('Package[nginx]')

      should contain_class('php').with({
        'ensure'         => 'latest',
        'fpm'            => false,
        'composer'       => false,
        'phpunit'        => false,
        'dev'            => false,
        'pear'           => false,
        'extensions'     => {
          'mcrypt' => {},
          'mongo' => {},
        },
        'settings'       => {
          'Date/date.timezone' => 'America/Vancouver',
        }
      }).that_requires('Package[nginx]')

      should contain_class('php::fpm').with({
        'ensure' => 'present',
        'pools'  => {},
      }).that_requires('Class[php]')

      should contain_php__fpm__pool('learninglocker').with({
        'ensure' => 'present',
        'user'   => 'www-data',
        'group'  => 'www-data',
      })
      should contain_php__fpm__pool('www').with({
        'ensure' => 'absent',
      })

      should contain_class('composer').with({
        'suhosin_enabled' => false,
      }).that_requires('Class[php]')

      should contain_package('bower').with({
        'ensure'   => 'present',
        'provider' => 'npm',
      }).that_requires('Class[nodejs]')

      should contain_exec('create /www_data').with({
        'command' => 'mkdir -p /www_data',
      })

      should contain_file('/www_data').with({
        'ensure'  => 'present',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_file('/home/root').with({
        'ensure'  => 'directory',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_vcsrepo('/www_data/learninglocker').with({
        'ensure'   => 'present',
        'provider' => 'git',
        'source'   => 'https://github.com/LearningLocker/learninglocker.git',
        'user'     => 'app',
        'revision' => 'master',
      })

      should contain_composer__exec('learninglocker-install').with({
        'cmd'         => 'install',
        'cwd'         => '/www_data/learninglocker',
        "scripts"     => true,
        "timeout"     => 0,
        "dev"         => false,
        'prefer_dist' => true,
        'user'        => 'app',
        "unless"      => "test -f /www_data/learninglocker/vendor/autoload.php",
      }).that_requires('Package[bower]')

      should contain_file('/www_data/learninglocker/app/storage')
      should contain_file('/www_data/learninglocker/app/storage/cache')
      should contain_file('/www_data/learninglocker/app/storage/logs')
      should contain_file('/www_data/learninglocker/app/storage/meta')
      should contain_file('/www_data/learninglocker/app/storage/sessions')
      should contain_file('/www_data/learninglocker/app/storage/views').with({
        'ensure'  => 'directory',
        'owner'   => 'www-data',
        'mode'    => '0775',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file('/www_data/learninglocker/app/storage/meta/services.json').with({
        'ensure'  => 'present',
        'owner'   => 'www-data',
        'mode'    => '0774',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/database.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/cache.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/session.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')
    }
  end

  describe 'when called with no parameters on Ubuntu 14.04' do
    let(:facts) {{
      :osfamily  => 'Debian',
      :operatingsystem => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :lsbdistid => 'Ubuntu',
      :lsbdistcodename => 'trusty',
    }}

    it {
      should_not contain_class('ius')
      should contain_class('nodejs').with({
        'manage_repo' => true,
      })
      should contain_class('nginx')
      should contain_nginx__resource__upstream('learninglocker').with({
        'ensure'  => 'present',
        'members' => [
          '127.0.0.1:9000',
        ],
      })

      should contain_user('app').with({
        'ensure'  => 'present',
        'groups'  => ['www-data'],
        'home'    => '/tmp',
      }).that_requires('Package[nginx]')

      should contain_class('php').with({
        'ensure'         => 'latest',
        'fpm'            => false,
        'composer'       => false,
        'phpunit'        => false,
        'dev'            => false,
        'pear'           => false,
        'extensions'     => {
          'mcrypt' => {},
          'mongo' => {},
        },
        'settings'       => {
          'Date/date.timezone' => 'America/Vancouver',
        }
      }).that_requires('Package[nginx]')

      should contain_class('php::fpm').with({
        'ensure' => 'present',
        'pools'  => {},
      }).that_requires('Class[php]')

      should contain_php__fpm__pool('learninglocker').with({
        'ensure' => 'present',
        'user'   => 'www-data',
        'group'  => 'www-data',
      })
      should contain_php__fpm__pool('www').with({
        'ensure' => 'absent',
      })

      should contain_class('composer').with({
        'suhosin_enabled' => false,
      }).that_requires('Class[php]')

      should contain_package('bower').with({
        'ensure'   => 'present',
        'provider' => 'npm',
      }).that_requires('Class[nodejs]')

      should contain_exec('create /www_data').with({
        'command' => 'mkdir -p /www_data',
      })

      should contain_file('/www_data').with({
        'ensure'  => 'present',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_file('/home/root').with({
        'ensure'  => 'directory',
        'owner'   => 'app',
        'mode'    => '0755',
      }).that_requires('User[app]')

      should contain_vcsrepo('/www_data/learninglocker').with({
        'ensure'   => 'present',
        'provider' => 'git',
        'source'   => 'https://github.com/LearningLocker/learninglocker.git',
        'user'     => 'app',
        'revision' => 'master',
      })

      should contain_composer__exec('learninglocker-install').with({
        'cmd'         => 'install',
        'cwd'         => '/www_data/learninglocker',
        "scripts"     => true,
        "timeout"     => 0,
        "dev"         => false,
        'prefer_dist' => true,
        'user'        => 'app',
        "unless"      => "test -f /www_data/learninglocker/vendor/autoload.php",
      }).that_requires('Package[bower]')

      should contain_file('/www_data/learninglocker/app/storage')
      should contain_file('/www_data/learninglocker/app/storage/cache')
      should contain_file('/www_data/learninglocker/app/storage/logs')
      should contain_file('/www_data/learninglocker/app/storage/meta')
      should contain_file('/www_data/learninglocker/app/storage/sessions')
      should contain_file('/www_data/learninglocker/app/storage/views').with({
        'ensure'  => 'directory',
        'owner'   => 'www-data',
        'mode'    => '0775',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file('/www_data/learninglocker/app/storage/meta/services.json').with({
        'ensure'  => 'present',
        'owner'   => 'www-data',
        'mode'    => '0774',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/database.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/cache.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')

      should contain_file("/www_data/learninglocker/app/config/session.php").with({
        'ensure'  => 'present',
        'tag'     => 'lrs.example.com',
      }).that_requires('Composer::Exec[learninglocker-install]')
    }
  end
end

