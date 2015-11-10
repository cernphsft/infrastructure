
c = get_config()

# The docker instances need access to the Hub, so the default loopback port doesn't work:
from IPython.utils.localinterfaces import public_ips
c.JupyterHub.hub_ip = public_ips()[0]
c.JupyterHub.port = 4443

certdir = '/srv/jupyterhub/certs/'
c.JupyterHub.ssl_cert = certdir + 'jhcert.crt'
c.JupyterHub.ssl_key  = certdir + 'jhkey.key'

# Authenticator
c.Authenticator.admin_users = {'notebook'}

# Spawner
c.JupyterHub.spawner_class = 'dockerspawner.SystemUserSpawner'
c.SystemUserSpawner.container_image = 'jupyter/systemuser'
c.SystemUserSpawner.read_only_volumes = { '/opt/ROOT':'/opt/ROOT' }
