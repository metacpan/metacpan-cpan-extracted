use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'o2sms',
	DISTNAME	=> 'o2sms',
	ABSTRACT	=> 'A module to send SMS messages using .ie websites',
	AUTHOR		=> 'mackers',
	VERSION_FROM	=> 'bin/o2sms',
	EXE_FILES     => [ 'bin/o2sms', 'bin/vodasms', 'bin/meteorsms', 'bin/threesms', 'bin/aftsms' ],
	PREREQ_PM	=> {
		Getopt::Long		=> 2.33,
		Term::ReadLine		=> 0,
		Storable		=> 0,
		TestGen4Web::Runner	=> 0.11,
		IO::Socket::SSL		=> 0,
		Net::SSLeay		=> 0,
		Crypt::SSLeay		=> 0,
		URI			=> 1.26,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
	return <<'MAKE_FRAG';

publish-cpan: dist 
	echo "Going to upload " `ls -1t *.tar.gz | head -1`
	sleep 2
	echo "(Use furniture password or enter a world of pain!!)"
	/usr/local/bin/cpan-upload -user mackers -mailto me@mackers.com -verbose `ls -1t *.tar.gz | head -1`

publish-sf: dist
	/usr/bin/scp `ls -1t *.tar.gz | head -1` mackers@frs.sourceforge.net:/home/pfs/project/o/o2/o2sms/

debuild: META.yml dist
	mkdir /tmp/debuild-o2sms/
	cp `ls -1t *.tar.gz | head -1` /tmp/debuild-o2sms/
	cd /tmp/debuild-o2sms/ && tar -zxvf *.tar.gz
	rm /tmp/debuild-o2sms/*.tar.gz
	cp -R debian /tmp/debuild-o2sms/o2sms*
	cd /tmp/debuild-o2sms/o2sms* && debuild
	rm -rf /tmp/debuild-o2sms/o2sms-*
	mv /tmp/debuild-o2sms/* ./debuild/
	rmdir /tmp/debuild-o2sms/

publish-debian: dist debuild
	echo "Going to upload" `ls -1t debuild/*.changes | head -1`
	sleep 2
	/usr/bin/reprepro -Vb /var/www/hosts/apt.mackers.com/htdocs/ include unstable `ls -1t debuild/*.changes | head -1` 
	find /var/www/hosts/apt.mackers.com/htdocs/ -name 'Release' -exec gpg -abs -o '{}.gpg' '{}' \;

publish-mackers.com: dist
	/usr/bin/pod2html -title o2sms -htmlroot . bin/o2sms  > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/usage.html
	/usr/bin/pod2html -title WWW::SMS::IE::iesms -htmlroot . lib/WWW/SMS/IE/iesms.pm > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/WWW/SMS/IE/iesms.html
	/usr/bin/pod2html -title WWW::SMS::IE::o2sms -htmlroot . lib/WWW/SMS/IE/o2sms.pm > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/WWW/SMS/IE/o2sms.html
	/usr/bin/pod2html -title WWW::SMS::IE::vodasms -htmlroot . lib/WWW/SMS/IE/vodasms.pm > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/WWW/SMS/IE/vodasms.html
	/usr/bin/pod2html -title WWW::SMS::IE::threesms -htmlroot . lib/WWW/SMS/IE/threesms.pm > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/WWW/SMS/IE/threesms.html
	/usr/bin/pod2html -title WWW::SMS::IE::meteorsms -htmlroot . lib/WWW/SMS/IE/meteorsms.pm > /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/docs/v3/WWW/SMS/IE/meteorsms.html
	find . -name '*.tmp' | xargs rm
	cp `ls -1t *.tar.gz | head -1` /var/www/hosts/www.mackers.com/htdocs/projects/o2sms/releases/

unpublish-debian:
	/usr/bin/reprepro -Vb /var/www/hosts/apt.mackers.com/htdocs/ remove unstable o2sms

exe:
	set PERL5LIB=lib
#	pp -v=3 -L pp_o2sms.log -a "c:/perl/lib/attributes.pm;./attributes.pm" -a "c:/perl/lib/Storable.pm;./Storable.pm" -o o2sms.exe -l c:/perl/bin/libeay32.dll -l c:/perl/bin/ssleay32.dll bin/o2sms
	pp \
	-v=3 \
	-L pp_o2sms.log \
	-a "c:/perl/lib/attributes.pm;./attributes.pm" \
	-a "c:/perl/lib/Storable.pm;./Storable.pm" \
	-a "lib/WWW/SMS/IE/vodasms.action;./lib/WWW/SMS/IE/vodasms.action" \
	-a "lib/WWW/SMS/IE/o2sms.action;./lib/WWW/SMS/IE/o2sms.action" \
	-a "lib/WWW/SMS/IE/meteorsms.action;./lib/WWW/SMS/IE/meteorsms.action" \
	-a "lib/WWW/SMS/IE/threesms.action;./lib/WWW/SMS/IE/threesms.action" \
	-o o2sms4w.exe \
	-l c:/perl/bin/libeay32.dll \
	-l c:/perl/bin/ssleay32.dll \
	--gui \
	--icon o2sms.ico \
	bin/o2sms4w

publish-exe: o2sms4w.exe
	zip o2sms4w.zip o2sms4w.exe
	scp o2sms4w.zip mackers.com:www/projects/o2sms/releases/o2sms4w.zip

MAKE_FRAG
}

