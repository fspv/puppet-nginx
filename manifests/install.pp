class webserver::install {
    package { $webserver::params::nginx_package_name:
        ensure => installed;
    }
    package { $webserver::params::apache_package_name:
        ensure => installed,
    }
    package { $webserver::params::mod_security_package_name:
        ensure => installed,
    }
    package { $webserver::params::mod_rpaf_package_name:
        ensure => installed,
    }
    package { $webserver::params::mod_php_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_cli_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_mysql_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_suhosin_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_ldap_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_gd_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_apc_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_curl_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_pgsql_package_name:
        ensure => installed,
    }
    package { $webserver::params::php_xml_packages:
        ensure => installed,
    }
    package { $webserver::params::proftpd_package_name:
        ensure => installed,
    }
    # Instals
    file { "/tmp/${webserver::params::php_xhprof_package}":
        owner   => root,
        group   => root,
        mode    => 644,
        ensure  => present,
        source  => "puppet:///modules/webserver/${webserver::params::php_xhprof_package}"
    }
    package { "php5-xhprof":
        provider => dpkg,
        ensure   => latest,
        source   => "/tmp/${webserver::params::php_xhprof_package}",
        require  => File["/tmp/${webserver::params::php_xhprof_package}"],
    }
}

