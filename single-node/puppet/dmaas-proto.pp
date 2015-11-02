###### Global exec path ######

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }


###### Firewall ######

firewall { '100 allow https access':
  dport   => [4443],
  proto  => tcp,
  action => accept,
}

firewall { '101 forward port 443 to 4443':
  table   => 'nat',
  chain   => 'PREROUTING',
  proto   => 'tcp',
  dport   => '443',
  jump    => 'REDIRECT',
  toports => '4443',
  require => Firewall['100 allow https access']
}


###### Packages ######
# Python --> 'zlib-devel', 'openssl-devel', 'sqlite-devel'

$packages = [ 'docker-io', 'zlib-devel', 'openssl-devel', 'sqlite-devel', 'git' ]
package { $packages:
  ensure => installed,
}


###### Docker ######

service { 'docker':
  ensure  => running,
  enable  => true,
  require => [ Package[$packages] ]
}


###### Apache HTTP server ######

docker::image { 'httpd':
  require => [ Service['docker'] ],
}

docker::run { 'Apache-HTTP':
  image        => 'httpd',
  ports        => ['4443:80'],
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
}

wget::fetch { 'Pip script':
  source      => 'https://bootstrap.pypa.io/get-pip.py',
  destination => "${tmpdir}get-pip.py",
}

exec { 'Install Pip3':
  command => "python3 ${tmpdir}get-pip.py",
  require => Wget::Fetch['Pip script'],
}


###### JupyterHub & Docker Spawner ######

$dspawnerdir = "${tmpdir}dockerspawner"
vcsrepo { $dspawnerdir:
  ensure   => present,
  provider => git,
  source   => 'https://github.com/jupyter/dockerspawner',
}

exec { 'Install JupyterHub':
  cwd     => $dspawnerdir,
  command => 'pip3 install -r requirements.txt',
}

exec { 'Install Docker Spawner':
  cwd     => $dspawnerdir,
  command => 'python3 setup.py install',
}

