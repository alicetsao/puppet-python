# Create virtual environments with virtualenvwrapper
#
# Usage:
#
#     in one of your classes...
#     python::mkvirtualenv{ 'name_of_venv':
#       ensure      => present,
#       systempkgs  => false,
#       distribute  => true,
#       project_dir => "path_to_associated_project"
#     }
#
#
# Parameter:
#   [ensure]
#     Must be present or absent. Default: present
#   [systempkgs]
#     true or false. Determines whether or not to enable the global site
#     pacakges. Default: false
#   [distribute]
#     true or false. Determines if Setuptools or Distribute is installed.
#     Default: true
#   [project_dir]
#     string. Set the project directory associated with venv being created.
#     Default: undef
#   [post_activate]
#     Set to a puppet:///file to set a postactivate script for the env
#   [post_deactivate]
#     Set to a puppet:///file to set a postdeactivate script for the env
#   [python_exe]
#     Which python interpreter to use (defaults to standard python)
#
# Notes:
#   The project does not have to exist before creating the virutal env, but if
#   it's not created by the end of the run activating the venv will throw nasty
#   errors.


define python::mkvirtualenv (
  $ensure          = present,
  $systempkgs      = false,
  $distribute      = true,
  $project_dir     = undef,
  $post_activate   = undef,
  $post_deactivate = undef,
  $python_exe      = undef
){
  require python

  $venv_path = "${python::config::venv_home}/${name}"
  case $ensure {
    'present': {
      $mkvenv_proj = $project_dir ? {
        undef   => '',
        default => "-a ${project_dir}"
      }

      $mkvenv_python_exe = $python_exe ? {
        undef   => '',
        default => "-p ${python_exe}"
      }

      $mkvenv_syspkg = $systempkgs ? {
        true    => '--system-site-packages',
        default => ''
      }


      exec{ "python_mkvirtualenv_${name}":
        command  => "env -i bash -c 'source ${boxen::config::home}/env.sh && \
          mkvirtualenv ${mkvenv_proj} ${mkvenv_syspkg} ${mkvenv_python_exe} ${name}'",
        provider => 'shell',
        user     => $::boxen_user,
        creates  => $venv_path,
        require  => [File["${boxen::config::envdir}/python_venvwrapper.sh"],
          Class['python::virtualenvwrapper']]
      }
      if $post_activate {
        file{ "python_mkenv_${name} postactivate":
          ensure  => present,
          path    => "${venv_path}/bin/postactivate",
          owner   => $::luser,
          mode    => '0755',
          require => Exec["python_mkvirtualenv_${name}"],
          content => $post_activate
        }
      }
      if $post_deactivate {
        file{ "python_mkenv_${name} postdeactivate":
          ensure  => present,
          path    => "${venv_path}/bin/postdeactivate",
          owner   => $::luser,
          mode    => '0755',
          require => Exec["python_mkvirtualenv_${name}"],
          content => $post_deactivate
        }
      }
    }
    'absent' : {
      if !defined(File[$venv_path]){
        file { $venv_path:
          ensure  => absent,
          recurse => true,
          force   => true,
          backup  => false
        }
      }
    }
    default: { fail('Invalid ensure option') }
  }
}
