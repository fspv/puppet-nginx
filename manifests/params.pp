class nginx::params {
    # Default apache port can be overwritten in main class
    $apache_port                              = $nginx::apache_port
    # nginx.conf params
    $worker_processes                         = 8 #number of proccessors (cores)
    $worker_connections                       = 1024

    $default_type                             = 'application/octet-stream'
    $server_names_hash_bucket_size            = 512
    $sendfile                                 = on
    $keepalive_timeout                        = 30
    $server_tokens                            = off

    $gzip                                     = on
    $gzip_min_length                          = 10
    $gzip_buffers                             = '64 8k'
    $gzip_comp_level                          = 9
    $gzip_http_version                        = '1.0'
    $gzip_proxied                             = any
    $gzip_types                               = 'text/plain application/xml application/x-javascript text/css text/html'


    # system-specific parameters
    case $operatingsystem {
        'Debian','Ubuntu': {
            # Nginx package
            $package_name                     = 'nginx'
            # name of Nginx service (in /etc/init.d)
            $service_name                     = 'nginx'
            
            $service_dir                      = '/etc/nginx'
            $service_404_page                 = '/etc/nginx/404.html'
            $service_config                   = '/etc/nginx/nginx.conf'
            $service_mime_types               = '/etc/nginx/mime.types'
            $service_log_path                 = '/var/log/nginx/'
            $service_vhosts_dir               = '/etc/nginx/vhosts/'
            $service_user                     = 'www-data'
            $service_group                    = 'www-data'

            $root_dir                               = '/var/www/'
        }
    }
}
