
define apache::munin_pagespeed_reqtime (
            $graph_title = "",
            $graph_category = "reqtime",
            $reqtime_type = "",
            $opts,
            $logfile
            ) {


    $plugin_name = "pagespeed-reqtime-${name}"

    @file { "/etc/munin/plugins/${plugin_name}":
        content => template("apache/munin/reqtime.erb"),
        mode => 0555,
        owner => root,
        group => root,
        tag => "munin_plugin",
    }

}
