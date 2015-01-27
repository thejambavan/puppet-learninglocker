require 'spec_helper'

describe 'learninglocker::cache', :type => :class do
  let(:facts) { { :path => '/usr/local/bin:/usr/bin:/bin' } }

  describe 'when called with no parameters on Redhat 6' do
    let(:facts) { { :osfamily  => 'Redhat', :operatingsystemrelease => 6  } }

    it {
      should contain_class('redis').with({
        'system_sysctl'          => true,
        'redis_version_override' => '2.4.x',
        'require'                => 'Yumrepo[epel]',
      })
    }
  end

  describe 'when called with no parameters on Redhat 7' do
    let(:facts) { { :osfamily  => 'Redhat', :operatingsystemrelease => 7  } }

    it {
      should contain_class('redis').with({
        'system_sysctl'          => true,
        'require'                => 'Yumrepo[epel]',
      })
    }
  end

  describe 'when called with no parameters on Ubuntu 12.04' do
    let(:facts) { { :osfamily  => 'Debian', :operatingsystemrelease => '12.04'  } }

    it {
      should contain_class('redis').with({
        'system_sysctl'          => true,
      })
    }
  end

  describe 'when called with no parameters on Ubuntu 14.04' do
    let(:facts) { { :osfamily  => 'Debian', :operatingsystemrelease => '14.04'  } }

    it {
      should contain_class('redis').with({
        'system_sysctl'          => true,
      })
    }
  end
end
