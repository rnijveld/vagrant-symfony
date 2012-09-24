class nginx-php-mongo {
	
	host {'self':
		ensure       => present,
		name         => $fqdn,
		host_aliases => ['puppet', $hostname],
		ip           => $ipaddress,
	}
	
	$php = ["php5-fpm", "php5-cli", "php5-dev", "php5-gd", "php5-curl", "php-pear", "php-apc", "php5-mcrypt", "php5-xdebug", "php5-sqlite"]
	
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
	
	package { $php:
		notify => Service['php5-fpm'],
		ensure => latest,
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
