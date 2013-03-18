module VagrantSymfony
  class VagrantSymfonyPlugin < Vagrant.plugin('2')
    name "VagrantSymfony"

    config "symfony" do
      require_relative "config/config"
      Config::Config
    end

    ["sf", "symfony", "cmd", "console"].each do |cmd|
      command cmd do
        require_relative "command/symfony"
        Command::SymfonyCommand
      end
    end

    ["composer"].each do |cmd|
      command cmd do
        require_relative "command/composer"
        Command::ComposerCommand
      end
    end

    action_hook(ALL_ACTIONS) do |hook|
      require_relative "action/boot"
      hook.before(Vagrant::Action::Builtin::Provision, Action::Boot)
    end
  end
end
