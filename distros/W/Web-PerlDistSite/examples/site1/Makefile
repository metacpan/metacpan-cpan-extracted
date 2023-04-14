.PHONY: all
all : styles scripts images pages

.PHONY: clean
clean :
	rm -fr _build docs

.PHONY: install
install :
	npm install
	cpanm Web::PerlDistSite

.PHONY: images
images :
	mkdir -p docs/assets/
	cp -r images docs/assets/

.PHONY: styles
styles : docs/assets/styles/main.css

.PHONY: scripts
scripts : docs/assets/scripts/bootstrap.bundle.min.js docs/assets/scripts/bootstrap.bundle.min.js.map

.PHONY: pages
pages :
	mkdir -p docs
	perl -Ilib -MWeb::PerlDistSite::Compile -e write_pages

_build/main.scss :
	perl -Ilib -MWeb::PerlDistSite::Compile -e write_main_scss

_build/layout.scss :
	perl -Ilib -MWeb::PerlDistSite::Compile -e write_layout_scss

_build/variables.scss : config.yaml
	perl -Ilib -MWeb::PerlDistSite::Compile -e write_variables_scss

custom.scss :
	touch -a custom.scss

docs/assets/styles/main.css : _build/main.scss _build/variables.scss _build/layout.scss custom.scss
	mkdir -p docs/assets/styles
	node node_modules/sass/sass.js --style=compressed _build/main.scss:docs/assets/styles/main.css

docs/assets/scripts/bootstrap.bundle.min.js :
	mkdir -p docs/assets/scripts
	cp node_modules/bootstrap/dist/js/bootstrap.bundle.min.js docs/assets/scripts/bootstrap.bundle.min.js

docs/assets/scripts/bootstrap.bundle.min.js.map :
	mkdir -p docs/assets/scripts
	cp node_modules/bootstrap/dist/js/bootstrap.bundle.min.js.map docs/assets/scripts/bootstrap.bundle.min.js.map
