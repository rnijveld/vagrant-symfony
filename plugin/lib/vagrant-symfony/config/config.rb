module VagrantSymfony
  module Config
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :web, :cmd, :update_nginx, :nginx_hostfile, :root, :entry

      def initialize
        @web = UNSET_VALUE
        @cmd = UNSET_VALUE
        @update_nginx = UNSET_VALUE
        @nginx_hostfile = UNSET_VALUE
        @root = UNSET_VALUE
        @entry = UNSET_VALUE
      end

      def entryPoint
        return "app.php" if @entry == UNSET_VALUE
        return @entry[1..-1] if @entry[0] == '/'
        return @entry[2..-1] if @entry[0] == '.' && @entry[1] == '/'
        return @entry
      end

      def rootFolder
        return "/vagrant" if @root == UNSET_VALUE
        return @root[0..-2] if @root[-1] == '/'
        return @root
      end

      def webFolder
        return "./web" if @web == UNSET_VALUE
        return @web[0..-2] if @web[-1] == '/'
        return @web
      end

      def commandName
        return "./app/console" if @cmd == UNSET_VALUE
        return @cmd
      end

      def updateNginx
        return false if @update_nginx == UNSET_VALUE
        return @update_nginx
      end

      def nginxHostfile
        return "/etc/nginx/sites-enabled/default" if @nginx_hostfile == UNSET_VALUE
        return @nginx_hostfile
      end
    end
  end
end
