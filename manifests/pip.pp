# == Define: python::pip
#
# Installs and manages packages from pip.
#
# === Parameters
#
# [*ensure*]
#  present|absent. Default: present
#
# [*virtualenv*]
#  virtualenv to run pip in.
#
# [*package*]
#  Name of the package to install (if installing same package to multiple virtual_envs for example)
#
# [*proxy*]
#  Proxy server to use for outbound connections. Default: none
#
# === Examples
#
# python::pip { 'flask':
#   virtualenv => '/var/www/project1',
#   proxy      => 'http://proxy.domain.com:3128',
# }
#
# === Authors
#
# Sergey Stankevich
#
define python::pip (
  $virtualenv,
  $package = unset,
  $ensure = present,
  $proxy  = false
) {
  require python

  # Parameter validation
  if ! $virtualenv {
    fail('python::pip: virtualenv parameter must not be empty')
  }

  $proxy_flag = $proxy ? {
    false    => '',
    default  => "--proxy=${proxy}",
  }

  $pip_package = $package ? {
    unset   => $name,
    default => $package
  }

  $grep_regex = $pip_package ? {
    /==/    => "^${pip_package}\$",
    default => "^${pip_package}==",
  }

  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command => "${virtualenv}/bin/pip install ${proxy_flag} ${pip_package}",
        unless  => "${virtualenv}/bin/pip freeze | grep -i -e ${grep_regex}",
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command => "echo y | ${virtualenv}/bin/pip uninstall ${proxy_flag} ${pip_package}",
        onlyif  => "${virtualenv}/bin/pip freeze | grep -i -e ${grep_regex}",
      }
    }
  }

}
