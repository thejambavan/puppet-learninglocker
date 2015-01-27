require 'spec_helper'

describe 'learninglocker::db', :type => :class do

  describe 'when called with no parameters' do
    let(:facts) { { :osfamily  => 'Redhat', :operatingsystemrelease => 6  } }

    it {
      should contain_class('mongodb::server').with({
        'port' => 27017,
      })
      should contain_class('mongodb::client')
      should contain_mongodb__db('learninglocker').with({
        'user' => 'learninglocker',
        'password' => 'learninglocker',
      })
    }
  end
end

