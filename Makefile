install:
	brew bundle
	vagrant plugin install vagrant-tart

up:
	vagrant up

deploy:
	vagrant provision

halt:
	vagrant halt

destroy:
	vagrant destroy -f
