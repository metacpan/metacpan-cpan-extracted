

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'swd',
    VERSION_FROM => 'lib/swd.pm', # finds \$VERSION
    AUTHOR       => 'Vidul Petrov (vidul@cpan.org)',
    ABSTRACT     => 'swd - Perl pragma to change $ENV{PWD}',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
