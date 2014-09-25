all:
	coffee --compile --output lib src

mtest:
	make
	./bin/render examples/templates/detail.jade \
		--context examples/data/hash-one.json
	./bin/render examples/templates/list.jade \
		--context examples/data/list-one.json,examples/data/list-two.json
	./bin/render examples/templates/detail.jade \
		--context examples/data/list-one.json,examples/data/list-two.json \
		--many

.PHONY: test
test:
	rm -f examples/html
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register
