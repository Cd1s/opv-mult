.PHONY: build install clean test

build:
	go build -o openvpn-manager main.go

install: build
	sudo ./install.sh

clean:
	rm -f openvpn-manager

test:
	go test -v ./...

deps:
	go mod download
	go mod tidy

run:
	go run main.go

.DEFAULT_GOAL := build
