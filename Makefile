install:
	brew bundle

patch-utm:
	./patch-utm-plugin.sh

patch-box:
	./patch-utm-box.sh
	-cp efi_vars.fd ${HOME}/.vagrant.d/boxes/utm-VAGRANTSLASH-ubuntu-24.04/0.0.1/arm64/utm/box.utm/Data

up:
	vagrant up

deploy:
	vagrant provision

halt:
	vagrant halt

destroy:
	vagrant destroy -f
