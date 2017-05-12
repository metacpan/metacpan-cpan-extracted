

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Weblogic::WLST',
    VERSION_FROM => 'lib/Weblogic/WLST.pm', # finds \$VERSION
    AUTHOR       => 'D Peters (davidp@electronf.com)',
    ABSTRACT     => 'Interface to Oraclwe Weblogic Scripting Tool',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
