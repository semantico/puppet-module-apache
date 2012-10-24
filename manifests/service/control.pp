
class apache::service::control inherits apache::config {

        exec { "reload-apache2":
                command => "/etc/init.d/${apache2_service_name} reload",
                refreshonly => true,
                before => [ Service["apache2"], Exec["force-reload-apache2"] ],
        }

        exec { "force-reload-apache2":
                command => "/etc/init.d/${apache2_service_name} force-reload",
                refreshonly => true,
                before => Service["apache2"],
        }


        exec { "restart-apache2":
                command => "/etc/init.d/${apache2_service_name} restart",
                refreshonly => true,
                before => Service["apache2"],
        }
}

