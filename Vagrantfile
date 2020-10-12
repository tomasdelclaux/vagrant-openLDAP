
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

   config.vm.network "forwarded_port", guest: 389, host: 4389
   config.vm.network "forwarded_port", guest: 636, host: 4636

   config.vm.network "private_network", ip: "192.168.33.13"

   config.vm.provider "virtualbox" do |vb|

     vb.memory = "8192"
   end

  config.vm.provision "ldap", type:'shell', path: 'openldap.sh', upload_path: "/vagrant/scripts/openldap.sh"
end
