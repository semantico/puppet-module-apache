class apache::module::wsgi {
    package { "libapache2-mod-wsgi": ensure => present }
    apache::module { "wsgi":
        require => Package["libapache2-mod-wsgi"],
        notify => Exec["reload-apache2"]
    }
}

