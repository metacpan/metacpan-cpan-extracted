# http://module-build.sourceforge.net/META-spec-v1.4.html

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile
    NAME => 'makepp',
    VERSION_FROM => 'Mpp/Text.pm',
    PM => {},
    META_MERGE => { resources => {
	bugtracker  => 'http://sourceforge.net/tracker/?atid=437093&group_id=43679&func=browse',
	homepage    => 'http://makepp.sourceforge.net/',
	license     => 'http://dev.perl.org/licenses/',
	repository  => 'http://sourceforge.net/scm/?type=cvs&group_id=43679&source=navbar',
	MailingList => 'http://sourceforge.net/tracker/?group_id=43679&source=navbar'
    }};

print "*** This is only intended to give CPAN testers an entry point.
*** It does not install makepp.
*** Use './configure && make install' or './install.pl' for that.\n";
