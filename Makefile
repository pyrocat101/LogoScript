all: parser compiler browser

parser:
	@pegjs src/parser.pegjs lib/parser.js

compiler:
	@coffee -c -o lib/ src/*.coffee

watch:
	@coffee -cw -o lib/ src/*.coffee

browser:
	@browserify -r ./lib/logo.js:logo > lib/app.js

clean:
	rm -rf lib/*.js

.PHONY: all watch compiler parser clean
