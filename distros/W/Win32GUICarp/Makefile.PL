use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Win32::GUI::Carp',
    'VERSION_FROM'  => 'lib/Win32/GUI/Carp.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Win32/GUI/Carp.pm', # retrieve abstract from module
    'AUTHOR'        => 'Cory Johns <johnsca@cpan.org>',
    'PREREQ_PM'     => {
      'Win32::GUI'  => 0,
      'Carp'        => 0,
    },
);
