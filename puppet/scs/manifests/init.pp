class scs (
    $http_scheme = 'http',
    $http_host = 'localhost',
    $http_path = '/wordpress',

    $smtp_host = undef,
    $smtp_port = undef,
    $smtp_tls = 'off',
    $smtp_tls_trust = '/etc/ssl/certs/ca-certificates.crt',
    $smtp_from = undef,
    $smtp_auth = 'off',
    $smtp_auth_user = undef,
    $smtp_auth_password = undef,

    $database_user = 'wordpress',
    $database_password = 'wordpress',
    $database_name = 'wordpress',
    $database_tableprefix = 'wp_',
    $database_charset = 'utf8',
    $database_collate = '',

    $wordpress_version = '3.8.1',

    $wordpress_globals = {},

    $wordpress_token_auth_key = 'put your unique phrase here',
    $wordpress_token_auth_salt = 'put your unique phrase here',
    $wordpress_token_secureauth_key = 'put your unique phrase here',
    $wordpress_token_secureauth_salt = 'put your unique phrase here',
    $wordpress_token_loggedin_key = 'put your unique phrase here',
    $wordpress_token_loggedin_salt = 'put your unique phrase here',
    $wordpress_token_nonce_key = 'put your unique phrase here',
    $wordpress_token_nonce_salt = 'put your unique phrase here',

    $wordpress_cleanup = false,

    $plugin_nginxhelper = '1.8',
) {
    $wordpress_docroot = "/var/www${http_path}"

    file {
        '/usr/bin/scs-liveupdate-mysql' :
            ensure => file,
            source => 'puppet:///modules/scs/scs-liveupdate-mysql',
            owner => root,
            group => root,
            mode => 0755,
            ;
        '/usr/bin/scs-runtime-hook-start' :
            ensure => file,
            source => 'puppet:///modules/scs/scs-runtime-hook-start',
            owner => root,
            group => root,
            mode => 0755,
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
        'wordpress' :
            command => "/usr/bin/wget -O- 'http://wordpress.org/wordpress-${wordpress_version}.tar.gz' | /bin/tar -xz --strip-components=1",
            cwd => "${wordpress_docroot}",
            creates => "${wordpress_docroot}/index.php",
            require => [
                File["${wordpress_docroot}"],
            ],
            ;
    }

    file {
        "/etc/msmtprc" :
            ensure => file,
            content => template('scs/smtp/msmtprc.erb'),
            mode => 0444,
            ;

        "/etc/nginx" :
            ensure => directory,
            ;
        "/etc/nginx/mime.types" :
            ensure => file,
            content => template('scs/nginx/mime.types.erb'),
            ;
        "/etc/nginx/nginx.conf" :
            ensure => file,
            content => template('scs/nginx/nginx.conf.erb'),
            ;
        "/etc/supervisor.d/nginx.conf" :
            ensure => file,
            content => template('scs/nginx/supervisor.conf.erb'),
            ;
        "/var/log/nginx" :
            ensure => directory,
            ;
        "/var/run/nginx" :
            ensure => directory,
            ;

        "/etc/php-fpm" :
            ensure => directory,
            ;
        "/etc/php-fpm/php-fpm.ini" :
            ensure => file,
            content => template('scs/php-fpm/php-fpm.ini.erb'),
            ;
        "/var/log/php-fpm" :
            ensure => directory,
            ;
        "/var/run/php-fpm" :
            ensure => directory,
            ;
        "/etc/supervisor.d/php-fpm.conf" :
            ensure => file,
            content => template('scs/php-fpm/supervisor.conf.erb'),
            ;

        "/var/www" :
            ensure => directory,
            ;
        "${wordpress_docroot}/wp-config.php" :
            ensure => file,
            content => template('scs/wordpress/wp-config.php.erb'),
            mode => 0644,
            require => [
                Exec['wordpress'],
            ],
            ;
        "${wordpress_docroot}/wp-content/uploads" :
            ensure => link,
            target => '/mnt/uploads',
            require => [
                Exec['wordpress'],
            ],
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
        'nginx-light' :
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
        'msmtp' :
            ensure => installed,
            require => [
                Exec['apt-update'],
                File['/etc/msmtprc'],
            ],
            ;
        'unzip' :
            ensure => installed,
            require => [
                Exec['apt-update'],
            ],
            ;
    }

    if $wordpress_cleanup {
        exec {
            'wordpress:cleanup' :
                command => '/bin/rm -fr readme.html license.txt wp-config-sample.php wp-content/themes/twentythirteen wp-content/themes/twentytwelve wp-content/themes/twentyeleven wp-content/themes/twentyten wp-content/plugins/hello.php',
                cwd => "${wordpress_docroot}",
                require => [
                    Exec['wordpress'],
                ],
                ;
        }
    }

    if $plugin_nginxhelper {
        scs::plugin {
            'nginx-helper' :
                source_zip => "http://downloads.wordpress.org/plugin/nginx-helper.${plugin_nginxhelper}.zip",
                ;
        }
    }
}
