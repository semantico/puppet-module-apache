
define apache::module::debian ( 
    $ensure = 'present',
    $load_file = "",    # template to use as the 'module loader' 
                        # in /etc/apache2/mods-available, 
                        # if not supplied by package
    $conf_file = ""     # as above, but for conf file.
    ) {

    $mods = "${apache2_confdir}/mods"

    if $conf_file {
        file { "${mods}-available/${name}.conf":
            content => template("apache/${conf_file}"),
            mode    => 0555,
            owner   => root,
            group   => root,
            before  => Exec["apache-module-enable-$name"],
        }
    }

    if $load_file {
        file { "${mods}-available/${name}.load":
            content => template("apache/${load_file}"),
            mode    => 0555,
            owner   => root,
            group   => root,
            before  => Exec["apache-module-enable-$name"],
        }
    }

    case $ensure {
        'present' : {
            exec { "apache-module-enable-$name":
                command => "/usr/sbin/a2enmod $title",
                unless => "/bin/sh -c '[ -L ${mods}-enabled/${name}.load ] \\
                            && [ ${mods}-enabled/${name}.load -ef ${mods}-available/${name}.load ]'",
                notify => Exec["force-reload-apache2"],
                require => Package[apache2],
            }
        }
        'absent': {
            exec { "/usr/sbin/a2dismod $title":
                onlyif => "/bin/sh -c '[ -L ${mods}-enabled/${name}.load ] \\
                          && [ ${mods}-enabled/${name}.load -ef ${mods}-available/${name}.load ]'",
                notify => Exec["force-reload-apache2"],
                require => Package["apache2"],
            }
        }
        default: { err ( "Unknown ensure value: '$ensure'" ) }
    }

}
