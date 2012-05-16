all: parser compiler

parser:
	@pegjs --track-line-and-column src/parser.pegjs lib/parser.js

compiler:
	@coffee -c -o lib/ src/*.coffee

watch:
	@coffee -cw -o lib/ src/*.coffee

test:
	@bash test/draw-roses.sh

clean:
	rm -rf test/roses
	rm -rf lib/*.js

.PHONY: all watch compiler parser test clean
