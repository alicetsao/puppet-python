# Equivelent to pip install -e [directory], which is similar to
# python setup.py develop
#
# Usage:
#
#     in one of your classes...
#     python::pip_develop{ 'name_of_venv':
#       virtualenv => "my_venv"
#     }
#
# Parameter:
#   [virtualenv]
#     Name of the virutal env to use (from python::mkvirtualenv)
#
#   [path]
#     *DEPRECATED*
#     The base path of where to find [name], e.g. the leading path component.
#     E.g. a repo at /home/someuser/workspace/shiney would have path set to
#     /home/pcollins/workspace
#     This made it hard to pip develop a single py_module in multiple virtual
#     envs. Use full_path instead
#
#   [full_path]
#     The full path to the py_module to install in the virtaulenv
#
#   [package_name]
#     The name of the py_module you're installing (defaults to $name)
#
#   [optional_depends]
#     String to use for optional dependancies
#     For example to get something like "pip install sentry[mysql,dev]" set
#     optional_depends => "mysql,dev"

define python::pip_develop (
  $virtualenv,
  $full_path        = undef,
  $force            = false,
  $package_name     = undef,
  $optional_depends = undef,
  $path             = undef,
  $timeout          = 300
){
  require python

  $venv_path = "${python::config::venv_home}/${virtualenv}"

  $py_module_path = $full_path ? {
    undef => "${path}/${name}",
    default => $full_path
  }

  $py_module_name = $package_name ? {
    undef => $name,
    default => $package_name
  }

  $py_module_optional_depends = $optional_depends ? {
    undef => '',
    default => "[${optional_depends}]"
  }

  case $force {
    true:  {
      exec{ "pip install -e ${name}":
        cwd      => $py_module_path,
        command  => "env -i bash -c 'source ${boxen::config::home}/env.sh && \
          source ${venv_path}/bin/activate && \
          pip install -e .${py_module_optional_depends}'",
        provider => 'shell',
        user     => $::boxen_user,
        require  => Class['python::virtualenvwrapper'],
        timeout  => $timeout
      }
    }
    default: {
      exec{ "pip install -e ${name}":
        cwd      => $py_module_path,
        command  => "env -i bash -c 'source ${boxen::config::home}/env.sh && \
          source ${venv_path}/bin/activate && \
          pip install -e .${py_module_optional_depends}'",
        provider => 'shell',
        user     => $::boxen_user,
        creates => "${venv_path}/lib/python2.7/site-packages/${py_module_name}.egg-link",
        require => Class['python::virtualenvwrapper'],
        timeout => $timeout
      }
    }
  }
}
