test:
	carton exec prove -lv t/

clean-install: clean
	carton install

install:
	carton install

clean:
	rm -rf local cpanfile.snapshot

install-minil:
	cpanm Minilla

prepare:
	minil test
	minil dist

carton-minil-test:
	carton exec minil test

release:
	minil release
