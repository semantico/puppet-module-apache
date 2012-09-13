# optional server context overrides    

define apache::override (
               $ensure = "present"
             )  {
   
    line { "_apache_context_override_$title":
            file => "/etc/${apache2_service_name}/apache_override.conf",
            line => "$title",
            ensure => $ensure,
            require => File["/etc/${apache2_service_name}/apache_override.conf"],
    }    
}    

