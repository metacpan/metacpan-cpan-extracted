use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'TestGen4Web::Runner',
	VERSION_FROM	=> 'lib/TestGen4Web/Runner.pm',
	AUTHOR		=> 'mackers',
	ABSTRACT	=> 'A module to replay files recorded with TestGen4Web',
	PREREQ_PM	=> {
		XML::Simple		=> 0,
		LWP::UserAgent		=> 0,
		HTTP::Cookies		=> 0,
		URI::Escape		=> 0,
		Term::ANSIColor		=> 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
	return <<'MAKE_FRAG';

publish-cpan: dist 
	echo "Going to upload " `ls -1t *.tar.gz | head -1`
	sleep 2
	/usr/local/bin/cpan-upload -user mackers -mailto me@mackers.com -verbose `ls -1t *.tar.gz | head -1`

debuild: META.yml dist
	mkdir /tmp/debuild-testgen4web/
	cp `ls -1t *.tar.gz | head -1` /tmp/debuild-testgen4web/
	cd /tmp/debuild-testgen4web/ && tar -zxvf *.tar.gz
	rm /tmp/debuild-testgen4web/*.tar.gz
	cp -R debian /tmp/debuild-testgen4web/TestGen4Web-Runner*
	cd /tmp/debuild-testgen4web/TestGen4Web-Runner* && debuild
	rm -rf /tmp/debuild-testgen4web/TestGen4Web-Runner-*
	mv /tmp/debuild-testgen4web/* ./debuild/
	rmdir /tmp/debuild-testgen4web/

publish-debian: dist debuild
	echo "Going to upload" `ls -1t debuild/*.changes | head -1`
	sleep 2
	/usr/bin/reprepro -Vb /var/www/hosts/apt.mackers.com/htdocs/ include unstable `ls -1t debuild/*.changes | head -1` 

unpublish-debian:
	/usr/bin/reprepro -Vb /var/www/hosts/apt.mackers.com/htdocs/ remove unstable libtestgen4web-runner-perl


MAKE_FRAG
}

