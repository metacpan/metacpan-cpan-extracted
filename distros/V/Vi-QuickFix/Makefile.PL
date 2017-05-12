use 5.008_000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Vi::QuickFix',
    VERSION_FROM => 'lib/Vi/QuickFix.pm', # finds $VERSION
    AUTHOR       => 'Anno Siegel (siegel@zrz.tu-berlin.de)',
    ABSTRACT     => 'Support for vim\'s QuickFix mode',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
