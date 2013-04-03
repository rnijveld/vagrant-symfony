require 'log4r'
require 'shellwords'

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
          entry = vm.config.symfony.entryPoint
          communicator = vm.communicate
          if communicator.ready?
            env[:ui].info "Updating web directory and reloading config..."
            vm.communicate.sudo "sed -i 's@root .*;@root #{folder};@g' #{file}"
            vm.communicate.sudo "sed -i 's@rewrite \\(.*\\)/\\(.*\\)/$1\\(.*\\);@rewrite \\1/#{entry}/$1\\3;@g' #{file}"
            vm.communicate.sudo "rm -rf /etc/nginx/fastcgi_env_params"
            vm.communicate.sudo "touch /etc/nginx/fastcgi_env_params"
            vm.config.symfony.environmentVariables.each do |key, value|
              line = 'fastcgi_param %s %s;' % [key.to_s, value.to_s]
              line = Shellwords.escape(line)
              vm.communicate.sudo "echo #{line} >> /etc/nginx/fastcgi_env_params"
            end
            vm.communicate.sudo "grep -q fastcgi_env_params #{file} || sed -i 's@fastcgi_params;@fastcgi_params; include fastcgi_env_params;@' #{file}"
            vm.communicate.sudo "service nginx reload"
          end
        end
      end
    end
  end
end
