
class apache::module::pagespeed {

    package { "mod-pagespeed-beta":
        ensure => present,
    }

    apache::module { "pagespeed": 
        conf_file => "pagespeed.conf.erb",
        require => Package["mod-pagespeed-beta"],
        notify => Exec["reload-apache2"]
    }

    @file { "/etc/munin/plugin-conf.d/pagespeed":
        tag   =>        "munin_plugin",
        owner =>        root,
        group =>        root,
        mode =>         444,
        content =>      "[pagespeed-*]\nuser root\n",
        require =>      Class["munin::node"]
    }

}

