define scs::newrelic (
    $license,
    $options = [],
) {
    exec {
        'newrelic:apt' :
            command => '/bin/echo "deb http://apt.newrelic.com/debian/ newrelic non-free" >> /etc/apt/sources.list.d/newrelic.list && /usr/bin/wget -O- https://download.newrelic.com/548C16BF.gpg | /usr/bin/apt-key add - && /usr/bin/apt-get update',
            creates => '/etc/apt/sources.list.d/newrelic.list',
            ;
        'newrelic:module' :
            command => "/bin/ln -s /usr/lib/newrelic-php5/agent/x64/newrelic-`/usr/sbin/php5-fpm -i | /bin/grep 'PHP Extension =>' | /usr/bin/awk '{ print \$4 }'``/usr/sbin/php5-fpm -i | /bin/grep 'Thread Safety =>' | /usr/bin/awk '{ print \$4 }' | /bin/sed -e 's/enabled/-zts/' -e 's/disabled//'`.so `/usr/sbin/php5-fpm -i | /bin/grep 'extension_dir' | /usr/bin/awk '{ print \$3 }'`/newrelic.so",
            require => [
                Package['php5-fpm'],
                Package['newrelic-php5'],
            ],
            ;
    }

    package {
        'newrelic-php5' :
            require => [
                Exec['newrelic:apt'],
            ],
            ;
    }

    file {
        '/etc/php5/fpm/conf.d/50-newrelic.ini' :
            ensure => file,
            content => template('scs/newrelic/50-newrelic.ini.erb'),
            mode => 0644,
            owner => 'root',
            group => 'root',
            require => [
                Exec['newrelic:module'],
            ],
            ;
        '/var/log/newrelic' :
            ensure => directory,
            mode => 0755,
            owner => 'root',
            group => 'root',
            ;
    }
}
