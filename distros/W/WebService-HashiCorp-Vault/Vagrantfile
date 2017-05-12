# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"

  config.vm.synced_folder '.', '/vagrant'
  #config.vm.synced_folder '.', '/vagrant_data'

  config.vm.provision "shell", inline: <<-SHELL

     # install what we need
     sudo apt-get update
     sudo apt-get install unzip curl jq

     # use system perl for now
     # TODO use perlbrew, cpanm etc
     sudo apt-get install libmoo-perl
     sudo apt-get install cpanminus libwww-perl make libnamespace-clean-perl
     sudo cpanm WebService::Client

     cd /tmp
     wget --no-check-certificate https://releases.hashicorp.com/vault/0.7.0/vault_0.7.0_linux_amd64.zip
     sudo mkdir -p /opt/vault/data
     cd /opt/vault
     sudo unzip /tmp/vault*zip
     /opt/vault/vault -v

    sudo cp /vagrant/t/.files/vault.hcl /opt/vault/vault.hcl
    sudo cp /vagrant/t/.files/vault.service /lib/systemd/system/vault.service
    sudo cp /vagrant/t/.files/vault.sh /etc/profile.d/vault.sh

    sudo systemctl daemon-reload
    sudo systemctl start vault
    sudo systemctl enable vault

    # dont do this in production, obviously
    # TODO init with just one key, maybe put it in /etc/sysconfig/vault and have the vault.service file unseal?
    VAULT_ADDR='http://127.0.0.1:8200' /opt/vault/vault init > /opt/vault/vault-init.log
    for i in `cat /opt/vault/vault-init.log  | grep 'Unseal Key' | sed 's/Unseal Key [1-5]: //'`; do VAULT_ADDR='http://127.0.0.1:8200' /opt/vault/vault unseal $i; done

    sudo -- sh -c "cat *log | grep 'Root Token' | sed 's/Initial Root Token: /export VAULT_TOKEN=/' >> /etc/profile.d/vault.sh"

    # finish up
    # sudo /vagrant/src/server/DEBIAN/postinst
   SHELL
end
