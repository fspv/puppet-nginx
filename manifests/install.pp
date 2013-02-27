class nginx::install {
    package { $nginx::params::package_name:
        ensure => installed;
    }
}

