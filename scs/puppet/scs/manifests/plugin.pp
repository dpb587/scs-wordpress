define scs::plugin(
    $source_tar = undef,
    $source_tgz = undef,
    $source_zip = undef,
) {
    if undef != $source_tar {
        $source = $source_tar
        $command = '/usr/bin/wget -qO- "$DOWNLOAD" | /bin/tar -x --strip-components 1'
    } elsif undef != $source_tgz {
        $source = $source_tgz
        $command = '/usr/bin/wget -qO- "$DOWNLOAD" | /bin/tar -xz --strip-components 1'
    } elsif undef != $source_zip {
        $source = $source_zip
        $command = '/usr/bin/wget "$DOWNLOAD" && /usr/bin/unzip -d .scstmp `basename "$DOWNLOAD"` && /bin/mv .scstmp/*/* ./ && /bin/rm -fr `basename "$DOWNLOAD"` .scstmp'
    }

    file {
        "${scs::wordpress_docroot}/wp-content/plugins/${name}" :
            owner => 'scs',
            group => 'scs',
            mode => 0755,
            ;
    }

    exec {
        "${name}:download" :
            command => $command,
            environment => [
                "DOWNLOAD=${source}",
            ],
            cwd => "${scs::wordpress_docroot}/wp-content/plugins/${name}",
            creates => "${scs::wordpress_docroot}/wp-content/plugins/${name}/${name}.php",
            require => [
                File["${scs::wordpress_docroot}/wp-content/plugins/${name}"],
                Exec['wordpress'],
                Package['unzip'],
            ],
            ;
    }
}
