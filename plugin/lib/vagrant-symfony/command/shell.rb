require 'shellwords'
require_relative '../which'

module VagrantSymfony
  module Command
    class ShellCommand < Vagrant.plugin('2', :command)
      def execute
        with_target_vms do |vm|
          if vm.state.id == :running
            ssh_bin = VagrantSymfony::Which.which('ssh')
            if ssh_bin == nil
              @env.ui.error("Could not find a SSH binary")
            else
              info = vm.ssh_info
              args = [
                info[:host],
                '-p', info[:port].to_s,
                '-l', info[:username],
                '-i', info[:private_key_path]
              ]
              Vagrant::Util::SafeExec.exec('ssh', *args)
            end
          end
        end
      end
    end
  end
end
