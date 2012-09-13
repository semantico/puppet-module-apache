
class apache::service::debian {

    file { "/etc/default/apache2":
        ensure => present,
        content => template("apache/apache2_default.erb"),
        mode    => 0444,
        require => Package["apache2"],
    }

}
