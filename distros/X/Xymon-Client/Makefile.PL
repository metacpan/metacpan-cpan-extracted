

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::Client',
    VERSION_FROM => 'lib/Xymon/Client.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Interface to xymon / hobbit client.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
