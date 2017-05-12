

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Voldemort',
    VERSION_FROM => 'lib/Voldemort.pm', # finds \$VERSION
    AUTHOR       => 'Spencer Portee (exussum@gmail.com)',
    PREREQ_PM    => {
                     'Moose' => 0.54,
                     'Test::Simple' => 0.44,
                     'Test::More' => 0.88,
                     'Google::ProtocolBuffers' => 0.08
                    },
);
