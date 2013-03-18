require_relative 'commandinvm'

module VagrantSymfony
  module Command
    class ComposerCommand < CommandInVm
      def interactive
        true
      end

      def build_command(vm)
        command = Shellwords.join(@argv)
        # command = '--ansi ' + command if support_color
        in_working_directory(vm, "composer.phar #{command}")
      end
    end
  end
end
