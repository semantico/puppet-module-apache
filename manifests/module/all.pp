#defines didnt work grr
class apache::module::all {
    @apache::module { "proxy":}
    @apache::module { "proxy_balancer":}
    @apache::module { "ssl":}
    @package { mod_ssl: ensure => present } 
}