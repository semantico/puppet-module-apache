class apache::module::python {
    package { "libapache2-mod-python": ensure => present }
    apache::module { "python":
        require => Package["libapache2-mod-python"],
        notify => Exec["reload-apache2"]
    }
}

