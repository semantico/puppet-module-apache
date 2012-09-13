
class apache::module::proxy {
    apache::module { "proxy": }
    apache::module { "proxy_http": }
    apache::module { "proxy_balancer": }
}

