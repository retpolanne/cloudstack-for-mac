# cloudstack-for-mac

Getting Cloudstack up and running on a Mac with Vagrant, Ansible, [Tart](https://tart.run) and [Nested Virtualization](https://developer.apple.com/documentation/virtualization/vzgenericplatformconfiguration/isnestedvirtualizationsupported).

We're using [Vagrant Tart](https://letiemble.github.io/vagrant-tart/) as the plugin
for vagrant.

## Usage

``` sh
# Install dependencies
make install

# Start up machines
make up

# If you want to update the ansible deployment
make deploy

# Stopping VMs
make halt

# Destroying VMs
make destroy
```

## How does it work

It creates two VMs using Vagrant, one with nested support (which exposes `/dev/kvm`)
so that we can have a Cloudstack Management VM and a Hypervisor VM. Vagrant then
calls Ansible to provision everything.

Tart is very handy due to how it talks to the Virtualization.framework 
provided by Apple. This framework allows for nested virtualization on 
newer macOS versions.

You can always edit Vagrantfile for what fits you best.
