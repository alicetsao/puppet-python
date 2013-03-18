# Installs and manages Python packages from requirements file.
#
# Useage:
#
# include python
#
# python::requirements {
#   requirements => 'requirements/file.txt'
#   virtualenv   => 'path/to/virtual/env'
#   proxy        => 'proxy to use for outbound connections if needed' (optional)
# }

define python::requirements (
  $requirements = $name,
  $virtualenv   = undef,
  $proxy        = false
) {

  $base_env = "${python::config::venv_home}/${virtualenv}"
  $pip_env = "${base_env}/bin/pip"

  $proxy_flag = $proxy ? {
    false    => '',
    default  => "--proxy=${proxy}",
  }

  # This will ensure multiple python::virtualenv definitions can share the
  # the same requirements file.
  if !defined(File[$requirements]) {
    file { $requirements:
      ensure  => present,
      replace => false,
      content => '# Puppet will install and/or update pip packages listed here',
    }
  }

  exec { "python_requirements_update_${name}":
    command => "${pip_env} install ${proxy_flag} -Ur ${requirements}",
    cwd     => $base_env,
    require => File[$requirements]
  }
}