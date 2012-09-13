
define apache::munin_reqs_per_sec (
            $site = "",
            $graph_title = "",
            $graph_category = "reqs_per_sec",
            $opts = "",
            $logfile
            ) {

    $plugin_name = "reqs-per-sec-${name}"

    @file { "/etc/munin/plugins/${plugin_name}":
        content => template("apache/munin/reqs_per_sec.erb"),
        mode => 0555,
        owner => root,
        group => root,
        tag => "munin_plugin",
    }

}
