# -*- mode: ruby -*-
# vi: set ft=ruby :

# Use environment variable or default to local box
# Available boxes: windows11-disk, windows11-security
VAGRANT_BOX = ENV['VAGRANT_BOX'] || 'windows11-security'

Vagrant.configure("2") do |config|
  config.vm.box = VAGRANT_BOX

  config.vm.communicator = 'winrm'
  config.winrm.username = 'vagrant'
  config.winrm.password = 'vagrant'
  config.winrm.transport = :plaintext
  config.winrm.basic_auth_only = true
  config.winrm.timeout = 1800
  config.winrm.retry_limit = 30

  # VirtualBox provider settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
    vb.gui = false
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end

  # Disable synced folder (not needed for testing)
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Ansible provisioner
  config.vm.provision :ansible do |ansible|
    ansible.limit = 'all'
    ansible.playbook = 'tests/playbook.yml'
    ansible.verbose = 'vv'
    ansible.extra_vars = {
      'ansible_connection' => 'winrm',
      'ansible_winrm_transport' => 'basic',
      'ansible_winrm_server_cert_validation' => 'ignore',
      'ansible_winrm_scheme' => 'http',
      'ado_pat_token' => ENV.fetch('ADO_PAT_TOKEN', 'placeholder'),
    }
  end
end
