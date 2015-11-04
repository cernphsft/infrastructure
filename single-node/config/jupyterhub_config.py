
c = get_config()

# The docker instances need access to the Hub, so the default loopback port doesn't work
from IPython.utils.localinterfaces import public_ips
c.JupyterHub.hub_ip = public_ips()[0]
c.JupyterHub.port = 8000 

# SSL
#c.JupyterHub.port = 443
#pem_dir   = '/srv/jupyterhub/certs/'
#c.JupyterHub.ssl_cert = pem_dir + 'jh.crt'
#c.JupyterHub.ssl_key  = pem_dir + 'jh.pem' 

# Authenticator
c.Authenticator.admin_users = {'etejedor', 'dpiparo', 'moscicki', 'mascetti'}

# Spawner
c.JupyterHub.spawner_class = 'dockerspawner.SystemUserSpawner'
c.SystemUserSpawner.container_image = 'cernphsft/systemuser'
#c.SystemUserSpawner.read_only_volumes = { '/opt/ROOT/':'/opt/ROOT/',
#                                          '/opt/x86_64-slc6-gcc48-opt/' : '/opt/x86_64-slc6-gcc48-opt/' }
