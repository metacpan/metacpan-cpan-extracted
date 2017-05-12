

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Newzbin',
    VERSION_FROM => 'lib/WWW/Newzbin.pm', # finds \$VERSION
    AUTHOR       => 'Chris Novakovic (chrisn@cpan.org)',
    ABSTRACT     => 'Interface to Newzbin.com\'s Usenet index',
    PREREQ_PM    => {
                     'Test::More' => 0.78,
		     'LWP::UserAgent' => 2.036,
		     'Exporter' => 5.58,
                    },
);
