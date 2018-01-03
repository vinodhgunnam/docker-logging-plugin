PLUGIN_NAME=splunknova/docker-logging-plugin


PLUGIN_TAGS := $(shell git tag)
ifeq ($(TRAVIS_BRANCH), master)
    PLUGIN_TAGS += latest
endif

ifdef TRAVIS_BRANCH
	PLUGIN_TAGS += $(TRAVIS_BRANCH)_latest
endif

SHELL := /bin/bash

all: clean docker rootfs create

clean:
	@echo "### rm -rf ./plugin"
	rm -rf ./plugin
	@for tag in ${PLUGIN_TAGS} ; do \
		echo "### remove existing plugin ${PLUGIN_NAME}:$$tag if exists" ;\
		docker plugin rm -f ${PLUGIN_NAME}:$$tag 2> /dev/null || true ;\
	done

docker:
	@echo "### docker build: rootfs image with splunk-log-plugin"
	docker build -t ${PLUGIN_NAME}:rootfs .

rootfs:
	@echo "### create rootfs directory in ./plugin/rootfs"
	mkdir -p ./plugin/rootfs
	docker create --name tmprootfs ${PLUGIN_NAME}:rootfs > /dev/null
	docker export tmprootfs | tar -x -C ./plugin/rootfs
	@echo "### copy config.json to ./plugin/"
	cp config.json ./plugin/
	docker rm -vf tmprootfs > /dev/null

create:
	@for tag in ${PLUGIN_TAGS} ; do \
		echo "### create new plugin ${PLUGIN_NAME}:$$tag from ./plugin" ;\
		docker plugin create ${PLUGIN_NAME}:$$tag ./plugin ;\
		rc=$$?; if [[ $$rc != 0 ]]; then exit $$rc; fi ; \
	done

enable:
	@for tag in ${PLUGIN_TAGS} ; do \
		echo "### enable plugin ${PLUGIN_NAME}:$$tag" ;\
		docker plugin enable ${PLUGIN_NAME}:$$tag ;\
		rc=$$?; if [[ $$rc != 0 ]]; then exit $$rc; fi ; \
	done


push: all
	@for tag in ${PLUGIN_TAGS} ; do \
		echo "### push plugin ${PLUGIN_NAME}:$$tag" ;\
		docker plugin push ${PLUGIN_NAME}:$$tag ;\
		rc=$$?; if [[ $$rc != 0 ]]; then exit $$rc; fi ; \
	done
