# Ludus Autolabs
## SCCM
### Build Collection
```
git clone https://github.com/Synzack/Ludus-Autolabs
cd sccm
ansible-galaxy collection build
```
### Ludus Install
Ludus ansible collection
```
python3 -m http.server 80
ludus ansible collection add http://<network ip>/autolabs-sccm-1.0.0.tar.gz
```

scp
```
scp -r sccm/ root@<ludus-host>:/opt/ludus/users/<username>/.ansible/collections/ansible_collections/autolabs/
```
### Ludus Range Config
```
ludus range config set -f sccm-range-config.yml
```
