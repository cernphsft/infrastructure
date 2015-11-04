
c = get_config()

# The docker instances need access to the Hub, so the default loopback port doesn't work
from IPython.utils.localinterfaces import public_ips
c.JupyterHub.hub_ip = public_ips()[0]
c.JupyterHub.port = 8000 

# Spawner
c.JupyterHub.spawner_class = 'dockerspawner.SystemUserSpawner'
c.SystemUserSpawner.container_image = 'cernphsft/systemuser'
