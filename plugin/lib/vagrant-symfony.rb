require "pathname"
require "vagrant-symfony/symfony"

module VagrantSymfony
  # lib_path = Pathname.new(File.expand_path("../vagrant-symfony", __FILE__))

  def self.source_root
    @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
  end
end
