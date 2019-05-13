

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Control',
    VERSION_FROM => 'lib/Text/Control.pm', # finds \$VERSION
    AUTHOR       => 'Felipe M. L. Gasper ()',
    ABSTRACT_FROM => 'lib/Text/Control.pm',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
                     'Test::More' => 0,
                    },
);
