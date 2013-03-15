class nginx-php-mongo {

  host {'self':
    ensure       => present,
    name         => $fqdn,
    host_aliases => ['puppet', $hostname],
    ip           => $ipaddress,
  }

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

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => [Package["python-software-properties"], Package["build-essential"], Package["nginx"], Package["mongodb"], Package[$php]],
  }

  package { "python-software-properties":
    ensure => present,
  }

  exec { 'add-apt-repository ppa:ondrej/php5':
    command => '/usr/bin/add-apt-repository ppa:ondrej/php5',
    require => Package["python-software-properties"],
  }

  exec { 'apt-get update for latest php':
    command => '/usr/bin/apt-get update',
    before => Package[$php],
    require => Exec['add-apt-repository ppa:ondrej/php5'],
  }

  package { "build-essential":
    ensure => present,
  }

  package { "nginx":
    ensure => present,
  }

  package { "mongodb":
    ensure => present,
  }

  package { "git-core":
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

  package { "curl":
    ensure => present,
  }

  exec { 'pecl install mongo':
    notify => Service["php5-fpm"],
    command => '/usr/bin/pecl install --force mongo',
    logoutput => "on_failure",
    require => [Package["build-essential"], Package[$php]],
    before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
    unless => "/usr/bin/php -m | grep mongo",
  }

  exec { 'pear config-set auto_discover 1':
    command => '/usr/bin/pear config-set auto_discover 1',
    before => Exec['pear install pear.phpunit.de/PHPUnit'],
    require => Package[$php],
    unless => "/bin/ls -l /usr/bin/ | grep phpunit",
  }

  exec { 'pear install pear.phpunit.de/PHPUnit':
    notify => Service["php5-fpm"],
    command => '/usr/bin/pear install --force pear.phpunit.de/PHPUnit',
    before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
    unless => "/bin/ls -l /usr/bin/ | grep phpunit",
  }

  exec { 'install_composer':
    command => '/usr/bin/curl https://getcomposer.org/installer | /usr/bin/php -- --install-dir=/usr/bin',
    require => [Package[$php],Package['curl']],
  }

  exec { 'update_composer':
    command => '/usr/bin/composer.phar self-update',
    require => Exec['install_composer'],
  }

  exec { 'ls www/symfony':
    command => "/bin/ln -f -s $symfony /home/vagrant/www"
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

  service { "php5-fpm":
    ensure => running,
    require => Package["php5-fpm"],
  }

  service { "nginx":
    ensure => running,
    require => Package["nginx"],
  }

  service { "mongodb":
    ensure => running,
    require => Package["mongodb"],
  }
}

include nginx-php-mongo
