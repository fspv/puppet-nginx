class nginx::service {
    service { $nginx::params::service_name:
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["nginx::config"],
    }
}
