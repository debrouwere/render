all:
	coffee --compile --output lib src

.PHONY: test
test:
	make
	./bin/render examples/templates/detail.jade \
		--context examples/data/hash-one.json
	./bin/render examples/templates/list.jade \
		--context examples/data/list-one.json,examples/data/list-two.json
	./bin/render examples/templates/detail.jade \
		--context examples/data/list-one.json,examples/data/list-two.json \
		--iterate