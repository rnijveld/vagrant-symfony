require "log4r"

module VagrantSymfony
  module Action
    class Boot
      def initialize(app, env)
        @app = app
        @logger = Log4r::Logger.new('vagranysymfony::action::boot')
      end

      def call(env)
        @app.call(env)
        vm = env[:machine]
        if vm.config.symfony.updateNginx
          folder = vm.config.symfony.webFolder
          root = vm.config.symfony.rootFolder
          if folder.start_with? './'
            folder = root + folder[1..-1]
          elsif !folder.start_with('/')
            folder = root + '/' + folder
          end
          file = vm.config.symfony.nginxHostfile
          communicator = vm.communicate
          if communicator.ready?
            env[:ui].info "Updating web directory and reloading config..."
            vm.communicate.sudo "sed -i 's@root .*;@root #{folder};@g' #{file}"
            vm.communicate.sudo "service nginx reload"
          end
        end
      end
    end
  end
end
