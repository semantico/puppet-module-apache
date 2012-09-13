class apache::module::ldap {
    apache::module { "authnz_ldap": }
    apache::module { "ldap": }
}

