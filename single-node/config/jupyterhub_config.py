
c = get_config()

# The docker instances need access to the Hub, so the default loopback port doesn't work
from IPython.utils.localinterfaces import public_ips
c.JupyterHub.hub_ip = public_ips()[0]
c.JupyterHub.port = 443 

# SSL
admin_user = 'jhadmin'
pem_file   = '/home/' + admin_user + '/certs/mycert.pem'
c.JupyterHub.ssl_cert = pem_file
c.JupyterHub.ssl_key  = pem_file

# Authenticator
c.Authenticator.admin_users = {admin_user}

# Spawner
c.JupyterHub.spawner_class = 'dockerspawner.SystemUserSpawner'
c.SystemUserSpawner.container_image = 'cernphsft/systemuser'
#c.SystemUserSpawner.read_only_volumes = { '/opt/ROOT/':'/opt/ROOT/',
#                                          '/opt/x86_64-slc6-gcc48-opt/' : '/opt/x86_64-slc6-gcc48-opt/' }
