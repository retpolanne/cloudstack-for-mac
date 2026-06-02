# Nested VMs Vagrant 

Getting Nested VMs up and running on a Mac with Vagrant, Ansible, [Tart](https://tart.run) and [Nested Virtualization](https://developer.apple.com/documentation/virtualization/vzgenericplatformconfiguration/isnestedvirtualizationsupported).

We're using [Vagrant Tart](https://letiemble.github.io/vagrant-tart/) as the plugin
for vagrant.

## Usage

``` sh
# Install dependencies
make install

# Start up machines
# Use ANSIBLE_ASK_VAULT_PASS if you want to ask for vault password
ANSIBLE_PLAYBOOK_DRIVER=/path/to/ansible/driver.yml \
    ANSIBLE_PLAYBOOK_WORKER=/path/to/ansible/worker.yml \
    ANSIBLE_ASK_VAULT_PASS=true \
    make up

# If you want to update the ansible deployment
ANSIBLE_PLAYBOOK_DRIVER=/path/to/ansible/driver.yml \
    ANSIBLE_PLAYBOOK_WORKER=/path/to/ansible/worker.yml \
    ANSIBLE_ASK_VAULT_PASS=true \
    make deploy

# Stopping VMs
ANSIBLE_PLAYBOOK_DRIVER=/path/to/ansible/driver.yml \
    ANSIBLE_PLAYBOOK_WORKER=/path/to/ansible/worker.yml \
    ANSIBLE_ASK_VAULT_PASS=true \
    make halt

# Destroying VMs
ANSIBLE_PLAYBOOK_DRIVER=/path/to/ansible/driver.yml \
    ANSIBLE_PLAYBOOK_WORKER=/path/to/ansible/worker.yml \
    ANSIBLE_ASK_VAULT_PASS=true \
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

### Networking between VMs

We use `--net-bridged` to connect using the `Wi-Fi` interface. Please change to
`en0` or `en1` to use whichever interface you may be using.

The VM IPs resolve by using
a trigger with the `agent` resolver, as per [this issue](https://github.com/cirruslabs/tart/issues/1020#issuecomment-3152128883).

## Troubleshooting

On the first run, you might see:

``` sh
==> driver: Running action triggers before get_state ...
==> driver: Running trigger...
```

This is tart trying to get an IP. It might stay on this for a while, but once it caches the IP
on the arp table, it gets faster.

If it stays like this for too long, check `tart list` to see if the VM is running.
