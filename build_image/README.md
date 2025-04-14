
# → build + mise à jour

```
$ vagrant destroy -f 
$ rm jammy64-updated.box
$ vagrant up       
$ vagrant halt      
$ vagrant package --output jammy64-updated.box
$ vagrant box add jammy64-updated jammy64-updated.box [--force]
```

Dans le Vagrantfile principal:

```
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "jammy64-updated"
```
