module VagrantSymfony
  require 'shellwords'

  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') + [''] : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      end
    end
    return nil
  end

  class ShellCommand < Vagrant.plugin('2', :command)
    def execute
      with_target_vms do |vm|
        if vm.state.id == :running
          ssh_bin = VagrantSymfony.which('ssh')
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
      if vm.config.vm.synced_folders.include? 'symfony'
        vm.config.vm.synced_folders['symfony'][:guestpath]
      else
        vm.config.vm.synced_folders['vagrant-root'][:guestpath]
      end
    end

    def run_interactive_command(vm, cmd)
      ssh_bin = VagrantSymfony.which('ssh')
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

  class SymfonyCommand < CommandInVm
    def interactive
      true
    end

    def build_command(vm)
      command = Shellwords.join(@argv)
      command = '--ansi ' + command if support_color
      in_working_directory(vm, "./app/console #{command}")
    end
  end

  class ComposerCommand < CommandInVm
    def interactive
      true
    end

    def build_command(vm)
      command = Shellwords.join(@argv)
      command = '--ansi ' + command if support_color
      in_working_directory(vm, "composer.phar #{command}")
    end
  end
end
