# Let's prevent having to mention the absolute path all the time
Exec { path => ['/bin/', '/sbin/', '/usr/bin', '/usr/sbin/', '/usr/local/bin/'] }

define line($file, $line, $ensure = 'present') {
  case $ensure {
    default: { err("Uknown ensure value ${ensure}") }
    present: {
      exec { "add-line":
        command => "echo '${line}' >> '${file}'",
        unless => "grep -qFx '${line}' '${file}'"
      }
    }
    absent: {
      exec { "remove-line":
        command => "grep -vFx '${line}' '${file}' | tee '${file}' > /dev/null 2>&1",
        onlyif => "grep -qFx '${line}' '${file}'"
      }
    }
    comment: {
      exec { "comment-line":
        command => "sed -i -e'/${line}/s/#\\+//' '${file}'",
        onlyif => "grep '${line}' '${file}' | grep '^#' | wc -l"
      }
    }
    uncomment: {
      exec { "uncomment-line":
        command => "sed -i -e'/${line}/s/\\(.\\+\\)$/#\\1/' '${file}'",
        onlyif => "test `grep '${line}' '${file}' | grep -v '^#' | wc -l` -ne 0"
      }
    }
  }
}

class apt {
  exec { 'apt-get update':
    command => 'apt-get update',
  }

  package { 'python-software-properties':
    ensure => present,
    require => Exec['apt-get update'],
  }

  exec { 'add-apt-repository ppa:ondrej/php5':
    command => 'add-apt-repository ppa:ondrej/php5',
    require => Package["python-software-properties"],
  }

  exec { 'add-apt-repository ppa:chris-lea/node.js':
    command => 'add-apt-repository ppa:chris-lea/node.js',
    require => Package["python-software-properties"],
  }

  exec { 'apt-get update all':
    command => 'apt-get update',
    require => [Exec['add-apt-repository ppa:ondrej/php5'], Exec['add-apt-repository ppa:chris-lea/node.js']],
  }

  exec { 'apt-get upgrade':
    command => 'apt-get -y upgrade',
    require => Exec['apt-get update all'],
  }
}

class base-packages {
  require apt

  $packages = [
    'git-core',
    'curl',
    'build-essential',
    'wget',
    'zerofree',
    'python',
    'g++',
    'make',
    'nodejs'
  ]

  package { $packages:
    ensure => present,
  }
}

class vbox-guest-additions {
  require base-packages
  require apt

  Exec['install-requirements']->Exec['retrieve']->Exec['mount']->Exec['install']->Exec['unmount']->Exec['clear']

  $vboxversion = '4.2.10'
  $url = "http://download.virtualbox.org/virtualbox/$vboxversion/VBoxGuestAdditions_$vboxversion.iso"

  exec { 'install-requirements':
    command => 'apt-get -y install linux-headers-`uname -r`',
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }

  exec { 'retrieve':
    command => "wget -O /tmp/VBoxGuestAdditions.iso $url",
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }

  exec { 'mount':
    command => "mount -o loop /tmp/VBoxGuestAdditions.iso /mnt",
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }

  exec { 'install':
    command => "/mnt/VBoxLinuxAdditions.run",
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }

  exec { 'unmount':
    command => 'umount /mnt',
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }

  exec { 'clear':
    command => 'rm /tmp/VBoxGuestAdditions.iso',
    unless => "VBoxService --version | grep -F -i $vboxversion",
  }
}

class nginx-php {
  require base-packages
  require apt

  $php = [
    "php5-fpm",
    "php5-cli",
    "php5-dev",
    "php5-mysql",
    "php5-gd",
    "php5-curl",
    "php-pear",
    "php-apc",
    "php5-mcrypt",
    "php5-xdebug",
    "php5-sqlite",
    "php5-imagick",
    "php5-memcache",
    "php5-memcached",
    "php5-xmlrpc",
    "php5-xsl",
    "php5-intl",
    "php5-enchant"
  ]

  package { "nginx":
    ensure => present,
  }

  package { $php:
    notify => Service['php5-fpm'],
    ensure => latest,
  }

  package { "apache2.2-bin":
    notify => Service['nginx'],
    ensure => purged,
    require => Package[$php],
  }

  exec { 'pear config-set auto_discover 1':
    command => 'pear config-set auto_discover 1',
    before => Exec['pear install pear.phpunit.de/PHPUnit'],
    require => Package[$php],
    unless => "ls -l /usr/bin/ | grep phpunit",
  }

