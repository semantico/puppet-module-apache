
class apache::service {

    case $operatingsystem {
        debian,ubuntu: { $apache2_service_name = "apache2"
                  $apache2_serverconfig = "/etc/apache2/apache2.conf"
                  $apache2_confdir = "/etc/apache2"
                  $vhost_enabled_dir = "/etc/apache2/sites-enabled"
                  $vhost_available_dir = "/etc/apache2/sites-available"
                  $cronolog = "/usr/bin/cronolog"
                }
        redhat,centos: { $apache2_service_name = "httpd"
                   $apache2_serverconfig = "/etc/httpd/conf/httpd.conf"
                   $apache2_confdir = "/etc/httpd/conf"
                   $vhost_enabled_dir = "/etc/httpd/sites-enabled"
                   $vhost_available_dir = "/etc/httpd/sites-available"
                   $cronolog = "/usr/sbin/cronolog"
                 }
        default: { fail("apache::service - $hostname - $operatingsystem not supported") }
    }

    File {
        owner => root,
        group => root,
        mode  => 0644,
    }

    Dir {
        owner => root,
        group => root,
        mode  => 2755,
    }

    include apache::service::control

    package { apache2:
        name => $apache2_service_name,
        ensure => $update ? {
            true    => "present",
            false    => "present",
            default => "present",
        },
    }

    service { apache2:
        name => $operatingsystem ? {
            debian  => "apache2",
            Ubuntu  => "apache2",
            default => "httpd",
        },
        ensure => running,
        enable => true,
        pattern => "${apache2_service_name}",
        hasrestart => true,
        hasstatus => true,
        require => Package["apache2"],
    }


    case $operatingsystem {
        Debian: {  include apache::service::debian }
        Ubuntu: {  include apache::service::debian }
        Redhat: {  include apache::service::redhat }
        Centos: {  include apache::service::redhat }
    }



    # CONFIG

    # Base Apache config is left as the OS default but include lines are added to allow the config to be changed

    # This file contains any parameters that you want to override using the apache::override define
    file { "apache_override.conf":
        path   => "/etc/${apache2_service_name}/apache_override.conf",
        mode    => 0440,
        notify => Exec["reload-apache2"],
        require => Package["apache2"],
    }

    #templated override for multiline server wide customizations
    file { "apache_templated_override":
        path   => "/etc/${apache2_service_name}/apache_templated_override.conf",
        content => template("apache/apache_templated_override.erb"),
        mode    => 0440,
        notify => Exec["reload-apache2"],
        require => Package["apache2"],
    }

    line { "include_ports_config":
        file => $apache2_serverconfig,
        line => "Include /etc/${apache2_service_name}/ports.conf",
        ensure => present,
        require => Package["apache2"],
    }

    line { "include_apache_override_conf":
        file => $apache2_serverconfig,
        line => "Include /etc/${apache2_service_name}/apache_override.conf",
        ensure => present,
        require => Line["include_ports_config"],
    }

    # templated override (can contain various if and case statements)
    line { "include_apache_templated_override_conf":
        file => $apache2_serverconfig,
        line => "Include /etc/${apache2_service_name}/apache_templated_override.conf",
        ensure => present,
        require => Line["include_apache_override_conf"],
    }

    # These two were both  ending up in the file, not sure how.
    # marking more complex one as absent - we do not want non-cfg files in
    # sites-enabled
    line { "include_sites_enabled_conf":
        file => $apache2_serverconfig,
        line => "Include /etc/${apache2_service_name}/sites-enabled/",
        ensure => present,
        require => Line["include_apache_templated_override_conf"],
    }
    line { "include_sites_enabled_conf-comment-absent":
        file => $apache2_serverconfig,
        line => "Include \/etc\/${apache2_service_name}\/sites-enabled\/[^.#]*",
        ensure => absent,
        require => Line["include_apache_templated_override_conf"],
    }

    #### Make rhel and debian behave in the same way
    dir { "sites-enabled":
        path   => "/etc/${apache2_service_name}/sites-enabled",
        require => Package["apache2"],
    }

    dir { "sites-available":
        path   => "/etc/${apache2_service_name}/sites-available",
        require => Package["apache2"],
    }

    ### Remove default installation options
    file { "default_welcome_conf":
        path   => "/etc/${apache2_service_name}/conf.d/welcome.conf",
        ensure => absent,
        require => Package["apache2"],
    }

    # Don't use site here, because the default site ships with a non-default symlink.
    exec { "remove-default-site":
        command => "/usr/sbin/a2dissite default",
        onlyif => "/usr/bin/test -L /etc/apache2/sites-enabled/000-default",
        notify => Exec["reload-apache2"],
        require => Package["apache2"],
    }

    #Make sure the default list on all interfaces on port 80 is removed
    line { "Listen_80_removal":
        file => "${apache2_serverconfig}",
        line => "Listen 80",
        ensure => absent,
        require => Package["apache2"],
    }

    line { "Listen_443_removal":
        file => "/etc/${apache2_service_name}/conf.d/ssl.conf",
        line => "Listen 443",
        ensure => absent,
        require => Package["apache2"],
    }

    #This file is templated to allow for namebased virtualhosting and listening on ip:port
    #When ports are updated the service needs restarting
    file { "/etc/${apache2_service_name}/ports.conf":
        ensure => present,
        content => template("apache/ports.conf"),
        mode    => 0444,
        require => Package["apache2"],
        notify => Exec["restart-apache2"],
    }

    dir { "${apache2_confdir}/ssl.prm" : require => Package["apache2"], mode => 2750 }
    dir { "${apache2_confdir}/ssl.crl" : require => Package["apache2"], mode => 2750 }
    dir { "${apache2_confdir}/ssl.crt" : require => Package["apache2"], mode => 2750 }
    dir { "${apache2_confdir}/ssl.key" : require => Package["apache2"], mode => 2750 }
    dir { "${apache2_confdir}/ssl.csr" : require => Package["apache2"], mode => 2750 }

    #compression of standard vhost logs, covers all legacy installs
    #cron per vhost?

    cron { all_apache_logs_compress:
        tag => "autoapply",
        command => "/opt/semantico/bin/compress_logs --run -p /var/log/${apache2_service_name}/cronolog/ --prune 250",
        minute => "1",
        hour => "3",
        weekday => "0",
    }

    case $operatingsystem {
        ubuntu,debian: { 
            file { "/etc/${apache2_service_name}/envvars":
                content => template('apache/envvars.erb'),
            }
        }
    }


    ###################################################
    #CUSTOMIZATIONS

    # By default add this custom log format
    apache::override { 'LogFormat "%h %l %u %t \"%r\" %>s %b %T \"%{Referer}i\" \"%{User-Agent}i\"" combined_plus_time': }

    realize Package['cronolog']

    #Standard logrotate works on the default log location, as we're using cronolog we need a new directory or
    # the logs would be rotated twice
    dir { "/var/log/${apache2_service_name}/cronolog":
        mode => 0755,
    }

    #this directory has very strict permissions on RHEL
    dir { "/var/log/${apache2_service_name}":
        mode => 0755,
    }

}

