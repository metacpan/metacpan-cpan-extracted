

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::Server',
    VERSION_FROM => 'lib/Xymon/Server.pm', # finds \$VERSION
    AUTHOR       => 'A. U. Thor (a.u.thor@a.galaxy.far.far.away)',
    ABSTRACT     => 'Xymon Server Interface',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