  exec { 'pear install pear.phpunit.de/PHPUnit':
    notify => Service["php5-fpm"],
    command => 'pear install --force pear.phpunit.de/PHPUnit',
    before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
    unless => "ls -l /usr/bin/ | grep phpunit",
  }

  exec { 'npm install -g less':
    command => 'npm install -g less',
  }

  exec { 'install_composer':
    command => 'curl https://getcomposer.org/installer | php -- --install-dir=/usr/bin',
    require => [Package[$php]],
  }

  exec { 'update_composer':
    command => 'composer.phar self-update',
    require => Exec['install_composer'],
  }

  exec { 'ln www/symfony':
    command => "ln -f -s $symfony /home/vagrant/www",
    unless => 'ls /home/vagrant/www',
  }

  file { '/etc/php5/cli/php.ini':
    owner  => root,
    group  => root,
    ensure => file,
    mode   => 644,
    source => '/vagrant/files/php/cli/php.ini',
    require => Package[$php],
  }

  file { '/etc/php5/fpm/php.ini':
    notify => Service["php5-fpm"],
    owner  => root,
    group  => root,
    ensure => file,
    mode   => 644,
    source => '/vagrant/files/php/fpm/php.ini',
    require => Package[$php],
  }

  file { '/etc/php5/fpm/php-fpm.conf':
    notify => Service["php5-fpm"],
    owner  => root,
    group  => root,
    ensure => file,
    mode   => 644,
    source => '/vagrant/files/php/fpm/php-fpm.conf',
    require => Package[$php],
  }

  file { '/etc/php5/fpm/pool.d/www.conf':
    notify => Service["php5-fpm"],
    owner  => root,
    group  => root,
    ensure => file,
    mode   => 644,
    source => '/vagrant/files/php/fpm/pool.d/www.conf',
    require => Package[$php],
  }

  file { '/etc/nginx/sites-available/default':
    owner  => root,
    group  => root,
    ensure => file,
    mode   => 644,
    source => '/vagrant/files/nginx/default',
    require => Package["nginx"],
  }

  file { "/etc/nginx/sites-enabled/default":
    notify => Service["nginx"],
    ensure => link,
    target => "/etc/nginx/sites-available/default",
    require => Package["nginx"],
  }

  file { "/home/vagrant/.ssh/id_rsa_git":
    owner => vagrant,
    group => vagrant,
    ensure => file,
    mode => 600,
    source => '/vagrant/files/ssh/id_rsa'
  }

  file { "/home/vagrant/.ssh/id_rsa_git.pub":
    owner => vagrant,
    group => vagrant,
    ensure => file,
    mode => 644,
    source => '/vagrant/files/ssh/id_rsa.pub'
  }

  file { "/home/vagrant/.ssh/config":
    owner => vagrant,
    group => vagrant,
    ensure => file,
    mode => 644,
    source => '/vagrant/files/ssh/config'
  }

  file { "/home/vagrant/.ssh/known_hosts":
    owner => vagrant,
    group => vagrant,
    ensure => file,
    mode => 600,
    source => '/vagrant/files/ssh/known_hosts'
  }

  service { "php5-fpm":
    ensure => running,
    require => Package["php5-fpm"],
  }

  service { "nginx":
    ensure => running,
    require => Package["nginx"],
  }
}

class install-all {
  include nginx-php
  include vbox-guest-additions

  Class['nginx-php']->Class['vbox-guest-additions']->Exec['apt-get autoremove']->Exec['apt-get clean']

  exec { 'apt-get autoremove':
    command => 'apt-get -y autoremove',
  }

  exec { 'apt-get clean':
    command => 'apt-get -y clean',
  }

  exec { 'empty-cache':
    command => "find /var/cache -type f -exec rm -rf {} \\;",
    require => Exec['apt-get clean'],
  }

  exec { 'rm-vboxguest':
    command => 'rm -rf /usr/src/vboxguest*',
    require => Exec['apt-get clean'],
  }

  file { "/usr/local/bin/cleanup.sh":
    owner => root,
    group => root,
    ensure => file,
    mode => 700,
    source => '/vagrant/files/cleanup.sh'
  }
}

class after-install {
  require install-all

  line { "bashrc":
    file => "/home/vagrant/.bashrc",
    line => "force_color_prompt=yes",
    ensure => 'uncomment',
  }

}

include after-install
