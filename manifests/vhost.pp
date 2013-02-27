define nginx::vhost(
        $serveraliases              = '',
        $apache_port                = 8080,
        $http_base_auth             = false,
        $root_dir                   = $nginx::params::root_dir,
        $service_log_path           = $nginx::params::service_log_path,
    )
{
    file { "${nginx::params::service_vhosts_dir}${name}.conf":
        # Файл конфига виртуалхоста для nginx
        content => template('/etc/puppet/modules/nginx/templates/nginx.vhost.conf.erb'),
        owner => root,
        group => root,
        mode => '644',
        require => Class["nginx::install"],
        notify => Class["nginx::service"],
    }
}
