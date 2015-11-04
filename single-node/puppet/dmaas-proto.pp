###### Global exec path ######

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }


###### Firewall ######

firewall { '100 allow https access':
  dport  => 4443,
  proto  => tcp,
  action => accept,
}

firewall { '101 forward port 443 to 4443':
  table   => nat,
  chain   => PREROUTING,
  proto   => tcp,
  dport   => 443,
  jump    => REDIRECT,
  toports => 4443,
  require => Firewall['100 allow https access']
}


###### Packages ######
# Docker     --> docker-io
# JupyterHub --> npm
# Python     --> zlib-devel, openssl-devel, sqlite-devel

$packages = [ 'docker-io', 'zlib-devel', 'openssl-devel', 'sqlite-devel', 'git', 'npm' ]
package { $packages:
  ensure => installed,
}


###### Docker ######

service { 'docker':
  ensure  => running,
  enable  => true,
  require => Package[$packages],
}


###### Apache HTTP server ######

docker::image { 'httpd':
  require => Service['docker'],
}

#$apacheconfig = 'httpd.conf'
#wget::fetch { 'Apache config':
#  source      => "http://raw.githubusercontent.com/cernphsft/infrastructure/master/single-node/config/$apacheconfig",
#  destination => "${tmpdir}${apacheconfig}",
#}

# -- TODO: Inject configuration into the container
docker::run { 'Apache-HTTP':
  image        => 'httpd',
  ports        => ['4443:80'],
  #volumes     => "${tmpdir}${apacheconfig}:/...."
  require      => Docker::Image['httpd'],
}


###### Python3 & Pip3 ######

$tmpdir    = '/tmp/'
$pythontar = "${tmpdir}Python-3.5.0.tgz"
$pythondir = "${tmpdir}Python-3.5.0/"
$gcc49     = '/afs/cern.ch/sw/lcg/contrib/gcc/4.9/x86_64-slc6/setup.sh'

wget::fetch { 'Python3':
  source      => 'https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz',
  destination => $pythontar,
  timeout     => 0,
  notify      => Exec['Unpack Python3'],
}

exec { 'Unpack Python3':
  command => "tar xvzf $pythontar",
  cwd     => $tmpdir,
  notify  => Exec['Install Python3'],
}

exec { 'Install Python3':
  cwd     => $pythondir,
  command => "bash -c 'source $gcc49 && ${pythondir}configure && make && make install'",
  require => Package[$packages],
}

wget::fetch { 'Pip script':
  source      => 'https://bootstrap.pypa.io/get-pip.py',
  destination => "${tmpdir}get-pip.py",
}

exec { 'Install Pip3':
  command => "python3 ${tmpdir}get-pip.py",
  require => [ Exec['Install Python3'], Wget::Fetch['Pip script'] ],
}


###### JupyterHub ######

$jhdir  = '/srv/jupyterhub/'
file { $jhdir:
  ensure => directory,
}

# Required by jupyterhub_config.py 
exec { 'Install IPython':
  command => 'pip3 install ipython==3.2',
#  require => Exec['Install Pip3'],
}

exec { 'Install configurable-http-proxy':
  command => 'npm install -g configurable-http-proxy',
  require => Package[$packages],
}

exec { 'Install JupyterHub':
  cwd     => $dspawnerdir,
  command => 'pip3 install jupyterhub',
#  require => Exec['Install Pip3'],
}

$jhconfig = 'jupyterhub_config.py'
wget::fetch { 'Jupyterhub config':
  source      => "http://raw.githubusercontent.com/cernphsft/infrastructure/master/single-node/config/$jhconfig",
  destination => "${jhdir}${jhconfig}",
  require     => File[$jhdir],
}


###### Docker Spawner ######

$dspawnerdir = "${jhdir}dockerspawner"
vcsrepo { $dspawnerdir:
  ensure   => present,
  provider => git,
  source   => 'https://github.com/jupyter/dockerspawner',
  require  => File[$jhdir],
}

exec { 'Install Docker Spawner dependencies':
  cwd     => $dspawnerdir,
  command => 'pip3 install -r requirements.txt',
  require => Vcsrepo[$dspawnerdir],
}

exec { 'Install Docker Spawner':
  cwd     => $dspawnerdir,
  command => 'python3 setup.py install',
  require => [ Exec['Install JupyterHub'], Exec['Install Docker Spawner dependencies'] ],
}


###### JupyterHub Server ######
exec { 'Run JupyterHub':
  cwd     => $jhdir,
  command => "nohup jupyterhub --config ${jhdir}${jhconfig} &",
  require => [ Exec['Install IPython'], Exec['Install JupyterHub'], Wget::Fetch['Jupyterhub config'] ],
}
