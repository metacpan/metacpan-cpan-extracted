

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon',
    VERSION_FROM => 'lib/Xymon.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Xymon Base Module',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
