define scs::plugin(
    $source,
) {
    exec {
        "/usr/bin/wget ${source} && /usr/bin/unzip ${name}*.zip && /bin/rm ${name}*.zip" :
            cwd => "${scs::wordpress_docroot}/wp-content/plugins",
            creates => "${scs::wordpress_docroot}/wp-content/plugins/${name}",
            require => [
                Exec['wordpress'],
                Package['unzip'],
            ],
            ;
    }
}
