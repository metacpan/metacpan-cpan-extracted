all:	setup
	./Build

setup:	manifest
	perl Build.PL

manifest:Build.PL README bin Makefile lib t
	find . -type f | grep -vE 'DS_Store|git|_build|META.yml|Build|cover_db|svn|blib|\~|\.old|CVS|rpmbuild|build.tap|idx|META' | sed 's/^\.\///' | sort > MANIFEST
	[ -f Build.PL ] && echo "Build.PL" >> MANIFEST

clean:	setup
	./Build clean

test:	setup
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	setup
	./Build testcover verbose=1

install:	setup
	./Build install

dist:	setup
	./Build dist

pardist:	setup
	./Build pardist
