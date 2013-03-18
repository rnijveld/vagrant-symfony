require_relative 'commandinvm'

module VagrantSymfony
  module Command
    class SymfonyCommand < CommandInVm
      def interactive
        true
      end

      def build_command(vm)
        command = Shellwords.join(@argv)
        command = '--ansi ' + command if support_color
        name = vm.config.symfony.commandName
        in_working_directory(vm, "#{name} #{command}")
      end
    end
  end
end
