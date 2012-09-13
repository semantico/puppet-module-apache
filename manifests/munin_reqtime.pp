
define apache::munin_reqtime (
            $graph_title = "",
            $graph_category = "reqtime",
            $reqtime_type = "",
            $opts,
            $logfile
            ) {

    if $reqtime_type {
        $base = "reqtime-${reqtime_type}"
    } else {
        $base = "reqtime"
    }

    @file { "/etc/munin/plugins/${base}-${title}":
        tag => "munin_plugin",
        content => template("apache/munin/reqtime.erb"),
        mode => 0555,
        owner => root,
        group => root,
    }

}
