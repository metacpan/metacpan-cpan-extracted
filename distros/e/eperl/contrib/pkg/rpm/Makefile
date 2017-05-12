
all: fetch build

fetch: eperl-2.2.11.tar.gz

eperl-2.2.11.tar.gz:
	fetch http://www.engelschall.com/sw/eperl/distrib/eperl-2.2.11.tar.gz

build:
	rpm --rcfile rpmrc -bc eperl.spec

clean:
	rm -rf eperl-2.2.11

