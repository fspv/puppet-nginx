# Module generates for every site configs for apache and nginx
# and creates directory for document root.
# It assumes, that you need pure html site or php
# 100% works only on Debian Squeeze (6.0)
class nginx (
    $apache_port = 8080,
)
{
    require nginx::params
    include nginx::install, nginx::config, nginx::service
}
