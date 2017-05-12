

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Time::Business',
    VERSION_FROM => 'lib/Time/Business.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Business Time Between Two Times',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    SKIP	=> [qw(entries)],
);
