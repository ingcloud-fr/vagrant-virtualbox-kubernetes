
# → build + mise à jour



```
$ cd build_image_jammy
$ vagrant destroy -f      # if needed
$ rm jammy64-updated.box  # if needed
$ vagrant up       
$ vagrant halt      
$ vagrant package --output jammy64-updated.box
$ vagrant box add jammy64-updated jammy64-updated.box [--force]
```

Dans le Vagrantfile principal:

```
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "jammy64-updated"
```
