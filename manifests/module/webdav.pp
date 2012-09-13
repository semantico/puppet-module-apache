
class apache::module::webdav {

    apache::module { "dav": }
    apache::module { "dav_fs": }
    apache::module { "dav_lock": }

}

