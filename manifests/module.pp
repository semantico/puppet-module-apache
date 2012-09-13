# Define an apache2 module. Debian packages place the module config
# into /etc/apache2/mods-available.

define apache::module ( 
    $ensure = 'present',
    $load_file = "",    # template to use as the 'module loader' 
                        # in /etc/apache2/mods-available, 
                        # if not supplied by package
    $conf_file = ""     # as above, but for conf file.
    ) {

    #needed for the custom per distro notifies
    include apache::service::control

    $mods = "${apache2_confdir}/mods"
    
    case $operatingsystem {
        debian,Ubuntu: {
            apache::module::debian { "${name}":
                ensure => $ensure,
                conf_file => $conf_file,
                load_file => $load_file,
            }
        }

        redhat,centos: { 
            #TODO test for module lines in rhel httpd.conf 
            warning("$hostname: apache::module does nothing on RHEL/CentOS - this is likely not doing what you expect!")
        }

        default: { fail("$hostname: apache::module not supported on $operatingsystem") }
    }

}

