
# → build + mise à jour

```
$ vagrant destroy -f 
$ rm noble64-updated.box
$ vagrant up       
$ vagrant halt      
$ vagrant package --output noble64-updated.box
$ vagrant box add noble64-updated noble64-updated.box [--force]
```

Dans le Vagrantfile principal:

```
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "noble64-updated"
```
