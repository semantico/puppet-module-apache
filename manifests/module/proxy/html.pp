
class apache::module::proxy::html {

    include apache::module::proxy
    case $operatingsystem {
        debian,ubuntu: {
            package { "libapache2-mod-proxy-html": }
            apache::module { "proxy_html": 
                require => Package["libapache2-mod-proxy-html"],
            }
        }
        default: { fail("apache::module::proxy::html - $operatingsystem not supported") }
    }

}
