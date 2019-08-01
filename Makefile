VERSION ?= dirty

default: builder

builder:
	VERSION=${VERSION} docker build -t image-builder-rpi64 .

sd-image: builder
	VERSION=${VERSION} docker run --rm --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e TRAVIS_TAG -e VERSION -e GITHUB_OAUTH_TOKEN image-builder-rpi64

shell: builder
	VERSION=${VERSION} docker run -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e TRAVIS_TAG -e VERSION -e GITHUB_OAUTH_TOKEN image-builder-rpi64 bash

test:
	VERSION=${VERSION} docker run --rm -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e TRAVIS_TAG -e VERSION image-builder-rpi64 bash -c "unzip /workspace/hypriotos-rpi64-${VERSION}.img.zip && rspec --format documentation --color /workspace/builder/test/*_spec.rb"

shellcheck: builder
	VERSION=${VERSION} docker run --rm -ti -v $(shell pwd):/workspace image-builder-rpi64 bash -c 'shellcheck /workspace/builder/*.sh /workspace/builder/files/etc/firstboot.d/*'

vagrant:
	vagrant up

docker-machine: vagrant
	docker-machine create -d generic \
	  --generic-ssh-user $(shell vagrant ssh-config | grep ' User ' | cut -d ' ' -f 4) \
	  --generic-ssh-key $(shell vagrant ssh-config | grep IdentityFile | cut -d ' ' -f 4) \
	  --generic-ip-address $(shell vagrant ssh-config | grep HostName | cut -d ' ' -f 4) \
	  --generic-ssh-port $(shell vagrant ssh-config | grep Port | cut -d ' ' -f 4) \
	  image-builder-rpi64

test-integration: test-integration-image test-integration-docker

test-integration-image:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-image"

test-integration-docker:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-docker"

tag:
	git tag ${TAG}
	git push origin ${TAG}
