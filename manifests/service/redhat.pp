
class apache::service::redhat {

    #GW add SSL to all redhat hosts, there is probably a better way of handling this..
    #This ssl conf file only includes the module and global config, NOT the default vhost.

    @package { mod_ssl: ensure => present }

    @file { "/etc/httpd/conf.d/ssl.conf":
        ensure => present,
        content => template("apache/ssl.conf"),
        mode    => 0444,
        require => Package["apache2"],
    }

}
