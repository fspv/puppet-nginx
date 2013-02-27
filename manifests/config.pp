class nginx::config {
    # NGINX configuration
    file { $nginx::params::service_config:
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 0440,
        content => template("nginx/nginx.conf.erb"),
        require => Class["nginx::install"],
        notify => Class["nginx::service"],
    }
    file { $nginx::params::service_mime_types:
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 0440,
        source => 'puppet:///modules/nginx/nginx.mime.types',
        require => Class["nginx::install"],
        notify => Class["nginx::service"],
    }
    file { $nginx::params::service_404_page:
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 0440,
        source => 'puppet:///modules/nginx/404.html',
        require => Class["nginx::install"],
        notify => Class["nginx::service"],
    }

    file { $nginx::params::service_log_path:
        ensure => directory,
        owner => "root",
        group => "root",
        recurse => true,
        mode => 0755,
        require => Class["nginx::install"],
    }
    logrotate::rule { "nginx":
        path => "${nginx::params::service_log_path}*.log",
        rotate => 5,
        minsize => '512k',
        size => '1024k',
        missingok => true,
        compress => true,
        create => true,
        create_mode => 0755,
        create_owner => 'root',
        create_group => 'root',
        sharedscripts => true,
        postrotate => '[ ! -f /var/run/nginx.pid ] || kill -USR1 $(cat /var/run/nginx.pid)',
    }
    file { $nginx::params::service_vhosts_dir:
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
        require => Class["nginx::install"],
        notify => Class["nginx::service"],
    }
}
