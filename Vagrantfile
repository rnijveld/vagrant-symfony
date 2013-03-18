require_relative 'plugin/symfony'

$symfonydir = "/usr/share/nginx/www/symfony"

Vagrant::Config.run do |config|
  config.vm.box = "precise64"

  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      "vagrant" => "1",
      "symfony" => $symfonydir,
      "fqdn" => "symfony.dev"
    }
  end

  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :hostonly, "192.168.42.42"

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port 80, 4567
  config.vm.share_folder("symfony", $symfonydir, "./", :nfs => true)
end
