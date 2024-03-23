# Ludus Autolabs
## SCCM
### Build Collection
```
git clone https://github.com/Synzack/Ludus-Autolabs
cd sccm
ansible-galaxy collection build
```
### Ludus
```
ludus range config set -f sccm-range-config.yml
```
