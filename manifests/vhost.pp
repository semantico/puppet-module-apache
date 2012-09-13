#3 methods

#1.Directory Structure based on vhost names with logs and public_html under this root
#set $vhost_name_structure to the base directory where you want vhost named directories to be written
#optionally set $vhost_log and $vhost_html to change them from logs and public_html

#2.Directory structure with a non-standard base dir
#$log_dir  and $html_dir

#3.system default webroot (/var/www/vhostname) and log location (/var/log/<service_name>/cronolog)
#only set $vhost_name

#todo script alias should be part of the standard module but needs 0.24


define apache::vhost (

        #############  Logging and ports and general vhost specific config options #############
        $ensure = 'present',
        $extra_apache_lines = [], #array to allow for multiple custom lines  ? remove to stop deviation from template?
        $customlog ='combined_plus_time', # custom format name, added using the apache_override define (see apache_override.pp)
        $port = 80, # sensible default
        $serveradmin = 'root@localhost', # sensible default
        $vhost_loglevel = 'warn',
        $serversignature = 'Off', #secure default
        $serveralias = '', # automatically populated with the www.vhostname
        $template_name = "apache/default_vhost.erb", #use a different template (possibly totally custom)
        $override_access_log_name = '',
        $override_error_log_name = '',

        $disallow_robots = false,
        $include_ssl_redirect_http_site = false, # set to true to create a VH that redirects to the HTTPS site

        $scriptalias = false,
        $allow = ["allow from all"],
        $allowoverride = "none",
        $options = "FollowSymLinks MultiViews",

        ##################### reverse proxy
        $proxypass = false, # e.g /tomcatapp http://192.168.1.250:9081/tomcatapp ( also enables the proxy based modules on debian )
        $directoryindex = false,
        $apache_alias = false,

        ######### load balancing (round robin?)
        #N.B proxypass is created automatically
        $balancergroup = "balancergroup", # default name of the proxy for balancing
        #n.b you still need a proxy pass line in this format "/ balancer://balancergroup:vhostport"
        $balancermember = false, #array for listing a set of BalancerMember http://127.0.0.1:16100
        $balancer_manager_allow_from = false, #if you want the balancer manager then you must lock it down
        $proxypreservehost = "Off", #needed if back end nodes need to know the original host header

        #######################
        $auth_enable = false,
        $auth_order = "allow,deny",
        $auth_type = "Basic",
        $auth_name = "",
        $auth_user_file = "",
        $auth_require_list = [ 'valid-user' ],

        #######################  webdav access
        $webdav = false,
        $webdav_alias = "/webdav",
        $webdav_dir_full = "",

        #######################  ssl
        $ssl = false, # default is to pull the files from the $cert_server_dir/vhostname.crt and .key
                      # and put them /etc/<service_name>/conf/ssl.crt/
        $manage_ssl_cert_files = true, # whether to manage ssl cert and key files - allows using the
                                       # same CN/key/cert combo for multiple VHs

        $sslcertificatefile = false, # e.g /etc/certs/selfsigned.crt
        $sslcertificatekeyfile = false, # e.g /etc/certs/selfsigned.key
        $sslcertificatefile_source = false, # e.g "BLAH.crt"
        $sslcertificatekeyfile_source = false, # e.g "BLAH.key"
        $sslcacertificatefile = false,
        $sslcarevocationfile = false,
        $sslcertificatechainfile = false,

        #options normally not required
        $sslciphersuite = false, #e.g SSLv2:-LOW:-EXPORT:RC4+RSA
        $sslverifyclient = false, # verify connecting clients?
        $sslverifydepth = false, # e.g 1 to only verify down to one level of the ssl chain, (the direct CA)
        $ssloptions = false, #e.g +StdEnvVars

        $requestheader = false,

        $vhost_listen = "", # address to listen to in the <VirtualHost xxx:port> directive
        $vhost_name_option = "",

        $log_dir =  false,
        $html_dir = false,
        $create_html_dir = true,

        $run_as_user = false,
        $run_as_group = false,

        $cert_server_dir = "/opt/semantico/data/certs"  # where we store certs on the puppetmaster
    ) {

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
        default: { }
    }

    File {
        owner => root,
        group => root,
    }

    include apache::service
 
    # N.B $apache2_service_name  is set globally...

    #this will always be unique right?

    if $vhost_name_option {
        $vhost_name = $vhost_name_option
    } else {
        $vhost_name = $title
    }

    if $vhost_listen {
        $our_vhost_listen = $vhost_listen
    } else {
        $our_vhost_listen = $vhost_name
    }

    ################## MODULE SPECIFIC ######################
    if $balancermember {
        $foo = 'bar'
        #todo test virtual defines

    }else {
        if $proxypass {
            #realize Apache::Module["proxy"]
            #realize Apache::Module["proxy_balancer"]
            $woo = 'bar'
        }
    }

    if $proxypass {
        $proxypass_real = $proxypass
    } else {
        if $balancermember {
            $proxypass_real = "/ balancer://${balancergroup}:${port}"
        } else {
            $proxypass_real = false
        }
    }

    # this switch is used to enable ssl where certificates have a standard format of vhost_name and are pulled down from
    # the puppetmaster
    if $ssl {

        include apache::module::ssl

        if $sslcertificatefile {
            $sslcertificatefile_real = $sslcertificatefile
        } else {
            $sslcertificatefile_real = "${apache2_confdir}/ssl.crt/${vhost_name}.crt"
        }

        if $sslcertificatefile_source {
            $sslcertificatefile_content = file("${cert_server_dir}/${sslcertificatefile_source}")
        } else {
            $sslcertificatefile_content = create_or_cat_ssl_file($vhost_name, "crt")
        }

        if $sslcertificatekeyfile {
            $sslcertificatekeyfile_real = $sslcertificatekeyfile
        } else {
            $sslcertificatekeyfile_real = "${apache2_confdir}/ssl.key/${vhost_name}.key"
        }

        if $sslcertificatekeyfile_source {
            $sslcertificatekeyfile_content = file("${cert_server_dir}/${sslcertificatekeyfile_source}")
        } else {
            $sslcertificatekeyfile_content = create_or_cat_ssl_file($vhost_name, "key")
        }

        if $manage_ssl_cert_files {

            file { "${sslcertificatefile_real}":
                content => "${sslcertificatefile_content}",
                mode  => 0444,
            }

            file { "${sslcertificatekeyfile_real}":
                content => "${sslcertificatekeyfile_content}",
                mode  => 0400,
            }

        }

        #enable modules based on the features being used
        case $operatingsystem {
            redhat,centos: {  
                realize Package['mod_ssl'] 
                realize File["/etc/httpd/conf.d/ssl.conf"]
            }
        }
    }

    ############### OS specific settings  for directory ownership
    if $run_as_user {
        $run_as_user_real = $run_as_user
        $run_as_group_real = $run_as_group
    } else {

        case $operatingsystem {
            debian: { $run_as_user_real = "www-data"
                      $run_as_group_real = "www-data"
            }
            Ubuntu: { $run_as_user_real = "www-data"
                      $run_as_group_real = "www-data"
            }
            redhat: { $run_as_user_real = "apache"
                      $run_as_group_real = "apache"
            }
            CentOS: { $run_as_user_real = "apache"
                      $run_as_group_real = "apache"
            }
            default: { fail("only redhat and debian supported") }
        }
    }

    # This standard log location is created by the base apache service
    # either specify the full path of logs and html directory manually or use the system defaults.
    if $log_dir {
        $log_dir_full = $log_dir
    } else {
        $log_dir_full = "/var/log/${apache2_service_name}/cronolog"
    }

    if $override_access_log_name {
        $access_log = "${log_dir_full}/${override_access_log_name}"
    } else {
        $access_log = "${log_dir_full}/${vhost_name}-access-%Y-%m-%d.log"
    }

    if $override_error_log_name {
        $error_log = "${log_dir_full}/${override_error_log_name}"
    } else {
        $error_log = "${log_dir_full}/${vhost_name}-error-%Y-%m-%d.log"
    }

    if $html_dir {
        $html_dir_full = $html_dir
    } else {
        $html_dir_full = "/var/www/${vhost_name}"
    }

    if $create_html_dir {
        file { "${html_dir_full}":
            mode => 0775,
            ensure => directory,
            owner => $run_as_user_real,
            group => $run_as_group_real,
        }
    }

    case $webdav {
        true: { include apache::module::webdav }
        default: { }
    }

    case $webdav_alias {
        "": { $our_webdav_alias = "/webdav" }
        default: { $our_webdav_alias = $webdav_alias }
    }

    case $webdav_dir_full {
        "": { $our_webdav_dir_full = "${html_dir_full}" }
        default: { $our_webdav_dir_full = $webdav_dir_full }
    }

    case $auth_type {
        Basic: { $our_auth_type = $auth_type }
        default: { fail("$hostname: apache::vhost - unsupported auth_type $auth_type") }
    }

    case $auth_name {
        "": { $our_auth_name = "${vhost_name}" }
        default: { $our_auth_name = $auth_name }
    }

    case $auth_user_file {
        "": { $our_auth_user_file = "${apache2_confdir}/htpasswd" }
        default: { $our_auth_user_file = $auth_user_file }
    }

    #Create the symbolic links to link the vhost file into the apache configuration
    #Use title not vhost_name as this needs to be unique
    case $ensure {
        'present' : {
            exec { "/bin/ln -s ${vhost_available_dir}/${title} ${vhost_enabled_dir}/${title}":
                unless => "/usr/bin/test -L ${vhost_enabled_dir}/${title}",
                notify => Exec["reload-apache2"],
                require => File["apache::vhost::config::${title}"],
            }
        }
        'absent' : {
            exec { "/bin/rm -f ${vhost_enabled_dir}/${title}":
                onlyif => "/usr/bin/test -L ${vhost_enabled_dir}/${title}",
                notify => Exec["reload-apache2"],
                require => File["apache::vhost::config::${title}"],
            }
        }
        default: { err ( "Unknown ensure value: '$ensure'" ) }
    }

    #required for the custom execs
    include apache::service::control

    #Apply the variable to this vhost erb template
    #Require the apache2 package to be installed first.
    file { "apache::vhost::config::${title}":
        path => "${vhost_available_dir}/${title}",
        content => template("$template_name"),
        mode    => 0440,
        notify => Exec["reload-apache2"],
        require => Package[apache2],
    }

    if $disallow_robots {

        file { "${html_dir_full}/robots.txt":
            content => template("apache/robots.txt"),
            mode    => 0444,
            notify => Exec["reload-apache2"],
            require => Package[apache2],
        }

    }

    apache::munin_reqtime { "${title}":
        tag => "autoapply",
        logfile => $access_log,
        opts => "-d",
        reqtime_type => "apache",
        graph_category => "${title}"
    }

    apache::munin_pagespeed_reqtime { "${title}":
        tag => "autoapply",
        logfile => $access_log,
        opts => "-d",
        reqtime_type => "apache",
        graph_category => "${title}"
    }

    apache::munin_reqs_per_sec { "${title}":
        tag => "autoapply",
        logfile => $access_log,
        opts => "-d",
        graph_category => "${title}"
    }

    apache::munin_reqs_per_sec { "${title}-500errors":
        tag => "autoapply",
        logfile => $access_log,
        opts => "-d -F /opt/semantico/bin/access_log_500_errors",
        graph_category => "${title}"
    }

    apache::munin_pagespeed_reqs_per_sec { "${title}":
        tag => "autoapply",
        logfile => $access_log,
        opts => "-d",
        graph_category => "${title}"
    }

}


