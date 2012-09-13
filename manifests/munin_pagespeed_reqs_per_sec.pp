
define apache::munin_pagespeed_reqs_per_sec (
            $graph_title = "",
            $graph_category = "reqs_per_sec",
            $opts = "",
            $logfile
            ) {

    $plugin_name = "pagespeed-reqs-per-sec-${name}"

    @file { "/etc/munin/plugins/${plugin_name}":
        content => template("apache/munin/pagespeed_reqs_per_sec.erb"),
        mode => 0555,
        owner => root,
        group => root,
        tag => "munin_plugin",
    }

}
