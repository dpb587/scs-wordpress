define scs::theme(
    $source,
) {
    exec {
        "/usr/bin/wget ${source} && /usr/bin/unzip ${name}*.zip && /bin/rm ${name}*.zip" :
            cwd => "${scs::wordpress_docroot}/wp-content/themes",
            creates => "${scs::wordpress_docroot}/wp-content/themes/${name}",
            require => [
                Exec['wordpress'],
                Package['unzip'],
            ],
            ;
    }
}
