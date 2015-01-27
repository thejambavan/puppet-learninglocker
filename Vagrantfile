# -*- mode: ruby -*-
# vi: set ft=ruby :
#

if ENV['VAGRANT_HOME'].nil?
    ENV['VAGRANT_HOME'] = './'
end

learninglocker = {
    # nodejs package is too old, npm gives SSL Error: CERT_UNTRUSTED
    #:'centos5'  => { :memory => '512', :ip => '10.1.1.10', :box => 'puppetlabs/centos-5.11-64-puppet',  :domain => 'learninglocker.local' },
    :'centos65' => { :memory => '512', :ip => '10.1.1.11', :box => 'puppetlabs/centos-6.5-64-puppet',   :domain => 'learninglocker.local' },
    :'centos7'  => { :memory => '512', :ip => '10.1.1.12', :box => 'puppetlabs/centos-7.0-64-puppet',   :domain => 'learninglocker.local' },
    :'precise'  => { :memory => '512', :ip => '10.1.1.20', :box => 'puppetlabs/ubuntu-12.04-64-puppet', :domain => 'learninglocker.local' },
    :'trusty'   => { :memory => '512', :ip => '10.1.1.22', :box => 'puppetlabs/ubuntu-14.04-64-puppet', :domain => 'learninglocker.local' },
    # having trouble to mount directory, might be a box issue
    #:'squeeze'  => { :memory => '512', :ip => '10.1.1.30', :box => 'puppetlabs/debian-6.0.9-64-puppet', :domain => 'learninglocker.local' },
    # having trouble to install nodejs, if someone can figure it out, that would be great!
    #:'wheezy'   => { :memory => '512', :ip => '10.1.1.31', :box => 'puppetlabs/debian-7.6-64-puppet',   :domain => 'learninglocker.local' },
}

Vagrant::Config.run("2") do |config|
  #config.vbguest.auto_update = false
  config.hostmanager.enabled = false

    learninglocker.each_pair do |name, opts|
      config.vm.define name do |n|
        config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", opts[:memory] ]
          vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        end
        n.vm.network "private_network", ip: opts[:ip]
        n.vm.box = opts[:box]
        n.vm.host_name = "#{name}" + "." + opts[:domain]
        n.vm.synced_folder "#{ENV['VAGRANT_HOME']}","/etc/puppet/modules/learninglocker"
        if "#{name}" == "trusty" or "#{name}" == "saucy"
          n.vm.provision :shell, :inline => "apt-get update"
          #n.vm.provision :shell, :inline => "apt-get -y upgrade"
          n.vm.provision :shell, :inline => "gem install puppet facter --no-ri --no-rdoc"
        end
        n.vm.provision :shell, :inline => "puppet module install kemra102-ius"
        n.vm.provision :shell, :inline => "puppet module install jfryman-nginx"
        n.vm.provision :shell, :inline => "puppet module install puppetlabs-git"
        n.vm.provision :shell, :inline => "puppet module install puppetlabs-mongodb"
        n.vm.provision :shell, :inline => "puppet module install tPl0ch-composer"
        n.vm.provision :shell, :inline => "puppet module install fsalum-redis"
        n.vm.provision :shell, :inline => "puppet module install puppetlabs-nodejs"
        n.vm.provision :shell, :inline => "puppet module install puppetlabs-firewall"
        n.vm.provision :shell, :inline => "puppet module install mayflower-php"
        n.vm.provision :puppet do |puppet|
          puppet.manifests_path = "tests"
          puppet.manifest_file  = "init.pp"
          puppet.module_path = "./"
        end
      end
    end

end
