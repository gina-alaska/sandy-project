# Sandy Development

## Getting Started

Clone this repository to your workstation

### Required Tools

* [ChefDK](http://downloads.getchef.com/chef-dk/)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](http://vagrantup.com/downloads.html)
* Vagrant Omnibus
* Vagrant Cachier
* Vagrant Berkshelf

#### Installation
Follow installation instructions for ChefDK, VirtualBox and Vagrant for your platform

#### Plugin Installation
```
vagrant plugin install vagrant-omnibus
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-berkshelf --plugin-version '>= 2.0.1'
```
#### Setting up your environment
```
eval "$(chef shell-init bash)"
```

### Starting your Virtual Machine

In the root of the repository (this will take a while the first time):
```
vagrant up
```

### Log in to your Virtual Machine
```
vagrant ssh
```

The sandy project is made available to you under 'sandy-project' in your home directory.
