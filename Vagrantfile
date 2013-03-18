Vagrant.require_plugin "vagrant-symfony"

$symfonydir = "/usr/share/nginx/www/symfony"

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.symfony.web = "./web"
  config.symfony.cmd = "./app/console"
  config.symfony.nginx_hostfile = "/etc/nginx/sites-enabled/default"
  config.symfony.update_nginx = true
  config.symfony.root = $symfonydir

  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      "vagrant" => "1",
      "symfony" => $symfonydir,
      "fqdn" => "symfony.dev"
    }
  end

  config.vm.network :private_network, ip: "192.168.42.42"
  config.vm.network :forwarded_port, guest: 80, host: 8000
  config.vm.synced_folder "./", $symfonydir, :nfs => true
end
