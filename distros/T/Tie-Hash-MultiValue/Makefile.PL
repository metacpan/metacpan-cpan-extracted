use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Tie::Hash::MultiValue',
    VERSION_FROM => 'lib/Tie/Hash/MultiValue.pm', # finds $VERSION
    AUTHOR       => 'Joe McMahon (mcmahon@ibiblio.org)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Tie::Hash' => 1.00,
                    },
);
