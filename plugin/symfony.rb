module VagrantSymfony
  class VagrantSymfonyPlugin < Vagrant.plugin('2')
    name "VagrantSymfony"

    command "sf" do
      require_relative "commands"
      SymfonyCommand
    end

    command "composer" do
      require_relative "commands"
      ComposerCommand
    end

    command "shell" do
      require_relative "commands"
      ShellCommand
    end
  end
end
