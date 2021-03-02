all: build

build:
	@docker build --tag=ftntming/nginx-xmpp .

release: build
	@docker build --tag=ftntming/nginx-xmpp:$(shell cat VERSION) .
