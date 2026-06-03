install:
	brew bundle
	vagrant plugin install vagrant-tart

up:
	vagrant up driver --no-provision
	vagrant up worker --no-provision

deploy:
	vagrant provision

halt:
	vagrant halt

destroy:
	vagrant destroy -f driver
	vagrant destroy -f worker
