use 5.008;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share/dtdto';

WriteMakefile(
    'NAME'		=> 'XML::DTD',
    'VERSION_FROM'      => 'lib/XML/DTD.pm',
    'ABSTRACT_FROM'     => 'lib/XML/DTD.pm',
    'AUTHOR'            => 'Brendt Wohlberg <wohl@cpan.org>',
    'EXE_FILES'         => ['bin/dtdto'],
    'PREREQ_PM'         => {File::ShareDir => 0,
			    File::ShareDir::Install => 0,
			    Getopt::Long => 0,
			    File::Temp => 0,
			    URI::file => 0,
			    LWP::Simple => 0,
			    Error => 0},
    'NO_META'           => 1
);

package MY;
use File::ShareDir::Install qw(postamble);
