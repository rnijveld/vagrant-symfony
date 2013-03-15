module VagrantSymfony
  require 'shellwords'

  class CommandInVm < Vagrant::Command::Base
    def execute
      @env.vms.each do |name,vm|
        if vm.created? && vm.state == :running
          run_command(vm, build_command(vm))
        end
      end
    end

    def support_color
      ENV.include?('TERM') && ENV['TERM'].include?('color')
    end

    def working_directory(vm)
      if @env.config.global.keys[:vm].shared_folders.include? 'symfony'
        @env.config.global.keys[:vm].shared_folders['symfony'][:guestpath]
      else
        @env.config.global.keys[:vm].shared_folders['v-root'][:guestpath]
      end
    end

    def run_command(vm, cmd)
      exit_status = vm.channel.execute(cmd, :error_check => false) do |type, data|
        channel = type == :stdout ? :out : :error
        vm.ui.info(data.to_s, :prefix => false, :new_line => false, :channel => channel)
      end
      exit exit_status
    end

    def in_working_directory(vm, cmd)
      wd = working_directory(vm)
      "(cd #{wd}; #{cmd})"
    end
  end

  class SymfonyCommand < CommandInVm
    def build_command(vm)
      command = Shellwords.join(@argv)
      command = '--ansi ' + command if support_color
      in_working_directory(vm, "./app/console #{command}")
    end
  end

  class ComposerCommand < CommandInVm
    def build_command(vm)
      command = Shellwords.join(@argv)
      command = '--ansi ' + command if support_color
      in_working_directory(vm, "composer.phar #{command}")
    end
  end
end

Vagrant.commands.register(:sf, VagrantSymfony::SymfonyCommand)
Vagrant.commands.register(:composer, VagrantSymfony::ComposerCommand)
