install:
	brew bundle
	vagrant plugin install vagrant-tart

up:
	vagrant up --no-parallel

deploy:
	vagrant provision --no-parallel

halt:
	vagrant halt

destroy:
	vagrant destroy -f
