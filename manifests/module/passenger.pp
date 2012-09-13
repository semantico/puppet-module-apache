
class apache::module::passenger {

    package { "libapache2-mod-passenger":
        ensure => present,
    }

    apache::module { "passenger": 
        require => Package["libapache2-mod-passenger"],
        notify => Exec["reload-apache2"]
    }

}

