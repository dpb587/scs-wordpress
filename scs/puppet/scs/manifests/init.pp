class scs (
    $http_scheme = 'http',
    $http_host = 'localhost',
    $http_path = '/wordpress',

    $database_user = 'wptest1',
    $database_password = 'wptest1',
    $database_name = 'wptest1',
    $database_tableprefix = 'wp_',

    $wordpress_version = '3.7.1',

    $wordpress_globals = {},

    $wordpress_token_auth_key = 'put your unique phrase here',
    $wordpress_token_auth_salt = 'put your unique phrase here',
    $wordpress_token_secureauth_key = 'put your unique phrase here',
    $wordpress_token_secureauth_salt = 'put your unique phrase here',
    $wordpress_token_loggedin_key = 'put your unique phrase here',
    $wordpress_token_loggedin_salt = 'put your unique phrase here',
    $wordpress_token_nonce_key = 'put your unique phrase here',
    $wordpress_token_nonce_salt = 'put your unique phrase here',
) {
    $wordpress_docroot = "/scs/var/www${http_path}"

    group {
        'scs' :
            ensure => present,
            gid => 1010,
            ;
    }

    user {
        'scs' :
            ensure => present,
            gid => 1010,
            shell => '/bin/false',
            uid => 1010,
            require => [
                Group['scs'],
            ],
            ;
    }

    exec {
        'apt-source:nginx/stable:key' :
            command => '/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C',
            ;
        'apt-source:nginx/stable' :
            command => '/bin/echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu precise main" >> /etc/apt/sources.list',
            unless => '/bin/grep "deb http://ppa.launchpad.net/nginx/stable/ubuntu precise main" /etc/apt/sources.list',
            require => [
                Exec['apt-source:nginx/stable:key'],
            ],
            ;
        'apt-source:ondrej/php5:key' :
            command => '/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C',
            ;
        'apt-source:ondrej/php5' :
            command => '/bin/echo "deb http://ppa.launchpad.net/ondrej/php5/ubuntu precise main" >> /etc/apt/sources.list',
            unless => '/bin/grep "deb http://ppa.launchpad.net/ondrej/php5/ubuntu precise main" /etc/apt/sources.list',
            require => [
                Exec['apt-source:ondrej/php5:key'],
            ],
            ;
        'apt-update' :
            command => '/usr/bin/apt-get update',
            require => [
                Exec['apt-source:nginx/stable'],
                Exec['apt-source:ondrej/php5'],
            ],
            ;
        '/usr/bin/easy_install supervisor' :
            creates => '/usr/bin/supervisord',
            require => [
                Package['python-setuptools'],
            ],
            ;
        'wordpress' :
            command => "/usr/bin/wget -O- 'http://wordpress.org/wordpress-${wordpress_version}.tar.gz' | /bin/tar -xz --strip-components=1",
            cwd => "${wordpress_docroot}",
            creates => "${wordpress_docroot}/index.php",
            require => [
                File["${wordpress_docroot}"],
            ],
            ;
        'wordpress-cleanup' :
            command => '/scs/scs/bin/wordpress-cleanup',
            cwd => "${wordpress_docroot}",
            require => [
                Exec['wordpress'],
            ],
            ;
    }

    file {
        "/scs/etc" :
            ensure => directory,
            ;
        "/scs/etc/supervisor.conf" :
            ensure => file,
            content => template('scs/supervisor/supervisor.conf.erb'),
            ;
        "/scs/etc/supervisor.d" :
            ensure => directory,
            ;
        "/scs/var" :
            ensure => directory,
            ;
        "/scs/var/log" :
            ensure => directory,
            ;
        "/scs/var/log/supervisord" :
            ensure => directory,
            ;
        "/scs/var/run" :
            ensure => directory,
            ;
        "/scs/var/run/supervisord" :
            ensure => directory,
            ;

        "/scs/etc/nginx" :
            ensure => directory,
            ;
        "/scs/etc/nginx/mime.types" :
            ensure => file,
            content => template('scs/nginx/mime.types.erb'),
            ;
        "/scs/etc/nginx/nginx.conf" :
            ensure => file,
            content => template('scs/nginx/nginx.conf.erb'),
            ;
        "/scs/etc/supervisor.d/nginx.conf" :
            ensure => file,
            content => template('scs/nginx/supervisor.conf.erb'),
            ;
        "/scs/var/log/nginx" :
            ensure => directory,
            ;
        "/scs/var/run/nginx" :
            ensure => directory,
            ;

        "/scs/etc/php-fpm" :
            ensure => directory,
            ;
        "/scs/etc/php-fpm/php-fpm.ini" :
            ensure => file,
            content => template('scs/php-fpm/php-fpm.ini.erb'),
            ;
        "/scs/var/log/php-fpm" :
            ensure => directory,
            ;
        "/scs/var/run/php-fpm" :
            ensure => directory,
            ;
        "/scs/etc/supervisor.d/php-fpm.conf" :
            ensure => file,
            content => template('scs/php-fpm/supervisor.conf.erb'),
            ;

        "/scs/var/www" :
            ensure => directory,
            ;
        "${wordpress_docroot}/wp-config.php" :
            ensure => file,
            content => template('scs/wordpress/wp-config.php.erb'),
            mode => 0644,
            ;
    }

    if "" != "${http_path}" {
        file {
            "${wordpress_docroot}" :
                ensure => directory,
                ;
        }
    }

    package {
        'nginx' :
            ensure => installed,
            require => [
                Exec['apt-source:nginx/stable'],
                Exec['apt-update'],
            ],
            ;
        'php5-fpm' :
            ensure => installed,
            require => [
                Exec['apt-source:ondrej/php5'],
                Exec['apt-update'],
            ],
            ;
        'php5-gd' :
            ensure => installed,
            require => [
                Exec['apt-source:ondrej/php5'],
                Exec['apt-update'],
            ],
            ;
        'php5-mysql' :
            ensure => installed,
            require => [
                Exec['apt-source:ondrej/php5'],
                Exec['apt-update'],
            ],
            ;
        'python-setuptools' :
            ensure => installed,
            require => [
                Exec['apt-update'],
            ],
            ;
        'unzip' :
            ensure => installed,
            require => [
                Exec['apt-update'],
            ],
            ;
    }

    scs::plugin {
        'nginx-helper' :
            source_zip => 'http://downloads.wordpress.org/plugin/nginx-helper.1.7.5.zip',
            ;
    }
}
