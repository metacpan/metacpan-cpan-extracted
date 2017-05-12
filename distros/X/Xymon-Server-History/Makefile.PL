

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Xymon::Server::History',
    VERSION_FROM => 'lib/Xymon/Server/History.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Return a hash of Xymon events history',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Xymon::Server' => 0.01,
                     'File::Find' => 0.01,
                     'Time::Local' => 0.01,
                     'Time::Business' => 0.13,
                    },
);
