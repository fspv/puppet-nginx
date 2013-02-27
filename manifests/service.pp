class webserver::service {
    service { $webserver::params::nginx_service_name:
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["webserver::config"],
    }
    service { $webserver::params::apache_service_name:
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["webserver::config"],
    }
    service { $webserver::params::proftpd_service_name:
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["webserver::config"],
    }
}
