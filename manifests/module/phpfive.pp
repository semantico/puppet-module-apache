#N.B Redhat package is realized in the vhost config
class apache::module::phpfive {
    include php5
    apache::module { "php5": }
}

