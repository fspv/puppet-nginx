define nginx::vhost(
        $serveraliases              = '',
        $root_dir                   = $nginx::params::root_dir,
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
