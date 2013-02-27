define webserver::vhost(
        $serveraliases              = '',
        $charsetsourceenc           = 'UTF-8',
        $charsetdefault             = 'UTF-8',
        $charsetpriority            = 'UTF-8 windows-1251 koi8-r ISO-8859-5 ibm866',
        $php_default_charset        = 'UTF-8',
        $php_open_basedir           = 'httpdocs/',
        $php_safe_mode              = 0,
        $php_safe_mode_gid          = 'on',
        $user,
        $password,
        $http_base_auth             = false,
        $http_base_auth_user        = 't',
        $http_base_auth_password    = 't',
        $apache_server_admin        = $webserver::params::apache_server_admin,
        $apache_port                = $webserver::params::apache_port,
        $apache_service_log_path    = $webserver::params::apache_service_log_path,
        $nginx_service_log_path     = $webserver::params::nginx_service_log_path,
        $root_dir                   = $webserver::params::root_dir,
        $php_open_basedir_default   = $webserver::params::php_open_basedir_default,
    )
{
    user { $user:
        ##############################################################################
        ## Пользователь, являющийся владельцем всех файлов сайта на виртуальном хосте
        ## Крайне рекомендуется иметь в наличии скрипт, который обновляет права на все
        ## файлы на виртуальном хосте на $user:www-data, и права, чтобы:
        ## 1. Не возникало проблем с доступом там, где он должен быть
        ## 2. Не давался доступ там, где его быть не должно
        ##############################################################################
        ensure => present,
        comment => "User for site ${name}",
        shell => '/bin/bash',
        groups => [$webserver::params::apache_service_group, $webserver::params::nginx_service_group],
        password => $password,
        # Домашнюю директорию ставим /httpdocs, т.к. юзер будет чрутиться в директорию виртуалхоста
        # и надо, чтобы в sftp его кидало сразу в директорию с сайтом
        home => '/httpdocs/',
    }
    file { "${webserver::params::apache_service_vhosts_dir}${name}.conf":
        # Файл конфига виртуалхоста для апача
        content => template('/etc/puppet/modules/webserver/templates/apache.vhost.conf.erb'),
        owner => root,
        group => root,
        mode => '644',
        require => Class["webserver::install"],
        notify => Class["webserver::service"],
    }
    file { "${webserver::params::nginx_service_vhosts_dir}${name}.conf":
        # Файл конфига виртуалхоста для nginx
        content => template('/etc/puppet/modules/webserver/templates/nginx.vhost.conf.erb'),
        owner => root,
        group => root,
        mode => '644',
        require => Class["webserver::install"],
        notify => Class["webserver::service"],
    }

    file { "${webserver::params::root_dir}${name}":
        # Основная директория сайта. Владелец должен быть рутом и 
        # для всех остальных эта директория должна быть недоступна
        # для записи, иначе не будет работать ssh/ftp
        require => User[$user],
        ensure => directory,
        owner => "root",
        group => $webserver::params::apache_service_group,
        mode => 0755,
    }
    file { "${webserver::params::root_dir}${name}/httpdocs":
        # Директория, в которой лежит сайт.
        # Ставим 750, чтобы скрипты не могли изменять
        # файлы в корне сайта (типа .htaccess, или index.php)
        require => User[$user],
        ensure => directory,
        owner => $user,
        group => $webserver::params::apache_service_group,
        mode => 0750,
    }
    
    file { "/home/${user}":
        # Создаем домашнюю директорию пользователя, которая является
        # симлинком на корневую директорию виртуального хоста
        # Сюда будет чрутиться SSH/SFTP и FTP
        ensure => "${webserver::params::root_dir}${name}",
        require => [File["${webserver::params::root_dir}${name}"], User[$user]],
    }
    # FIXME: на каждый виртуалхост добавляется файл authorized-keys
    # надо бы как-нибудь правильнее это сделать
    file { "/home/${user}/.ssh":
        ensure => directory,
        owner =>  $user,
        group => $webserver::params::apache_service_group,
        mode => 0500,
        require => [File["${webserver::params::root_dir}${name}"], User[$user]],
    }
    file { "/home/${user}/.ssh/authorized_keys":
        ensure => present,
        owner =>  $user,
        source => 'puppet:///modules/webserver/authorized_keys',
        group => $webserver::params::apache_service_group,
        mode => 0400,
        require => [File["${webserver::params::root_dir}${name}"], User[$user]],
    }
    # END_FIXME
    if $http_base_auth {
        # FIXME: надо обновлять этот файл только при изменении пароля или изменении файла.
        # в принцие пересоздание этого файла каждый раз занимает не так много времени
        # так что относительно нормально, что делается именно так.
        exec { "${name}-htpasswd":
            path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            command => "htpasswd -bc ${webserver::params::root_dir}${name}/.htpasswd $http_base_auth_user $http_base_auth_password",
            require => File["${webserver::params::root_dir}${name}"],
        }
    }
    ###############################
    ## Создаем чрут окружение
    ## FIXME: Тут куча фигни. Пытался сделать функцию и в неё передать все нужные директории
    ## одним массивом, но тогда для каждого виртуального хоста будут функции с одинаковыми
    ## именами и паппет будет ругаться на duplicate declaration
    ###############################
    file { "${webserver::params::root_dir}${name}/usr":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    file { "${webserver::params::root_dir}${name}/lib":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/lib":
        device  => "/lib",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/lib"],
    }
    file { "${webserver::params::root_dir}${name}/lib32":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/lib32":
        device  => "/lib32",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/lib32"],
    }
    file { "${webserver::params::root_dir}${name}/lib64":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/lib64":
        device  => "/lib64",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/lib64"],
    }
    file { "${webserver::params::root_dir}${name}/bin":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/bin":
        device  => "/bin",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/bin"],
    }
    file { "${webserver::params::root_dir}${name}/sbin":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/sbin":
        device  => "/sbin",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/sbin"],
    }
    file { "${webserver::params::root_dir}${name}/usr/lib":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/usr/lib":
        device  => "/usr/lib",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/usr/lib"],
    }
    file { "${webserver::params::root_dir}${name}/usr/lib32":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/usr/lib32":
        device  => "/usr/lib32",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/usr/lib32"],
    }
    file { "${webserver::params::root_dir}${name}/usr/lib64":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/usr/lib64":
        device  => "/usr/lib64",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/usr/lib64"],
    }
    file { "${webserver::params::root_dir}${name}/usr/bin":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/usr/bin":
        device  => "/usr/bin",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/usr/bin"],
    }
    file { "${webserver::params::root_dir}${name}/usr/sbin":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/usr/sbin":
        device  => "/usr/sbin",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/usr/sbin"],
    }
    file { "${webserver::params::root_dir}${name}/etc":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    file { "${webserver::params::root_dir}${name}/etc/alternatives":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    mount { "${webserver::params::root_dir}${name}/etc/alternatives":
        device  => "/etc/alternatives",
        fstype  => 'auto',
        options => 'ro,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/etc/alternatives"],
    }
    file { "${webserver::params::root_dir}${name}/dev":
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => 0755,
    }
    file { "${webserver::params::root_dir}${name}/dev/null":
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => 0666,
    }
    mount { "${webserver::params::root_dir}${name}/dev/null":
        device  => "/dev/null",
        fstype  => 'auto',
        options => 'rw,bind',
        ensure  => mounted,
        require => File["${webserver::params::root_dir}${name}/dev/null"],
    }
}
