require 'shellwords'
require_relative '../which'

module VagrantSymfony
  module Command
    class CommandInVm < Vagrant.plugin('2', :command)
      def execute
        with_target_vms do |vm|
          if vm.state.id == :running
            cmd = build_command(vm)
            if interactive
              run_interactive_command(vm, cmd)
            else
              run_command(vm, cmd)
            end
          end
        end
      end

      def support_color
        ENV.include?('TERM') && ENV['TERM'].include?('color')
      end

      def working_directory(vm)
        vm.config.symfony.root
      end

      def run_interactive_command(vm, cmd)
        ssh_bin = VagrantSymfony::Which.which('ssh')
        if ssh_bin != nil
          info = vm.ssh_info
          args = [
            info[:host],
            '-t',
            '-p', info[:port].to_s,
            '-l', info[:username],
            '-i', info[:private_key_path],
            '-o', 'LogLevel=QUIET',
            '--', cmd
          ]
          Vagrant::Util::SafeExec.exec('ssh', *args)
        end
        run_command(vm, cmd)
      end

      def run_command(vm, cmd)
        communicator = vm.communicate
        if communicator.ready?
          exit_status = communicator.execute(cmd, :error_check => false) do |type, data|
            channel = type == :stdout ? :out : :error
            @env.ui.info(data.to_s, :prefix => false, :new_line => false, :channel => channel)
          end
        else
          @env.ui.error("Could not execute command")
        end
        exit exit_status
      end

      def in_working_directory(vm, cmd)
        wd = working_directory(vm)
        "(cd #{wd}; #{cmd})"
      end
    end
  end
end
