all: build

build:
	coffee --compile --output lib src


.PHONY: test
test: build
	rm -rf examples/html
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register \
		--slow 50 \
		--timeout 3000